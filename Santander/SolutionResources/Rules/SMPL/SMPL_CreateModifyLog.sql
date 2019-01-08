DECLARE 
    --custom 
    v_id           NUMBER; 
	v_task_id           NUMBER; 
	v_case_id           NUMBER; 
    v_eventname         NVARCHAR2(255);
    v_eventtype_id        NUMBER;
    v_isdeleted    NUMBER; 
	v_description  NCLOB; 
	
    --standard 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
BEGIN 	
    --custom
    v_id := :Id; 
	v_case_id := :Case_Id; 
    v_eventname := :eventname; 
    v_isdeleted := NVL(:IsDeleted, 0); 
	v_description := :Description; 
	v_Task_Id := :Task_Id; 
    v_eventtype_id := :EventType_Id;
	
	--standard
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := ''; 

    BEGIN 
		--set assumed success message
		IF v_id IS NOT NULL THEN
			:SuccessResponse := 'Updated';
		ELSE
			:SuccessResponse := 'Created';
		END IF;
		:SuccessResponse := :SuccessResponse || ' ' || v_eventname || ' logged event';
       
        --create new record if needed
        IF v_id IS NULL THEN 
			INSERT INTO tbl_SMPL_Log(col_CaseLog, col_TaskLog, Col_Smpl_Logdict_Customword) 
			VALUES (v_case_id, v_Task_Id, v_eventtype_id); 

			SELECT GEN_TBL_SMPL_Log.CURRVAL 
			INTO   v_id 
			FROM   dual;
		END IF; 

		--update the record
		UPDATE tbl_SMPL_Log
		SET    
			col_eventname = v_eventname, 
			col_isDeleted = v_isdeleted,
			col_description = v_description,
            Col_Smpl_Logdict_Customword = v_eventtype_id
		WHERE  col_id = v_id; 
				
		--set output
		:affectedRows := sql%rowcount; 
		:recordId := v_id; 		
    EXCEPTION 
        WHEN OTHERS THEN 
			:affectedRows := 0; 
			v_errorcode := 102; 
			v_errormessage := substr(SQLERRM, 1, 200);
			:SuccessResponse := ''; 
    END; 
	:errorCode := v_errorcode;
	:errorMessage := v_errormessage;		
END;