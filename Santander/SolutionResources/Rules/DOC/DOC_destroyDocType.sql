DECLARE
  v_Id INTEGER;
  v_Ids NVARCHAR2(32767);
  v_listNotAllowDelete NVARCHAR2(32767);
  v_tempName  NVARCHAR2(255);
  count_ INTEGER;
  v_countDeletedRecords INTEGER;
  v_isDetailedInfo boolean;
  v_result NUMBER;
  v_MessageParams NES_TABLE := NES_TABLE();

BEGIN
    :SuccessResponse := '';
    :ErrorCode     := 0;
    :ErrorMessage  := '';
    :affectedRows   := 0;
    v_Id            := :Id;
    v_Ids            := :Ids;
    count_          := 0;
    v_countDeletedRecords := 0;
    :SuccessResponse := EMPTY_CLOB();
  
	---Input params check 
	IF v_Id IS NULL AND v_Ids IS NULL THEN
        :ErrorMessage  := 'Id can not be empty';
        :ErrorCode     := 101;
        RETURN;
    END IF;

    IF(v_Id IS NOT NULL) THEN
        v_Ids := TO_CHAR(v_id);
        v_isDetailedInfo := false;
    ELSE
        v_isDetailedInfo := true;
    END IF;

    FOR mRec IN (SELECT COLUMN_VALUE AS id FROM TABLE(ASF_SPLIT(v_Ids, ',')))
    LOOP
        SELECT COUNT(*) into count_
        FROM tbl_Doc_Document
        WHERE  COL_DOCTYPE = mRec.id AND ROWNUM=1;

        IF count_ > 0 THEN
            BEGIN
                SELECT col_Name INTO v_tempName
                FROM tbl_DICT_DocumentType
                WHERE col_Id = mRec.id;
                
                v_listNotAllowDelete := v_listNotAllowDelete || ', ' || v_tempName;

                EXCEPTION WHEN NO_DATA_FOUND THEN NULL;   
            END;

            CONTINUE;
        END IF;
        
		DELETE tbl_DICT_DocumentType
		WHERE col_id = mRec.id;

        v_countDeletedRecords := v_countDeletedRecords + 1;

    END LOOP;
    
	--get affected rows
	:affectedRows := SQL%ROWCOUNT; 	
	   
    IF (v_listNotAllowDelete IS NOT NULL) THEN  
        v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 2, LENGTH(v_listNotAllowDelete));

        /*IF(LENGTH(v_listNotAllowDelete) > 255) THEN
            v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 1, 255) || '...';
        END IF;*/
    
        :ErrorCode := 102;

        IF  (v_isDetailedInfo) THEN
            --:ErrorMessage := 'Count of deleted  Document Type(s): ' || v_countDeletedRecords || CHR(13)||CHR(10);
            --:ErrorMessage := :ErrorMessage || 'You can''t delete Document Type(s): ' || v_listNotAllowDelete;
			
			v_MessageParams.EXTEND(2);
			v_MessageParams(v_MessageParams.LAST - 1) := KEY_VALUE('MESS_COUNT', v_countDeletedRecords);
			v_MessageParams(v_MessageParams.LAST) := KEY_VALUE('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
			
			:ErrorMessage := 'Count of deleted  Document Types: {{MESS_COUNT}} <br>You can''t delete Document Types: {{MESS_LIST_NOT_DELETED}}<br> There are one or more Documents referencing Type.<br> Change the Type Code of those Documents and try again.';
        ELSE 
            :ErrorMessage := 'You can''t delete this Document Type.<br> There are one or more Documents referencing Type.<br> Change the Type Code of those Documents and try again.';
        END IF;  

		v_result := LOC_i18n(
			MessageText => :ErrorMessage,
			MessageParams => v_MessageParams,
			DisableEscapeValue => TRUE,
			MessageResult => :ErrorMessage
		);
    ELSE
        --:SuccessResponse := 'Deleted ' || v_countDeletedRecords || ' item(s)';
		v_result := LOC_i18n(
			MessageText => 'Deleted {{MESS_COUNT}} items',
			MessageResult => :SuccessResponse,
			MessageParams => NES_TABLE(
				Key_Value('MESS_COUNT', v_countDeletedRecords)
			)
		);
    END IF;

END;