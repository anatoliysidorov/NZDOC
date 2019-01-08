DECLARE 
    --custom 
    v_id           NUMBER; 
    v_name         NVARCHAR2(255); 
    v_code         NVARCHAR2(255);
    v_description  NCLOB;
    v_isdeleted    NUMBER; 
	v_isId		   INT;
	v_result	   NUMBER;
	v_Text		   NVARCHAR2(255);
	
    --standard 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
BEGIN 
    --custom 
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := '';
    :SuccessResponse := EMPTY_CLOB(); 
	
    --standard 
    v_id := :Id; 
    v_name := :Name; 
    v_code := :Code; 
    v_isdeleted := :IsDeleted; 
    v_description := :Description; 
	
	-- validation on Id is Exist
    IF NVL(v_id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_id,
                             tablename    => 'TBL_DICT_DOCUMENTTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    --set assumed success message
	IF v_id IS NOT NULL THEN
		v_Text := 'Updated {{MESS_NAME}} Document Type';
	ELSE
		v_Text := 'Created {{MESS_NAME}} Document Type';
	END IF;
	--:SuccessResponse := :SuccessResponse || ' ' || v_name || ' Document Type';
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
          INSERT INTO tbl_dict_documenttype
                      ( 
                       col_code, 
                       col_name,
                       col_description,
					   col_isDeleted) 
          VALUES      ( 
                       v_code, 
                       v_name,
                       v_description,
					   0)
          RETURNING col_id INTO :recordId; 

          :affectedRows := 1; 
        ELSE 
          UPDATE tbl_dict_documenttype
          SET    col_name = v_name, 
                 col_isDeleted = v_isdeleted,
                 col_description = v_description
          WHERE  col_id = v_id; 

          :affectedRows := 1; 
          :recordId := v_id; 
        END IF; 
    EXCEPTION 
        WHEN dup_val_on_index THEN 
          :affectedRows := 0; 
          v_errorcode := 101; 
          v_errormessage := 'There already exists a document type with the code {{MESS_CODE}}';
			v_result := LOC_i18n(
				MessageText => v_errormessage,
				MessageResult => v_errormessage,
				MessageParams => NES_TABLE(
					Key_Value('MESS_CODE', To_char(v_code))
				)
			);
          :SuccessResponse := '';
        WHEN OTHERS THEN 
          :affectedRows := 0; 
          v_errorcode := 102; 
      	  v_errormessage := substr(SQLERRM, 1, 200);
          :SuccessResponse := '';
    END; 
	<<cleanup>>
	:errorCode := v_errorcode;
	:errorMessage := v_errormessage;	
END; 