DECLARE 
    --custom 
    v_id           NUMBER; 
    v_name         NVARCHAR2(255); 
    v_code        NVARCHAR2(255);
    v_formmarkup  NCLOB; 
	v_description NCLOB;
	v_isdeleted    NUMBER; 
	v_isId		  INT;
	v_result		NUMBER;
	
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
    v_formmarkup := :FormMarkup; 
	v_description := :Description; 
	v_isdeleted := :IsDeleted; 
    
	-- validation on Id is Exist
    IF NVL(v_id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_id,
                             tablename    => 'TBL_FOM_FORM');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    IF v_id IS NOT NULL THEN
		:SuccessResponse := 'Updated {{MESS_NAME}} form';
	ELSE
		:SuccessResponse := 'Created {{MESS_NAME}} form';
	END IF;
	
    --:SuccessResponse := :SuccessResponse || ' ' || v_name || ' form';
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
          INSERT INTO tbl_fom_form 
                      (col_formmarkup, 
                       col_code, 
                       col_name,
					   col_isDeleted,
					   col_description) 
          VALUES      (v_formmarkup, 
                       v_code, 
                       v_name,
					   0,
					   v_description)
          RETURNING col_id INTO :recordId; 

          :affectedRows := 1; 
        ELSE 
          UPDATE tbl_fom_form
          SET    col_name = v_name, 
                 col_formmarkup = v_formmarkup,
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
            --v_errormessage := 'There already exists a fom form with the code ' || To_char(v_code); 
			v_errormessage := 'There already exists a FOM form with the code {{MESS_CODE}}'; 
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