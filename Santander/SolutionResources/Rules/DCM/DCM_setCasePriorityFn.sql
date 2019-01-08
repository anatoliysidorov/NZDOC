DECLARE 
  --input 
  v_caseid           INTEGER; 
  v_new_priorityid   INTEGER; 

  --calculate 
  v_new_priorityname NVARCHAR2(255); 
  v_old_priorityid   INTEGER; 
  v_old_priorityname NVARCHAR2(255); 
  v_isincache        INTEGER; 
  v_CSisInCache      INTEGER;
  v_result           INTEGER; 

  --standard 
  v_message          NCLOB;  
  v_errorcode        NUMBER; 
BEGIN 
  --input
  v_caseid :=         :Case_Id; 
  v_new_priorityid := :Priority_Id; 
  
  --init
  v_message := ''; 
  v_isincache := F_dcm_iscaseincache(v_caseid); 
  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache

  --standard 
  v_errorcode := 0; 

  -- BASIC ERROR CHECKS 
  IF Nvl(v_new_priorityid, 0) = 0 THEN 
    v_errorcode := 101; 
    v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'ERROR: Priority ID can not be empty'); 
    GOTO cleanup; 
  END IF; 

  --GET INFORMATION ABOUT THE OLD AND NEW PRIORITY 
  BEGIN 
    IF v_isincache = 1 THEN 
      v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'INFO: Case is in cache'); 

      SELECT col_stp_prioritycasecc 
      INTO   v_old_priorityid 
      FROM   tbl_casecc 
      WHERE  col_id = v_caseid; 
    END IF;

    --new cache
    IF v_CSisInCache=1 THEN  
      v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'INFO: Case is in cache'); 
      
      SELECT COL_STP_PRIORITYCASE INTO   v_old_priorityid 
      FROM   TBL_CSCASE 
      WHERE  col_id = v_caseid; 
    END IF; 
    
    IF (v_isincache = 0) AND (v_CSisInCache=0) THEN 
      v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'INFO: Case is not in cache'); 

      SELECT COL_STP_PRIORITYCASE INTO   v_old_priorityid 
      FROM   TBL_CASE 
      WHERE  col_id = v_caseid; 
    END IF; 
      
  EXCEPTION 
      WHEN no_data_found THEN 
        v_errorcode := 102; 
        v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'ERROR: Case is missing' ); 
        GOTO cleanup; 
  END; 

  IF Nvl(v_old_priorityid, 0) > 0 THEN 
    BEGIN 
        SELECT col_name || ' (' || To_char(col_value) || ')' 
        INTO   v_old_priorityname 
        FROM   tbl_stp_priority 
        WHERE  col_id = v_old_priorityid; 

        v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'INFO: The previous Priority was ' || v_old_priorityname); 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_old_priorityname := 'No Priority'; 
          v_message := F_util_addtomessage(originalmsg => v_message, 
          newmsg => 'WARNING: The previous Priority of this Case is missing'); 
    END; 
  ELSE 
    v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'INFO: Case did not have a Priority set before this operation'); 
  END IF; 

  BEGIN 
      SELECT col_name || ' (' || To_char(col_value) || ')' 
      INTO   v_new_priorityname 
      FROM   tbl_stp_priority 
      WHERE  col_id = v_new_priorityid; 

      v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'INFO: The new Priority will be ' || v_new_priorityname); 
  EXCEPTION 
      WHEN no_data_found THEN 
        v_errorcode := 103; 
        v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'ERROR: Priority with ID ' || To_char( v_new_priorityid) || ' is missing'); 
        GOTO cleanup; 
  END; 

  --SET CASE PRIORITY 
  IF v_isincache = 1 THEN 
    UPDATE tbl_casecc 
    SET    col_stp_prioritycasecc = v_new_priorityid 
    WHERE  col_id = v_caseid; 
  END IF; 

  --new cache
  IF v_CSisInCache=1 THEN   
    UPDATE TBL_CSCASE 
    SET    COL_STP_PRIORITYCASE = v_new_priorityid  
    WHERE  col_id = v_caseid; 
  END IF; 
    
  IF (v_isincache = 0) AND (v_CSisInCache=0) THEN  
    UPDATE tbl_case 
    SET    col_stp_prioritycase = v_new_priorityid 
    WHERE  col_id = v_caseid; 
  END IF; 

  --SET ASSUMED SUCCESS MESSAGE 
  SuccessResponse := 'Case Priority has been changed from ' || v_old_priorityname || ' to ' || v_new_priorityname; 

  --WRITE HISTORY AND PROCESS ERRORS 
  IF ( Nvl(v_errorcode, 0) = 0 ) THEN 
    v_result := F_hist_createhistoryfn(additionalinfo => SuccessResponse, issystem => 0, message => NULL, messagecode => 'CasePriorityChanged', targetid => v_caseid, targettype => 'CASE'); 
    RETURN v_new_priorityid; 
  ELSE 
    GOTO cleanup; 
  END IF; 

  <<cleanup>> 
  v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'ERROR CODE: ' || v_errorcode); 
  v_result := F_hist_createhistoryfn(additionalinfo => v_message, issystem => 0, message => NULL,  messagecode => 'CasePriorityChangeFailed', targetid => v_caseid, targettype => 'CASE'); 

  :errorCode := v_errorcode; 
  :errorMessage := v_message; 
  :SuccessResponse := ''; 
  RETURN 0; 
END; 