DECLARE
  --custom 
  v_id          NUMBER;
  v_isDeleted   NUMBER;
  v_name        NVARCHAR2(255);
  v_code        NVARCHAR2(255);
  v_description NCLOB;
  v_isId        NUMBER;
  v_Text        NVARCHAR2(255);
  v_result		NUMBER;

  --standard 
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  --custom 
  v_id          := :Id;
  v_isDeleted   := :IsDeleted;
  v_name        := :Name;
  v_code        := :Code;
  v_description := :Description;

  --standard 
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  :SuccessResponse := EMPTY_CLOB();

    -- validation on Id is Exist
    IF NVL(v_id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_id,
                             tablename    => 'TBL_DICT_LINKTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  --set assumed success message
  IF v_id IS NOT NULL THEN
    v_Text := 'Updated {{MESS_NAME}} link type';
  ELSE
    v_Text := 'Created {{MESS_NAME}} link type';
  END IF;
	v_result := LOC_i18n(
		MessageText => v_Text,
		MessageResult => :SuccessResponse,
		MessageParams => NES_TABLE(
			Key_Value('MESS_NAME', v_name)
		)
	);

  BEGIN
    --add new record or update existing one 
    IF v_id IS NULL THEN
      INSERT INTO tbl_dict_linktype (col_code) VALUES (v_code) RETURNING col_id INTO v_id;
    END IF;
  
    UPDATE tbl_dict_linktype
       SET col_name = v_name, col_description = v_description , col_isDeleted = v_isDeleted
     WHERE col_id = v_id;
  
    :affectedRows := SQL%ROWCOUNT;
    :recordId := v_id;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
		v_result := LOC_i18n(
			MessageText => 'There already exists a link type with the code {{MESS_CODE}}',
			MessageResult => v_errormessage,
			MessageParams => NES_TABLE(
				Key_Value('MESS_CODE', v_code)
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