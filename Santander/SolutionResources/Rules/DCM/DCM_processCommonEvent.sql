DECLARE
  v_eventcode NVARCHAR2(255);
  v_eventname NVARCHAR2(255);
  v_eventprocessor NVARCHAR2(255);
  v_eventorder INTEGER;
  v_commoneventtype NVARCHAR2(255);
  v_eventmoment NVARCHAR2(255);
  v_eventtype NVARCHAR2(255);
  v_validationresult NUMBER;
  v_result NUMBER;
  v_resultTotal NUMBER;
  v_input NCLOB;
  v_caseid NUMBER;
  v_casetypeid NUMBER;
  v_procedureid NUMBER;
  v_taskid NUMBER;
  v_tasktypeid NUMBER;
  v_ErrorCode NUMBER;
  v_ErrorMessage NCLOB;
  v_Domain NVARCHAR2(255);
  v_Params NCLOB;
  v_commonEventCode NVARCHAR2(255);
  v_historyMsg NCLOB;
  v_Attributes NCLOB;
  v_commoneventtype_ID INT;
  v_eventmoment_ID INT;
  v_eventtype_ID INT;
  v_validationType_ID INT;
  v_InData CLOB;
  v_outData CLOB;
  
BEGIN
  --input
  v_caseid          := :CaseId;
  v_casetypeid      := :CaseTypeId;
  v_procedureid     := :ProcedureId;
  v_taskid          := :TaskId;
  v_tasktypeid      := :TaskTypeId;
  v_commoneventtype := lower(:CommonEventType); /* CREATE_CASE, UPDATE_CASE_DATA etc */
  v_eventmoment     := lower(:EventMoment); /* BEFORE or AFTER */
  v_eventtype       := lower(:EventType); /* VALIDATION or ACTION */
  v_commonEventCode := lower(:Code);
  v_Attributes      := :Attributes;
  v_InData          := :InData;
  
  v_outData         := NULL;
  
  --get IDs for dictionary values
  BEGIN
      SELECT COL_ID
      INTO
             v_commoneventtype_ID
      FROM   TBL_DICT_COMMONEVENTTYPE
      WHERE  lower(col_code) = v_commoneventtype;
      
      --DBMS_OUTPUT.PUT_LINE('v_commoneventtype_ID' || ' ' || v_commoneventtype_ID);
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
      NULL;
  END;
  BEGIN
      SELECT COL_ID
      INTO
             v_eventmoment_ID
      FROM   TBL_DICT_TASKEVENTMOMENT
      WHERE  lower(col_code) = v_eventmoment;
      
      --DBMS_OUTPUT.PUT_LINE('v_eventmoment_ID' || ' ' || v_eventmoment_ID);
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
      NULL;
  END;
  BEGIN
      SELECT COL_ID
      INTO
             v_eventtype_ID
      FROM   TBL_DICT_TASKEVENTTYPE
      WHERE  lower(col_code) = v_eventtype;
      
      --DBMS_OUTPUT.PUT_LINE('v_eventtype_ID' || ' ' || v_eventtype_ID);
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
      NULL;
  END;
  BEGIN
      SELECT COL_ID
      INTO
             v_validationType_ID
      FROM   TBL_DICT_TASKEVENTTYPE
      WHERE  lower(col_code) = 'validation';
      
      --DBMS_OUTPUT.PUT_LINE('v_validationType_ID' || ' ' || v_validationType_ID);
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
      NULL;
  END;
	
  --GET INFO ABOUT TYPES IF NEEDED
  IF v_taskid > 0 AND NVL(v_tasktypeid,0) = 0 THEN
      v_tasktypeid := f_DCM_getTaskTypeForTask(v_taskid);
  END IF;
  IF v_caseid > 0 AND NVL(v_casetypeid,0) = 0 THEN
      v_casetypeid := f_DCM_getCaseTypeForCase(v_caseid);
  END IF;
	
  --CREATE INPUT XML FOR CALLS
  IF v_Attributes IS NOT NULL THEN
      v_input := v_input || v_Attributes;
  END IF;
  v_input := v_input || '<CaseId>' || TO_CHAR(v_caseid) || '</CaseId>';
  v_input := v_input || '<CaseTypeId>' || TO_CHAR(v_casetypeid) || '</CaseTypeId>';
  v_input := v_input || '<ProcedureId>' || TO_CHAR(v_procedureid) || '</ProcedureId>';
  v_input := v_input || '<TaskId>' || TO_CHAR(v_taskid) || '</TaskId>';
  v_input := v_input || '<TaskTypeId>' || TO_CHAR(v_tasktypeid) || '</TaskTypeId>';

  --READ DOMAIN FROM CONFIGURATION
  v_Domain := f_UTIL_getDomainFn();
	
  --EXECUTE EVENTS WHEN DOING OPERATIONS WITH AN EXISTING PROCEDURE
  IF v_procedureid > 0 THEN
      --DBMS_OUTPUT.PUT_LINE('ENTER PROCEDURE EVENTS');
      FOR rec IN(SELECT  col_id,
               col_processorcode,
               COL_REPEATINGEVENT,
               COL_COMMONEVENTTASKEVENTTYPE
      FROM     TBL_COMMONEVENT
      WHERE    COL_COMEVENTCOMEVENTTYPE = v_commoneventtype_ID
               AND COL_COMMONEVENTEVENTMOMENT = v_eventmoment_ID
               AND COL_COMMONEVENTTASKEVENTTYPE = v_eventtype_ID
               AND NVL(COL_ISPROCESSED,0) = 0
               AND COL_COMMONEVENTPROCEDURE = v_procedureid
      ORDER BY col_eventorder ASC)
      LOOP 
          --DBMS_OUTPUT.PUT_LINE('PROCEDURE - ' || rec.col_processorcode);
          --for safety when the same the procedure injects itself
          IF rec.COL_REPEATINGEVENT = 0 THEN
              UPDATE TBL_COMMONEVENT
              SET    col_ISPROCESSED = 1
              WHERE  COL_ID = rec.col_id;
          
          END IF;
          --execute functions sync and others as async
          IF lower(SUBSTR(rec.col_processorcode,1,2)) = 'f_' THEN
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'XML');
              v_result := f_UTIL_genericProcInvokerFn(INDATA =>v_InData,
                                                      OUTDATA =>v_outData,
                                                      ERRORCODE => v_ErrorCode,
                                                      ERRORMESSAGE => v_ErrorMessage,
                                                      INPUT => v_Params,
                                                      PROCESSORNAME => rec.col_processorcode,
                                                      VALIDATIONRESULT => v_validationresult);
              --check if validation passed         	
              IF rec.COL_COMMONEVENTTASKEVENTTYPE = v_validationType_ID AND v_validationresult = 0 THEN
                  --DBMS_OUTPUT.PUT_LINE('ERROR');
                  GOTO cleanup;
              END IF;
          ELSE
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'JSON');
              v_result := f_UTIL_addToQueueFn(  RULECODE => rec.col_processorcode,
                                                PARAMETERS => v_Params);
          END IF;
      END LOOP;
  END IF;

  --EXECUTE EVENTS WHEN DOING OPERATIONS ON AN EXISTING TASK
  IF v_taskid > 0 THEN
      --DBMS_OUTPUT.PUT_LINE('ENTER TASK EVENTS');
      FOR rec IN(SELECT  col_id,
               col_processorcode,
               COL_REPEATINGEVENT,
               COL_COMMONEVENTTASKEVENTTYPE
      FROM     TBL_COMMONEVENT
      WHERE    COL_COMEVENTCOMEVENTTYPE = v_commoneventtype_ID
               AND COL_COMMONEVENTEVENTMOMENT = v_eventmoment_ID
               AND COL_COMMONEVENTTASKEVENTTYPE = v_eventtype_ID
               AND NVL(COL_ISPROCESSED,0) = 0
               AND COL_COMMONEVENTTASK = v_taskid
      ORDER BY col_eventorder ASC)
      LOOP
          --DBMS_OUTPUT.PUT_LINE('TASK - ' || rec.col_processorcode);
          --for safety when the same the procedure injects itself
          IF rec.COL_REPEATINGEVENT = 0 THEN
              UPDATE TBL_COMMONEVENT
              SET    col_ISPROCESSED = 1
              WHERE  COL_ID = rec.col_id;
          
          END IF;
          --execute functions sync and others as async
          IF lower(SUBSTR(rec.col_processorcode,1,2)) = 'f_' THEN
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'XML');
              v_result := f_UTIL_genericProcInvokerFn(INDATA =>v_InData,
                                                      OUTDATA =>v_outData,
                                                      ERRORCODE => v_ErrorCode,
                                                      ERRORMESSAGE => v_ErrorMessage,
                                                      INPUT => v_Params,
                                                      PROCESSORNAME => rec.col_processorcode,
                                                      VALIDATIONRESULT => v_validationresult);
              --check if validation passed         	
              IF rec.COL_COMMONEVENTTASKEVENTTYPE = v_validationType_ID AND v_validationresult = 0 THEN
                  --DBMS_OUTPUT.PUT_LINE('ERROR');
                  GOTO cleanup;
              END IF;
          ELSE
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'JSON');
              v_result := f_UTIL_addToQueueFn(  RULECODE => rec.col_processorcode,
                                                PARAMETERS => v_Params);
          END IF;
      END LOOP;
  END IF;

  --EXECUTE EVENTS WHEN DOING OPERATIONS ON AN EXISTING CASE
  IF v_caseid > 0 THEN
      --DBMS_OUTPUT.PUT_LINE('ENTER CASE EVENTS');
      --DBMS_OUTPUT.PUT_LINE('CASE - ' || v_caseid);
      FOR rec IN(SELECT  col_id,
               col_processorcode,
               COL_REPEATINGEVENT,
               COL_COMMONEVENTTASKEVENTTYPE
      FROM     TBL_COMMONEVENT
      WHERE    COL_COMEVENTCOMEVENTTYPE = v_commoneventtype_ID
               AND COL_COMMONEVENTEVENTMOMENT = v_eventmoment_ID
               AND COL_COMMONEVENTTASKEVENTTYPE = v_eventtype_ID
               AND NVL(COL_ISPROCESSED,0) = 0
               AND COL_COMMONEVENTCASE = v_caseid
               AND NVL(COL_COMMONEVENTTASK,0) = 0
      ORDER BY col_eventorder ASC)
      LOOP
          --DBMS_OUTPUT.PUT_LINE('CASE - ' || rec.col_processorcode);
          --DBMS_OUTPUT.PUT_LINE(lower(SUBSTR(rec.col_processorcode,1,2)));
          --for safety when the same the procedure injects itself
          IF rec.COL_REPEATINGEVENT = 0 THEN
              UPDATE TBL_COMMONEVENT
              SET    col_ISPROCESSED = 1
              WHERE  COL_ID = rec.col_id;
          
          END IF;
          --execute functions sync and others as async
          IF lower(SUBSTR(rec.col_processorcode,1,2)) = 'f_' THEN
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'XML');
              v_result := f_UTIL_genericProcInvokerFn(INDATA =>v_InData,
                                                      OUTDATA =>v_outData,
                                                      ERRORCODE => v_ErrorCode,
                                                      ERRORMESSAGE => v_ErrorMessage,
                                                      INPUT => v_Params,
                                                      PROCESSORNAME => rec.col_processorcode,
                                                      VALIDATIONRESULT => v_validationresult);
              --check if validation passed         	
              IF rec.COL_COMMONEVENTTASKEVENTTYPE = v_validationType_ID AND v_validationresult = 0 THEN
                  --DBMS_OUTPUT.PUT_LINE('ERROR');
                  GOTO cleanup;
              END IF;
          ELSE
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'JSON');
              v_result := f_UTIL_addToQueueFn(  RULECODE => rec.col_processorcode,
                                                PARAMETERS => v_Params);
          END IF;
      END LOOP;
  END IF;

  --EXECUTE EVENTS WHEN DOING OPERATIONS ON A NON-EXISTENT TASK
  IF NVL(v_taskid,0) = 0 AND v_tasktypeid > 0 AND(v_commonEventCode IS NOT NULL) THEN
      --DBMS_OUTPUT.PUT_LINE('ENTER NON-EXISTENT TASKS');
      FOR rec IN(SELECT  col_id,
               col_processorcode,
               COL_REPEATINGEVENT,
               COL_COMMONEVENTTASKEVENTTYPE
      FROM     TBL_COMMONEVENT
      WHERE    COL_COMEVENTCOMEVENTTYPE = v_commoneventtype_ID
               AND COL_COMMONEVENTEVENTMOMENT = v_eventmoment_ID
               AND COL_COMMONEVENTTASKEVENTTYPE = v_eventtype_ID
               AND NVL(COL_ISPROCESSED,0) = 0
               AND NVL(COL_COMMONEVENTTASK,0) = 0
               AND COL_COMMONEVENTTASKTYPE = v_tasktypeid
               AND LOWER(COL_LINKCODE) = v_commonEventCode
      ORDER BY col_eventorder ASC)
      LOOP
          --DBMS_OUTPUT.PUT_LINE('TASK NON EXISTENT - ' || rec.col_processorcode);
          --for safety when the same the procedure injects itself
          IF rec.COL_REPEATINGEVENT = 0 THEN
              UPDATE TBL_COMMONEVENT
              SET    col_ISPROCESSED = 1
              WHERE  COL_ID = rec.col_id;
          
          END IF;
          --execute functions sync and others as async
          IF lower(SUBSTR(rec.col_processorcode,1,2)) = 'f_' THEN
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'XML');
              v_result := f_UTIL_genericProcInvokerFn(INDATA =>v_InData,
                                                      OUTDATA =>v_outData,
                                                      ERRORCODE => v_ErrorCode,
                                                      ERRORMESSAGE => v_ErrorMessage,
                                                      INPUT => v_Params,
                                                      PROCESSORNAME => rec.col_processorcode,
                                                      VALIDATIONRESULT => v_validationresult);
              --check if validation passed         	
              IF rec.COL_COMMONEVENTTASKEVENTTYPE = v_validationType_ID AND v_validationresult = 0 THEN
                  --DBMS_OUTPUT.PUT_LINE('ERROR');
                  GOTO cleanup;
              END IF;
          ELSE
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'JSON');
              v_result := f_UTIL_addToQueueFn(  RULECODE => rec.col_processorcode,
                                                PARAMETERS => v_Params);
          END IF;
      END LOOP;
  END IF;

  --EXECUTE EVENTS WHEN DOING OPERATIONS ON A NON-EXISTENT CASE
  IF NVL(v_caseid,0) = 0 AND v_casetypeid > 0 AND(v_commonEventCode IS NOT NULL) THEN
      --DBMS_OUTPUT.PUT_LINE('ENTER NON-EXISTENT CASE');
      FOR rec IN(SELECT  col_id,
               col_processorcode,
               COL_REPEATINGEVENT,
               COL_COMMONEVENTTASKEVENTTYPE
      FROM     TBL_COMMONEVENT
      WHERE    COL_COMEVENTCOMEVENTTYPE = v_commoneventtype_ID
               AND COL_COMMONEVENTEVENTMOMENT = v_eventmoment_ID
               AND COL_COMMONEVENTTASKEVENTTYPE = v_eventtype_ID
               AND NVL(COL_ISPROCESSED,0) = 0
               AND NVL(COL_COMMONEVENTCASE,0) = 0
               AND COL_COMMONEVENTCASETYPE = v_casetypeid
               AND LOWER(COL_LINKCODE) = v_commonEventCode
      ORDER BY col_eventorder ASC)
      LOOP
          --DBMS_OUTPUT.PUT_LINE('CASE NON EXISTENT - ' || rec.col_processorcode);
          --for safety when the same the procedure injects itself
          IF rec.COL_REPEATINGEVENT = 0 THEN
              UPDATE TBL_COMMONEVENT
              SET    col_ISPROCESSED = 1
              WHERE  COL_ID = rec.col_id;
          
          END IF;
          --execute functions sync and others as async
          IF lower(SUBSTR(rec.col_processorcode,1,2)) = 'f_' THEN
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'XML');
              v_result := f_UTIL_genericProcInvokerFn(INDATA =>v_InData,
                                                      OUTDATA =>v_outData,
                                                      ERRORCODE => v_ErrorCode,
                                                      ERRORMESSAGE => v_ErrorMessage,
                                                      INPUT => v_Params,
                                                      PROCESSORNAME => rec.col_processorcode,
                                                      VALIDATIONRESULT => v_validationresult);
              --check if validation passed         	
              IF rec.COL_COMMONEVENTTASKEVENTTYPE = v_validationType_ID AND v_validationresult = 0 THEN
                  --DBMS_OUTPUT.PUT_LINE('ERROR');
                  GOTO cleanup;
              END IF;
          ELSE
              v_Params := f_UTIL_getDataFromARP(ATTRIBUTES =>v_input,
                                                CASEID =>v_CaseId,
                                                PARENTID =>rec.col_id,
                                                TYPEOFQUERY =>'COMMONEVENTS',
                                                DATATYPEFORMAT =>'JSON');
              v_result := f_UTIL_addToQueueFn(  RULECODE => rec.col_processorcode,
                                                PARAMETERS => v_Params);
          END IF;
      END LOOP;
  END IF;

  --CALCULATE RESULTS
  IF v_validationresult IS NULL THEN
      v_validationresult := 1; --no validation result means everything was OK
  ELSIF v_validationresult = 0 AND v_ErrorMessage IS NULL THEN
      v_ErrorMessage := 'There was an error processing the action';
  END IF;

  --DBMS_OUTPUT.PUT_LINE('============');
  --RETURN
  :ErrorCode        := v_ErrorCode;
  :ErrorMessage     := v_ErrorMessage;
  :ValidationResult := v_validationresult;
  :HistoryMessage   := v_historyMsg;
  :OutData          := v_outData;
  RETURN 0;
  
  <<cleanup>> 
  :ErrorCode        := v_ErrorCode;
  :ErrorMessage     := v_ErrorMessage;
  :ValidationResult := v_validationresult;
  :HistoryMessage   := v_historyMsg;
  :OutData          := v_outData;
  RETURN -1;
  
END;