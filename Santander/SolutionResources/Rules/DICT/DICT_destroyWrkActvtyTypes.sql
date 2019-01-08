DECLARE 
    v_id           tbl_dict_workactivitytype.col_id%TYPE; 
    v_errorcode    PLS_INTEGER := 0; 
    v_errormessage NCLOB := ''; 
    v_result       NUMBER; 
	v_countUsed INTEGER;
BEGIN 
    :affectedRows := 0; 
    v_id := :WorkActivityType_Id; 

    ---Input params check   
    IF ( v_id IS NULL ) THEN 
      v_result := Loc_i18n(messagetext => 'Id can not be empty', messageresult => v_errormessage); 
      v_errorcode := 101; 
      GOTO cleanup; 
    END IF; 

	--check that the type is not used anywhere
	SELECT COUNT(1) 
	INTO v_countUsed
	FROM TBL_DCM_WORKACTIVITY
	WHERE COL_WORKACTIVITYTYPE = v_id;
	
	IF v_countUsed > 0 THEN
		v_result := Loc_i18n(messagetext => 'Can not delete this type because it is being used in runtime', messageresult => v_errormessage); 
		v_errorcode := 101; 
		GOTO cleanup; 
	END IF;
	
	
    DELETE tbl_dict_workactivitytype 
    WHERE  col_id = v_id; 

    --get affected rows  
    :affectedRows := SQL%rowcount; 

    v_result := Loc_i18n(
				messagetext => 'Deleted {{MESS_COUNT}} items', 
				messageresult => :SuccessResponse, 
				messageparams => Nes_table(Key_value( 'MESS_COUNT', :affectedRows ))
				); 

    <<cleanup>> 
    :ErrorMessage := v_errormessage; 

    :ErrorCode := v_errorcode; 
END; 