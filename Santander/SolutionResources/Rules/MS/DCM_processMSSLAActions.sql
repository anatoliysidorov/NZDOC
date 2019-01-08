DECLARE
  v_CaseId      NUMBER;
  v_result      NUMBER;
  v_isValid     NUMBER;
  v_EventType   NVARCHAR2(255);
  v_EventState  NVARCHAR2(255);
  v_EventMoment NVARCHAR2(255);
  v_Params      NCLOB;
  v_Domain      NVARCHAR2(255);
  v_UserAccessSubject NVARCHAR2(255);  

  v_stateConfigId NUMBER;
  v_SLAEvtId      NUMBER;
   
  --errors variables
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
  v_outData       CLOB;

BEGIN
  v_stateConfigId     := :StateConfigId;
  v_CaseId            := :CaseId;
  v_SLAEvtId          := :SLAEvtId; 
  v_Domain            := :pDomain;
  v_UserAccessSubject := :pUserAccessSubject;  
  
  v_isValid       := 1;
  v_errorMessage  := NULL;
  v_errorCode     := NULL;
  v_Params        := NULL;
  v_outData       := NULL;
  
  IF (v_CaseId IS NULL) AND (v_stateConfigId IS  NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A both Id values cannot be NULL';
    GOTO cleanup;
  END IF;

  IF (v_SLAEvtId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A SLA Event Id cannot be NULL';
    GOTO cleanup;
  END IF;  

  --main query
  FOR rec IN
  (
    SELECT ssa.COL_ID AS ActionId, ssa.COL_PROCESSORCODE AS ProcessorName,
           CASE 
            WHEN lower(substr(ssa.COL_PROCESSORCODE, 1, instr(ssa.COL_PROCESSORCODE, '_', 1, 1))) = 'f_' then 1 
            ELSE 0 
           END AS IsFunction                          
    FROM TBL_DICT_STATESLAACTION ssa 
    WHERE ssa.COL_STATESLAACTNSTATESLAEVNT=v_SLAEvtId
         /* a code is working (commented by VV)
             now we use a "transition way" for a solve this issue    
          AND ssa.COL_ID  NOT IN 
          (SELECT COL_SLAQUEUEDICT_STSLAACT 
           FROM TBL_MSSLAQUEUE
           WHERE COL_MSSLAQUEUECASE=v_CaseId AND
                 COL_SLAQUEUEDICT_STSLAEVENT = v_SLAEvtId AND
                 COL_DATAFLAG=1)    
         */                 
    ORDER BY ssa.COL_SLAACTIONORDER ASC  
  )
  LOOP
    v_Params := NULL;
    IF NVL(rec.IsFunction,0) =0 THEN
      v_Params:= f_UTIL_getDataFromARPTmpl(ATTRIBUTES =>NULL,
                                           CASEID         =>v_CaseId,
                                           PARENTID       =>rec.ActionId, 
                                           TYPEOFQUERY    =>'SLAACTION', 
                                           DATATYPEFORMAT =>'JSON');
      v_result := f_UTIL_addToQueueFn(RuleCode => rec.ProcessorName, Parameters => v_Params);
    END IF;

    IF NVL(rec.IsFunction,0) =1 THEN
      v_Params:= f_UTIL_getDataFromARPTmpl(ATTRIBUTES     =>NULL,
                                           CASEID         =>v_CaseId,
                                           PARENTID       =>rec.ActionId, 
                                           TYPEOFQUERY    =>'SLAACTION', 
                                           DATATYPEFORMAT =>'XML');
      --CALL PROCESSOR FUNCTION HERE AND GET RETURN VALUE
      v_isValid := 1;
/*    deprecated , will be deleted later      
  	  v_result := f_DCM_invokeMSEventProcessor(CASEID   =>v_CaseId, 
                                               INPUT    =>v_Params, 
                                               MESSAGE  =>v_errorMessage, 
                                               PROCESSORNAME    =>rec.ProcessorName, 
                                               STATEID          =>NULL, 
                                               STEVENTID        =>NULL, 
                                               VALIDATIONRESULT =>v_isValid);      
*/
      v_result := f_UTIL_genericProcInvokerFn(INDATA => NULL,
                                              OUTDATA =>v_outData,
                                              ERRORCODE => v_ErrorCode,
                                              ERRORMESSAGE => v_ErrorMessage,
                                              INPUT => v_Params,
                                              PROCESSORNAME => rec.ProcessorName,
                                              VALIDATIONRESULT => v_isValid);
/*
      if v_isValid = 0 THEN
        v_errorCode := 102;
        EXIT;
      end if;*/
    END IF;
  END LOOP;
  
  --IF v_isValid <> 1 THEN   GOTO cleanup; END IF;

  v_errorCode :=NULL;
  v_errorMessage :=NULL;

  :IsValid := 1;--v_isValid;
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  RETURN 0;  

  --error block
  <<cleanup>>
  :IsValid := 0;
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;  
  RETURN -1;
end;
