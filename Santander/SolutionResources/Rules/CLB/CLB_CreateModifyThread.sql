DECLARE 
    v_id                NUMBER; 
    v_code              NVARCHAR2(255); 
    v_status            NVARCHAR2(255); 
    v_message           NCLOB; 
    v_messageworkbasket NUMBER; 
    v_case_id           NUMBER; 
    v_parentthread      NUMBER; 
    v_errorcode         NUMBER; 
    v_errormessage      NVARCHAR2(255); 
	v_TargetID INT;
	v_TargetType NVARCHAR2(30);
	v_result INT;
BEGIN 
    v_id := :Id; 
    v_code := :Code;     
    v_status := Nvl(:Status, 'ACTIVE'); 
    v_message := :Message; 
    v_parentthread := :ParentThread; 
    v_case_id := :Case_Id; 
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := ''; 

    --set success message 
    IF v_id IS NOT NULL THEN 
      :SuccessResponse := 'Updated'; 
    ELSE 
      :SuccessResponse := 'Created'; 
    END IF; 

    :SuccessResponse := :SuccessResponse || ' thread'; 

    BEGIN 
        --add new record or update existing one 
        IF v_id IS NULL THEN 
			IF(v_parentthread IS NOT NULL) THEN
				v_id := f_TRD_attachMessage(Message=>v_message, ParentId=>v_parentthread);
			ELSE
			  INSERT INTO tbl_thread 
						  (
						  col_code,
						  col_threadcase,
						  col_parentmessageid,
						  col_status) 
			  VALUES      (
							v_code,
							v_case_id,
							v_parentthread,
							'ACTIVE') 
			  returning col_id INTO v_id; 
			  
				IF v_case_Id > 0 THEN
					v_TargetID := v_case_Id;
					v_TargetType := 'CASE';
				END IF;
				
				IF v_TargetID > 0 THEN
					v_result := f_HIST_createHistoryFn(
						AdditionalInfo => NULL,  
						IsSystem=>0, 
						Message=> NULL,
						MessageCode => 'ThreadCreated', 
						TargetID => v_TargetID, 
						TargetType=>v_TargetType
					);				
				END IF;
			END IF;

        END IF; 

        UPDATE tbl_thread 
        SET     
               col_message = v_message
        WHERE  col_id = v_id; 

        :affectedRows := 1; 
        :recordId := v_id; 
    EXCEPTION 
        WHEN OTHERS THEN 
          :affectedRows := 0;
          v_errorcode := 101; 
          v_errormessage := Substr(SQLERRM, 1, 200); 
          :SuccessResponse := ''; 
    END; 

    <<cleanup>> 
    :errorCode := v_errorcode; 
    :errorMessage := v_errormessage; 
END;