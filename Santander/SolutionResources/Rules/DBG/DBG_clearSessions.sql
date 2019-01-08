DECLARE
  v_AffectedRows PLS_INTEGER := 0;
  v_result NUMBER;
  v_id INTEGER;
  v_ids NVARCHAR2(32767);
BEGIN

	v_id := :Id;
	v_ids := :IDS;
        :SuccessResponse := EMPTY_CLOB();
	
	IF v_ids IS NULL AND v_id IS NULL THEN
            :ErrorMessage  := 'Id can not be empty';
            :ErrorCode     := 101;  
            RETURN;
    END IF;
    
    IF(v_id IS NOT NULL) THEN
        v_ids := TO_CHAR(v_id);
    END IF;

	DELETE FROM TBL_DEBUGTRACE WHERE col_debugtracedebugsession  IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(v_ids, ',')));
	DELETE FROM TBL_DEBUGSESSION WHERE COL_ID IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(v_ids, ',')));
	
	v_AffectedRows := SQL%ROWCOUNT;
	v_Result := LOC_i18n(
		MessageText => 'Deleted {{MESS_COUNT}} Sessions',
		MessageResult => :SuccessResponse,
		MessageParams => NES_TABLE(KEY_VALUE('MESS_COUNT', v_AffectedRows))
	);
END;