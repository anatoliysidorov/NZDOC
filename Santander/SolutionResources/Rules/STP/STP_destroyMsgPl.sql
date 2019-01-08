DECLARE
	v_Id                  INTEGER;
	v_Ids                 NVARCHAR2(32767);
	v_tempName            NVARCHAR2(255);
	v_countDeletedRecords INTEGER;
	v_MessageParams       NES_TABLE := NES_TABLE();	
	v_listNotAllowDelete  NVARCHAR2(32767);
	v_result              NUMBER;
	v_count INT;	
	v_isDetailedInfo      BOOLEAN;
BEGIN
	:SuccessResponse := EMPTY_CLOB();
	:ErrorCode := 0;
	:ErrorMessage := '';
	:affectedRows := 0;
	  
	v_count := 0;
	v_Id := :Id;
	v_Ids := :Ids;
	v_countDeletedRecords := 0;  
	
	IF (v_Id IS NULL AND v_Ids IS NULL) THEN
		v_result := LOC_I18N(
		  MessageText => 'Id can not be empty',
		  MessageResult => :ErrorMessage
		);
		:ErrorCode := 101;
		RETURN;
	END IF;

	IF (v_Id IS NOT NULL) THEN
		v_Ids := TO_CHAR(v_Id);
		v_isDetailedInfo := false;
	ELSE 
		v_isDetailedInfo := true;
	END IF;
	
	FOR mRec IN (SELECT COLUMN_VALUE AS id
                 FROM TABLE (ASF_SPLIT(v_Ids, ',')))
	LOOP
  
		SELECT lower(COL_PLACEHOLDER)
		INTO v_tempName
		FROM tbl_messageplaceholder
		WHERE col_id = mRec.id;
		
		SELECT COUNT(1)
		INTO v_count
		FROM tbl_message
		WHERE dbms_lob.instr(lower(COL_TEMPLATE),'@' || v_tempName || '@' ) >= 1;

		---Input params check 
		IF v_count = 0 THEN
			DELETE TBL_MESSAGEPLACEHOLDER
			WHERE COL_ID = mRec.id;
			
			v_countDeletedRecords := v_countDeletedRecords + 1;
		ELSE 		
			v_listNotAllowDelete := v_listNotAllowDelete || ', ' || v_tempName;
		END IF;
	END LOOP;
	
	IF (v_listNotAllowDelete IS NOT NULL)
	THEN
		v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 2, LENGTH(v_listNotAllowDelete));

		IF (LENGTH(v_listNotAllowDelete) > 255)
		THEN
		  v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 1, 255) || '...';
		END IF;
		:ErrorCode := 101;
		IF (v_isDetailedInfo) THEN
		  :ErrorMessage := 'Count of deleted placeholders: {{MESS_COUNT}}'
						 || '<br>You can''t delete placeholders(ies): {{MESS_LIST_NOT_DELETED}}'
						 || '<br>There are one or more message template(s) referencing placeholders.';
		  v_MessageParams.EXTEND(2);
		  v_MessageParams(1) := KEY_VALUE('MESS_COUNT', v_countDeletedRecords);
		  v_MessageParams(2) := KEY_VALUE('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
		ELSE
		  :ErrorMessage := 'You can''t delete this placeholder.'
						 || '<br>The placeholder is used in a message template';
		END IF;
	ELSE
		:affectedRows := v_countDeletedRecords;
		v_MessageParams.EXTEND(1);
		v_MessageParams(1) := Key_Value('MESS_COUNT', v_countDeletedRecords);  
		v_result := LOC_I18N(
		  MessageText => 'Deleted {{MESS_COUNT}} items',
		  MessageResult => :SuccessResponse,
		  MessageParams => v_MessageParams);
	END IF;	
	
END;