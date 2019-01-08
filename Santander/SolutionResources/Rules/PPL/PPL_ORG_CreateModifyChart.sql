DECLARE
  v_id     NUMBER;
  v_name   NVARCHAR2(255);
  v_code   NVARCHAR2(255);
  v_config NCLOB;
  v_count NUMBER;
  v_result NUMBER;
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id     := :Id;
  v_name   := :NAME;
  v_code   := :Code;
  v_config := :Config;
  :SuccessResponse := EMPTY_CLOB();

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  v_count := 0;

  --set success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated {{MESS_NAME}} organizational chart';
  ELSE
    :SuccessResponse := 'Created {{MESS_NAME}} organizational chart';
  END IF;
  --:SuccessResponse := :SuccessResponse || ' ' || v_name || ' ' || ' organizational chart';
  v_result := LOC_i18n(
		MessageText => :SuccessResponse,
		MessageResult => :SuccessResponse,
		MessageParams => NES_TABLE(
		Key_Value('MESS_NAME', v_name)
		)
	);
    
  BEGIN
    --add new record or update existing one 
    IF v_id IS NULL THEN
      INSERT INTO tbl_ppl_orgchart (col_code, col_name) VALUES (v_code, v_name) RETURNING col_id INTO :recordId;
    ELSE
    
      SELECT COUNT(*) INTO v_count
      FROM tbl_ppl_orgchart 
      WHERE col_Id = v_id;
      
      IF (v_count = 0) THEN
        v_errorcode      := 101;
        v_errormessage   := 'There is not exist organizational chart with id {{MESS_CHARTID}}';
		v_result := LOC_i18n(
		  MessageText => v_errormessage,
		  MessageResult => v_errormessage,
		  MessageParams => NES_TABLE(
			Key_Value('MESS_CHARTID', to_char(v_id))
		  )
		);		
        :SuccessResponse := '';
        GOTO cleanup;
      END IF;	
	
      UPDATE tbl_ppl_orgchart SET col_code = v_code, col_name = v_name, col_config = v_config WHERE col_id = v_id;
    
      :recordId := v_id;
    END IF;
  
    :affectedRows := SQL%ROWCOUNT;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      
        v_errormessage   := 'There already exists a organizational chart with the code {{MESS_CHARTCODE}}';
		v_result := LOC_i18n(
		  MessageText => v_errormessage,
		  MessageResult => v_errormessage,
		  MessageParams => NES_TABLE(
			Key_Value('MESS_CHARTCODE', to_char(v_code))
		  )
		);		
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 102;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;