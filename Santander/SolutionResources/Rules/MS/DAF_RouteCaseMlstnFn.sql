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
  v_Context  NVARCHAR2(255); 

BEGIN
  --INPUT
  v_CaseId        := :CaseId;
  v_Target        := :Target;
  v_ResolutionId  := :ResolutionId;
  v_Workbasketid  := :WorkbasketId;  
  v_RoutingDescription := :Note;
  v_TransitionId       := :TransitionId;
  v_Context := :Context;  
    
  --ROUTE THE CASE  
  BEGIN
    v_result := f_DIF_RouteCaseMlstnFn(TRANSITIONID =>v_TransitionId,
                                    ERRORCODE => v_tempErrCd ,
                                    ERRORMESSAGE => v_tempErrMsg ,
                                    TARGET => v_target ,
                                    RESOLUTIONID => v_ResolutionId ,
                                    CASEID => v_CaseId ,
                                    WORKBASKETID => v_WorkbasketId,
                                    NOTE =>v_RoutingDescription,
                                    CONTEXT=>v_Context);
    
    IF NVL(v_tempErrCd, 0) > 0 THEN      
      GOTO cleanup;
    END IF;
  EXCEPTION 
    WHEN OTHERS THEN GOTO cleanup;
  END; 
                
  /*--SUCCESS BLOCK*/
  :ERRORCODE := 0;
  :ERRORMESSAGE := '';
  RETURN 0;
    
  /*--ERROR BLOCK*/
  <<cleanup>> 
  v_message := f_UTIL_addToMessage(originalMsg => v_message,newMsg => 'ERROR CODE: ' || v_tempErrCd);
  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR MSG: ' || v_tempErrMsg);
    
  :ERRORCODE := v_tempErrCd;
  :ERRORMESSAGE := v_message;

  RETURN -1;  
END;