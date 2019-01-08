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

  v_stateConfigId   NUMBER;
  v_Attributes      NVARCHAR2(4000);
  v_TransitionId    NUMBER;
  v_outData         CLOB;
   
  --errors variables
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(2000);

BEGIN
  v_stateConfigId := :StateConfigId;
  v_CaseId        := :CaseId;
  v_EventType     := :EvtType;
  v_EventMoment   := :EvtMoment;
  v_EventState    := :EvtState;
  v_Attributes    := :Attributes;

  v_isValid        := 1;
  v_errorMessage   := NULL;
  v_errorCode      := NULL;
  v_Params         := NULL;
  v_TransitionId   := NULL;
  v_outData        := NULL;
  
  IF (v_CaseId IS NULL) AND (v_stateConfigId IS  NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A both Id values cannot be NULL';
    GOTO cleanup;
  END IF;

  IF (v_EventType IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A Event Type cannot be NULL';
    GOTO cleanup;
  END IF;  

  IF (v_EventMoment IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A Event Moment cannot be NULL';
    GOTO cleanup;
  END IF;  

  IF (v_EventState IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A Event State cannot be NULL';
    GOTO cleanup;
  END IF; 

  IF (v_CaseId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A Case Id cannot be NULL';
    GOTO cleanup;
  END IF;

  IF (v_CaseId IS NOT NULL) AND (v_stateConfigId IS NULL) THEN
    IF f_DCM_CSisCaseInCache(v_caseid)=0 THEN
      BEGIN
        SELECT stcfg.COL_ID INTO v_stateConfigId
        FROM TBL_DICT_STATECONFIG stcfg
        INNER JOIN TBL_CASE c ON c.COL_CASEDICT_CASESYSTYPE=stcfg.COL_CASESYSTYPESTATECONFIG
        WHERE stcfg.COL_ISCURRENT=1
              AND c.col_id=v_CaseId;
      EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        v_stateConfigId :=NULL;
      WHEN TOO_MANY_ROWS THEN
        v_stateConfigId :=NULL;
      END;
    END IF; 

    IF f_DCM_CSisCaseInCache(v_caseid)=1 THEN
      BEGIN
        SELECT stcfg.COL_ID INTO v_stateConfigId
        FROM TBL_DICT_STATECONFIG stcfg
        INNER JOIN TBL_CSCASE c ON c.COL_CASEDICT_CASESYSTYPE=stcfg.COL_CASESYSTYPESTATECONFIG
        WHERE stcfg.COL_ISCURRENT=1
              AND c.col_id=v_CaseId;
      EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        v_stateConfigId :=NULL;
      WHEN TOO_MANY_ROWS THEN
        v_stateConfigId :=NULL;
      END;
    END IF; 
  END IF; 

  IF (v_stateConfigId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage := 'Missing State Config ID for Case # '||TO_CHAR(v_CaseId);   
    GOTO cleanup;
  END IF;
  
  --get Transition Id if exists
  v_TransitionId :=TO_NUMBER(f_FORM_getParamByName('<CustomData><Attributes>'||
                                                   v_Attributes||
                                                   '</Attributes></CustomData>', 
                                                   'TransitionId'));  
  --main query
  FOR rec IN
  (
    SELECT ste.COL_ID AS StateEventId, ste.COL_STATEEVENTSTATE AS StateId, 
           ste.COL_STATEEVENTEVENTMOMENT, ste.COL_STATEEVENTEVENTTYPE, ste.COL_EVENTORDER, 
           ste.COL_EVENTSUBTYPE, ste.COL_EVENTTYPE, ste.COL_PROCESSORCODE AS ProcessorName,
           st.COL_NAME, st.COL_CODE, st.COL_ACTIVITY, st.COL_STATESTATECONFIG,
           mmt.col_code AS momentCode,
           et.col_code AS evtTypeCode,
           CASE 
            WHEN LOWER(SUBSTR(ste.COL_PROCESSORCODE, 1, instr(ste.COL_PROCESSORCODE, '_', 1, 1))) = 'f_' then 1 
            ELSE 0 
           END AS IsFunction,
           ste.COL_STEVT_TRANS AS TransitionId
    FROM TBL_DICT_STATEEVENT ste
    INNER JOIN TBL_DICT_STATE st ON ste.COL_STATEEVENTSTATE=st.col_ID
    INNER JOIN TBL_DICT_TASKEVENTMOMENT mmt ON ste.COL_STATEEVENTEVENTMOMENT=mmt.COL_ID
    INNER JOIN TBL_DICT_TASKEVENTTYPE et ON ste.COL_STATEEVENTEVENTTYPE= et.COL_ID
    WHERE st.COL_STATESTATECONFIG= v_stateConfigId
          AND UPPER(st.COL_ACTIVITY)= UPPER(v_EventState)
          AND UPPER(mmt.col_code)=UPPER(v_EventMoment)
          AND UPPER(et.col_code)=UPPER(v_EventType)
    ORDER BY ste.COL_EVENTORDER ASC
  )
  LOOP
    IF rec.TransitionId NOT IN (v_TransitionId, 0) THEN CONTINUE; END IF;
    v_Params := NULL;
    IF NVL(rec.IsFunction,0) =0 THEN
      v_Params:= f_UTIL_getDataFromARPTmpl(ATTRIBUTES =>v_Attributes,
                                           CASEID=>v_CaseId,
                                           PARENTID=>rec.StateEventId, 
                                           TYPEOFQUERY=>'MILESTONE', 
                                           DATATYPEFORMAT=>'JSON');
      v_result := f_UTIL_addToQueueFn(RuleCode => rec.ProcessorName, Parameters => v_Params);
    END IF;

    IF NVL(rec.IsFunction,0) =1 THEN
      v_Params:= f_UTIL_getDataFromARPTmpl(ATTRIBUTES =>v_Attributes,
                                           CASEID=>v_CaseId,
                                           PARENTID=>rec.StateEventId, 
                                           TYPEOFQUERY=>'MILESTONE', 
                                           DATATYPEFORMAT=>'XML');
                                           
      --CALL PROCESSOR FUNCTION HERE AND GET RETURN VALUE 
      v_isValid := 1;
/*    deprecated , will be deleted later
  	  v_result := f_DCM_invokeMSEventProcessor(CASEID   =>v_CaseId, 
                                               INPUT    =>v_Params, 
                                               MESSAGE  =>v_errorMessage, 
                                               PROCESSORNAME    =>rec.ProcessorName, 
                                               STATEID          =>rec.StateId, 
                                               STEVENTID        =>rec.StateEventId, 
                                               VALIDATIONRESULT =>v_isValid);
*/                                               
      v_result := f_UTIL_genericProcInvokerFn(INDATA => NULL,
                                              OUTDATA =>v_outData,
                                              ERRORCODE => v_ErrorCode,
                                              ERRORMESSAGE => v_ErrorMessage,
                                              INPUT => v_Params,
                                              PROCESSORNAME => rec.ProcessorName,
                                              VALIDATIONRESULT => v_isValid);
      if v_isValid = 0 THEN
        v_errorCode := 102;
        EXIT;
      end if;
    END IF;
  END LOOP;
  
  IF v_isValid <> 1 THEN   GOTO cleanup; END IF;

  v_errorCode :=NULL;
  v_errorMessage :=NULL;

  :IsValid := v_isValid;
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
