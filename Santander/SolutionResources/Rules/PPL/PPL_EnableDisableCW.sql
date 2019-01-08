DECLARE 
    v_userid       NUMBER; 
    v_id           NUMBER; 
    v_status       NUMBER; 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
    v_successResponse NVARCHAR2(255);
    v_result 	   NUMBER;
BEGIN 
    v_userid := :UserId; 
    v_id := :CaseWorker_Id; 
    v_status := :Status; 
    v_errorcode := 0; 
    v_errormessage := '';
    v_successResponse  := '';

    IF v_userid IS NULL AND v_id IS NULL THEN 
      v_errorcode := 121; 
      v_errormessage := 'UserId or CaseWorker_Id must not be empty'; 
      GOTO cleanup; 
    END IF; 

    IF v_status IS NULL OR ( v_status <> 0 AND v_status <> 1 ) THEN 
      v_errorcode := 120; 
      v_errormessage := 'No Status or wrong status value provided'; 
      GOTO cleanup; 
    END IF; 

    UPDATE  tbl_ppl_caseworker 
    SET     col_isdeleted = v_status,
    	    COL_ISMANUAL = v_status
    WHERE   col_userid = v_userid OR col_id = v_id; 
    v_successResponse  := 'Case worker was updated';
    
    v_result := f_DCM_createCTAccessCache();
    
    <<cleanup>> 
    :ErrorCode := v_errorcode; 
    :ErrorMessage := v_errormessage;
    :SuccessResponse :=  v_successResponse;
END; 