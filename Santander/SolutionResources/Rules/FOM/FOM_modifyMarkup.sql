DECLARE 
    --custom 
    v_id           NUMBER; 
    v_formmarkup  NCLOB; 
	v_isId		  INT;
	
    --standard 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
BEGIN 
    --custom 
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := ''; 
	
    --standard 
    v_id := :Id; 
    v_formmarkup := :FormMarkup; 
       
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
  
	UPDATE tbl_fom_form
	SET    
			 col_formmarkup = v_formmarkup
	WHERE  col_id = v_id; 

	:affectedRows := 1; 
	:recordId := v_id;

    <<cleanup>>
	:errorCode := v_errorcode;
	:errorMessage := v_errormessage;	
END;