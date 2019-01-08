DECLARE
  --INPUT
  v_CaseId NUMBER;
  v_TransitionId NUMBER;
  v_Target NVARCHAR2(255);
  v_ResolutionId NUMBER;
  v_WorkbasketId NUMBER;
  v_RoutingDescription NVARCHAR2(4000);
    
  v_result INTEGER;
  v_tempErrCd INTEGER;
  v_tempErrMsg NCLOB;
  v_tempSccss NCLOB;
  v_message NCLOB;  

BEGIN
  --INPUT
  v_CaseId        := :CaseId;
  v_Target        := :Target;
  v_ResolutionId  := :ResolutionId;
  v_Workbasketid  := :WorkbasketId;  
  v_RoutingDescription := :RoutingDescription;
  v_TransitionId       := :TransitionId;
    
  --ROUTE THE CASE
  v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'INFO: Attempting to route Case to target milestone');
  BEGIN
    v_result := f_DAF_RouteCaseMlstnFn(TRANSITIONID =>v_TransitionId,
                                    ERRORCODE => v_tempErrCd ,
                                    ERRORMESSAGE => v_tempErrMsg ,
                                    TARGET => v_target ,
                                    RESOLUTIONID => v_ResolutionId ,
                                    CASEID => v_CaseId ,
                                    WORKBASKETID => v_WorkbasketId,
                                    NOTE =>v_RoutingDescription,
                                    CONTEXT=>'CASE_MS_ROUTE');
    
    IF NVL(v_tempErrCd, 0) > 0 THEN
      v_message := f_UTIL_addToMessage( originalMsg => v_message,newMsg => 'ERROR: There was an error routing the Case');
      GOTO cleanup;
    ELSE
      v_message := f_UTIL_addToMessage( originalMsg => v_message,newMsg => 'INFO: Succesfully routed Case');
      v_tempSccss := 'Succesfully routed';
    END IF;
  EXCEPTION 
    WHEN OTHERS THEN GOTO cleanup;
  END; 
                
  /*--SUCCESS BLOCK*/
  :ERRORCODE := 0;
  :ERRORMESSAGE := '';
  :SUCCESSRESPONSE := v_tempSccss;
  :EXECUTIONLOG := v_message;
  RETURN;
    
  /*--ERROR BLOCK*/
  <<cleanup>> 
  v_message := f_UTIL_addToMessage(originalMsg => v_message,newMsg => 'ERROR CODE: ' || v_tempErrCd);
  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR MSG: ' || v_tempErrMsg);
  
  IF v_CaseId > 0 THEN
    v_result := f_HIST_createHistoryFn(AdditionalInfo => v_message,
                                       IsSystem => 0,
                                       MESSAGE => NULL,
                                       MessageCode => 'GenericEventFailure',
                                       TargetID => v_CaseId,
                                       TargetType => 'CASE');
  END IF;
  
  :ERRORCODE := v_tempErrCd;
  :ERRORMESSAGE := v_tempErrMsg;
  :EXECUTIONLOG := v_message;
  :SUCCESSRESPONSE := '';
  
  --ROLLBACK DATA AFTER FAILURE
  ROLLBACK;
EXCEPTION
WHEN OTHERS THEN
  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'SQL ERROR: ');
  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => dbms_utility.format_error_backtrace);
  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => dbms_Utility.format_error_stack);
  
  :ERRORCODE := 199;
  :ERRORMESSAGE := 'There was an error routing';
  :EXECUTIONLOG := v_message;
  :SUCCESSRESPONSE := '';
  
  --ROLLBACK DATA AFTER FAILURE
  ROLLBACK;
END;