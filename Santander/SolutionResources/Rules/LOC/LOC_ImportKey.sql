DECLARE
    v_namespace   NVARCHAR2(255);
    v_xml_input   NCLOB;
    v_namespaceID NUMBER;
    v_count       INTEGER;
    v_count2      INTEGER;
    v_SourceId    INTEGER;
    v_SourceType  NVARCHAR2(255);
BEGIN
    v_namespace := :NAMESPACE;
    v_xml_input := :XML_INPUT;
    v_count     := 0;
    v_count2    := 0;
    v_SourceId  := TO_NUMBER(:SourceId);
    v_SourceType:= :SourceType;
    
    -- get a namespace ID
    BEGIN
        Select col_id Into v_namespaceID From tbl_LOC_Namespace Where col_name = v_namespace;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN v_namespaceID := null;
    END;
    
    IF v_namespaceID IS NULL THEN
        INSERT INTO tbl_LOC_Namespace (col_name, COL_UCODE) VALUES (v_namespace, SYS_GUID()) RETURNING col_id INTO v_namespaceID;
    END IF;

    -- merge the key table
    MERGE INTO tbl_LOC_Key
    USING (
        select *
        from XMLTable('Keys/*'
               passing xmltype(nvl(v_xml_input, '<Keys/>'))
               columns keyName  nvarchar2(255) path 'keyName'
                     , isPlural nvarchar2(255) path 'isPlural'
                     , context  nvarchar2(255) path 'context'
                     , namespace  nvarchar2(255) path 'namespace'
        )
    ) ON (keyName = COL_NAME and COL_NAMESPACEID = v_namespaceID and nvl(context, '0') = nvl(COL_CONTEXT, '0'))
    WHEN MATCHED THEN
        UPDATE SET col_IsNew = 0, col_IsPlural = isPlural, col_IsDeleted = 0
    WHEN NOT MATCHED THEN
        INSERT  (col_name, col_Context, col_IsDeleted, col_IsNew, col_IsPlural, col_NamespaceID, COL_UCODE) 
        VALUES 	(trim(keyName), trim(context), 0, 1, isPlural, v_namespaceID, SYS_GUID());

    -- mark like delete/remove for the not exist records
    for rec in (
        with xml_table AS (
            select * 
            from XMLTable('Keys/*'
                   passing xmltype(nvl(v_xml_input, '<Keys/>'))
                   columns keyName  nvarchar2(255) path 'keyName'
                         , context  nvarchar2(255) path 'context'
            )
        )
        Select t_key.COL_NAME as keyName, t_key.COL_CONTEXT as context, t_key.col_id as KeyID, xml_table.keyName as xmlKeyName
        From tbl_LOC_Key t_key
           left join xml_table on (xml_table.keyName = t_key.COL_NAME and nvl(xml_table.context, '0') = nvl(t_key.COL_CONTEXT, '0'))
        Where t_key.COL_NAMESPACEID = v_namespaceID
    )         
    loop
        -- have to delete some keys and keysources records
        IF rec.xmlKeyName is null THEN
            Select count(*) Into v_count From TBL_LOC_TRANSLATION Where COL_KEYID = rec.KeyID;
            
            IF ((v_SourceType is not null) and (v_SourceId is not null)) THEN
                DELETE FROM TBL_LOC_KEYSOURCES WHERE (COL_SOURCETYPE = v_SourceType and COL_KEYID = rec.KeyID and COL_SOURCEID = v_SourceId);
                Select count(*) Into v_count2 From TBL_LOC_KEYSOURCES Where (COL_KEYID = rec.KeyID and COL_SOURCEID <> v_SourceId);
            END IF;
            
            If (v_count2 = 0) Then
                If (v_count > 0) Then
                    UPDATE tbl_LOC_Key
                    SET COL_ISDELETED = 1
                    WHERE col_id = rec.KeyID;
                Else
                    DELETE FROM tbl_loc_key WHERE col_id = rec.KeyID;
                End If;
            End IF;
        -- if a key exists, have to insert a new Key Sources
        ELSIF ((v_SourceType is not null) and (v_SourceId is not null)) THEN
            MERGE INTO TBL_LOC_KEYSOURCES
            USING (
                select v_SourceId as SourceId, rec.KeyID as SourceKeyID, v_SourceType as SourceType from dual
            ) ON (COL_SOURCETYPE = SourceType and COL_KEYID = SourceKeyID and COL_SOURCEID = SourceId)
            WHEN NOT MATCHED THEN
                INSERT  (COL_SOURCETYPE, COL_KEYID, COL_SOURCEID, COL_UCODE) 
                VALUES 	(SourceType, SourceKeyID, SourceId, SYS_GUID());
        END IF;
    end loop;

EXCEPTION
    WHEN OTHERS THEN
        :errorcode      := 101;
        :errormessage   := substr(SQLERRM, 1, 200);
END;