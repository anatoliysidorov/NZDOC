DECLARE
  v_sourceId       NUMBER;
  v_name           NVARCHAR2(255);
  v_code           NVARCHAR2(255);
  v_description    NCLOB;
  v_UIElementId    NUMBER;
  v_DOMAttribute   INTEGER;
  v_AccessObjectId NUMBER;
  v_isACL          INTEGER;
  v_usedfor        NVARCHAR2(255);
  v_CaseTypeId     NUMBER;
  v_result         NUMBER;
  v_aotype         INT;

  --standard  
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_sourceId    := :sourceId;
  v_name        := :NAME;
  v_code        := :Code;
  v_description := :Description;
  v_isACL       := :IsACL;
  v_usedfor     := :UsedFor;
  v_CaseTypeId  := :CaseTypeId;

  --standard  
  :affectedRows    := 0;
  v_errorcode      := 0;
  v_errormessage   := '';
  :SuccessResponse := EMPTY_CLOB();

  ---Input params check
  IF v_sourceId IS NULL THEN
    v_errormessage := 'SourceId can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  BEGIN
    BEGIN
      -- clone Page record
      FOR rec IN (SELECT col_isdeleted   AS isdeleted,
                         col_fieldvalues AS fieldvalues,
                         col_config      AS config,
                         col_name        AS NAME
                    FROM tbl_fom_page
                   WHERE col_id = v_sourceId) LOOP
        INSERT INTO tbl_fom_page
          (col_isdeleted, col_description, col_name, col_code, col_fieldvalues, col_usedfor, col_config, col_PageCaseSysType)
        VALUES
          (rec.isdeleted, v_description, v_name, v_code, rec.fieldvalues, v_usedfor, rec.config, v_CaseTypeId)
        RETURNING col_id INTO :recordId;
        --:SuccessResponse := 'Page ' || rec.name || ' was cloned to page ' || v_name;
        :SuccessResponse := 'Page {{MESS_PAGEFROM}} was cloned to page {{MESS_PAGETO}}';
        v_result         := LOC_i18n(MessageText   => :SuccessResponse,
                                     MessageResult => :SuccessResponse,
                                     MessageParams => NES_TABLE(Key_Value('MESS_PAGEFROM', rec.name), Key_Value('MESS_PAGETO', v_name)));
        :affectedRows    := 1;
      END LOOP;
    EXCEPTION
      WHEN dup_val_on_index THEN
        :affectedRows := 0;
        v_errorcode   := 102;
        --v_errormessage   := 'There already exists a page with the code ' || v_code;
        v_errormessage   := 'There already exists a page with the code {{MESS_CODE}}';
        v_result         := LOC_i18n(MessageText => v_errormessage, MessageResult => v_errormessage, MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_code)));
        :SuccessResponse := '';
        GOTO cleanup;
    END;
  
    -- clone Page UIElement records
    FOR cur1 IN (SELECT ue.col_jsondata        AS jsondata,
                        ue.col_positionindex   AS positionindex,
                        ue.col_regionid        AS regionid,
                        ue.col_description     AS description,
                        ue.col_iseditable      AS iseditable,
                        ao.col_id              AS accessobjectid,
                        ue.col_formidlist      AS formidlist,
                        ue.col_codedpageidlist AS codedpageidlist,
                        ue.col_config          AS config
                   FROM tbl_fom_uielement ue
                   LEFT JOIN tbl_ac_accessobject ao
                     ON ao.col_accessobjectuielement = ue.col_id
                  WHERE ue.col_uielementpage = v_sourceId) LOOP
    
      -- FOM_UIELEMENT
      INSERT INTO tbl_fom_uielement
        (col_description, col_jsondata, col_positionindex, col_regionid, col_uielementpage, col_iseditable, col_code, col_formidlist, col_codedpageidlist, col_config)
      VALUES
        (cur1.description, cur1.jsondata, cur1.positionindex, cur1.regionid, :recordId, cur1.iseditable, sys_guid(), cur1.formidlist, cur1.codedpageidlist, cur1.config)
      RETURNING col_id INTO v_UIElementId;
    
      -- TBL_UIELEMENT_DOM_ATTRIBUTE
      IF v_CaseTypeId IS NOT NULL THEN
        BEGIN
          SELECT COL_DOM_ATTRIBUTE_ID INTO v_DOMAttribute FROM TBL_UIELEMENT_DOM_ATTRIBUTE WHERE COL_FOM_UIELEMENT_ID = v_UIElementId;
        EXCEPTION
          WHEN OTHERS THEN
            v_DOMAttribute := NULL;
        END;
      
        IF v_DOMAttribute IS NOT NULL THEN
          INSERT INTO TBL_UIELEMENT_DOM_ATTRIBUTE
            (COL_FOM_UIELEMENT_ID, COL_DOM_ATTRIBUTE_ID)
          VALUES
            (v_UIElementId, (SELECT COL_DOM_ATTRIBUTE_ID FROM TBL_UIELEMENT_DOM_ATTRIBUTE WHERE COL_FOM_UIELEMENT_ID = v_UIElementId));
        END IF;
      END IF;
    
      -- AC_AccessObject
      v_aotype := f_util_getidbycode(code => 'PAGE_ELEMENT', tablename => 'tbl_ac_accessobjecttype');
      INSERT INTO tbl_ac_accessobject
        (col_name, col_code, col_accessobjectuielement, col_accessobjaccessobjtype)
      VALUES
        ('Page element ' || To_char(v_UIElementId), f_UTIL_calcUniqueCode('PAGE_ELEMENT_' || to_char(v_UIElementId), 'tbl_ac_accessobject'), v_UIElementId, v_aotype)
      RETURNING col_id INTO v_AccessObjectId;
    
      -- AC_ACL
      IF v_isACL = 1 THEN
        FOR cur2 IN (SELECT col_aclaccesssubject AS aclaccesssubject,
                            col_aclpermission    AS aclpermission,
                            col_type             AS TYPE
                       FROM tbl_ac_acl
                      WHERE col_aclaccessobject = cur1.accessobjectid) LOOP
          INSERT INTO tbl_ac_acl
            (col_aclaccessobject, col_aclaccesssubject, col_aclpermission, col_type, col_code)
          VALUES
            (v_AccessObjectId, cur2.aclaccesssubject, cur2.aclpermission, cur2.type, sys_guid());
        END LOOP;
      END IF;
    END LOOP;
  
    -- clone KeySources
    INSERT INTO TBL_LOC_KEYSOURCES
      (COL_SOURCETYPE, COL_KEYID, COL_SOURCEID, COL_UCODE)
      SELECT COL_SOURCETYPE,
             COL_KEYID,
             :recordId,
             SYS_GUID()
        FROM TBL_LOC_KEYSOURCES
       WHERE lower(COL_SOURCETYPE) = lower('Page')
         AND COL_SOURCEID = v_sourceId;
  
  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 104;
      v_errormessage   := Substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
