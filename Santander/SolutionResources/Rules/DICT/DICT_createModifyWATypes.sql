DECLARE 
    --custom 
    v_id           NUMBER; 
    v_name         NVARCHAR2(255); 
    v_code         NVARCHAR2(255);
    v_isdeleted    NUMBER; 
	v_description  NCLOB; 
	v_iconcode     NVARCHAR2(255);
    v_isId         NUMBER;
	v_Result	   NUMBER;
	v_Text		   NVARCHAR2(255);
	
    --standard 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
BEGIN 
    --standard 
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := ''; 
    :SuccessResponse := EMPTY_CLOB();
	
    --standard 
    v_id := :WorkActivityType_Id; 
    v_name := :Name; 
    v_code := :Code; 
    v_isdeleted := :IsDeleted; 
	v_description := :Description; 
	v_iconcode := :IconCode;
    
    -- validation on Id is Exist
    IF NVL(v_id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_id,
                             tablename    => 'TBL_DICT_WORKACTIVITYTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
    --set assumed success message
	IF v_id IS NOT NULL THEN
		v_Text := 'Updated {{MESS_NAME}} Work Activity Type';
	ELSE
		v_Text := 'Created {{MESS_NAME}} Work Activity Type';
	END IF;
	--:SuccessResponse := :SuccessResponse || ' ' || v_name || ' Work Activity Type';
	v_result := LOC_i18n(
		MessageText => v_Text,
		MessageResult => :SuccessResponse,
		MessageParams => NES_TABLE(
			Key_Value('MESS_NAME', v_name)
		)
	);

    BEGIN        
        --add new record if an ID is not passed in
		IF v_id IS NULL THEN 
		  INSERT INTO tbl_DICT_WorkActivityType
					  ( 
					   col_code, 
					   col_isDeleted
					   ) 
		  VALUES      ( 
					   v_code, 
					   0); 

		  SELECT GEN_TBL_DICT_WORKACTIVITYTYP.CURRVAL 
		  INTO   v_id 
		  FROM   dual; 
		END IF;
		
		UPDATE tbl_DICT_WorkActivityType
		SET    col_name = v_name, 
			 col_isDeleted = v_isdeleted,
			 col_description = v_description,
			 col_iconcode = v_iconcode				
		WHERE  col_id = v_id; 

          :affectedRows := 1; 
          :recordId := v_id; 
    EXCEPTION 
        WHEN dup_val_on_index THEN 
          :affectedRows := 0; 
          v_errorcode := 101; 
          v_errormessage := 'There already exists an activity type with the code {{MESS_CODE}}'; 
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