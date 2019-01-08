DECLARE
 v_Input            CLOB;
 v_InputXML         XMLTYPE;  
 v_StateId          NUMBER;
 v_SlaStateId       NUMBER;
 
 v_stateConfigId    NUMBER;
 v_SLAEventId       NUMBER; 
 
 --calculated
 v_Result           INTEGER;
 v_eventObj         CLOB;
 v_eventSubType     NVARCHAR2(255);
 v_eventType        NVARCHAR2(255);
 v_processorCode    NVARCHAR2(255); 
 v_path             NVARCHAR2(255);
 v_executionMoment  NVARCHAR2(255);
 v_SLAActionId  NUMBER; 
 v_typeOfEvt        NVARCHAR2(255);
 v_evtMomentId      NUMBER;
 v_evtTypeId        NUMBER;
 
  --errors variables
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
 
BEGIN
  v_path          := :Path;
  v_SLAEventId    := :SLAEventId;

  v_Input         := :Input;    
  v_InputXML      := XMLTYPE(:Input);
  v_stateConfigId := :StConfigId; ----preserve for future
  
  v_errorMessage  := NULL;
  v_errorCode     := NULL;
   
  v_SLAActionId := NULL;  
  v_executionMoment     := NULL;
  
  v_eventObj        :=NULL;    
  v_eventSubType    :=NULL;    
  v_eventType       :=NULL;    
  v_processorCode   :=NULL;    
  
  v_typeOfEvt        :=NULL;
  v_evtMomentId      :=NULL;
  v_evtTypeId        :=NULL;

  IF v_SLAEventId IS NULL THEN
    v_errorCode :=101;
    v_errorMessage :='A SLA Event Id is missing';
    GOTO cleanup;
  END IF;

  IF (v_Input IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='Milestone data is missing';
    GOTO cleanup;
  END IF;

  IF (v_path IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A Path is missing';
    GOTO cleanup;
  END IF;
                
  IF  v_InputXML.EXISTSNODE(v_path||'/Object') = 1 THEN
    v_eventType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@eventType');
    v_eventSubType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@subtype');
    v_typeOfEvt := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/@type');    
    
    --a validation events will be always BEFORE/VALIDATION 
    IF (v_typeOfEvt IS NOT NULL)  AND (UPPER(v_typeOfEvt) IN ('VALIDATION_EVENT'))  THEN
      BEGIN
        SELECT COL_ID INTO v_evtMomentId FROM TBL_DICT_TASKEVENTMOMENT WHERE COL_CODE = 'BEFORE';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN v_evtMomentId :=NULL;
      END;
      BEGIN
        SELECT COL_ID INTO v_evtTypeId FROM TBL_DICT_TASKEVENTTYPE WHERE COL_CODE = 'VALIDATION';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN v_evtTypeId :=NULL;
      END;
    END IF;

    --calculate an events execution moment (events is only  ACTION)
    IF (v_typeOfEvt IS NOT NULL)  AND (UPPER(v_typeOfEvt) IN ('EVENT'))  THEN
      v_executionMoment:= f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@execution_moment');

      --by default
      v_executionMoment :=NVL(v_executionMoment, 'AFTER');

      BEGIN
        SELECT COL_ID INTO v_evtMomentId FROM TBL_DICT_TASKEVENTMOMENT WHERE COL_CODE = UPPER(v_executionMoment);
      EXCEPTION WHEN NO_DATA_FOUND THEN v_evtMomentId :=NULL;
      END;

      BEGIN
        SELECT COL_ID INTO v_evtTypeId FROM TBL_DICT_TASKEVENTTYPE WHERE COL_CODE = 'ACTION';
      EXCEPTION WHEN NO_DATA_FOUND THEN v_evtTypeId :=NULL;
      END;
    END IF;

    IF v_eventType IS NOT NULL THEN
      BEGIN
        SELECT COL_MSPROCESSORCODE INTO v_processorCode 
        FROM TBL_DICT_ACTIONTYPE WHERE UPPER(col_code) = UPPER(v_eventType);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        v_processorCode := null;
      END;
      IF v_processorCode IS NULL THEN
        IF (UPPER(v_eventType) IN ('RULE', 'VALIDATION_RULE')) AND UPPER(v_eventSubType)='RULE' THEN
          v_processorCode := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@rule_code');
        END IF;
      END IF; --v_processorCode IS NULL
    END IF;--v_eventType IS NOT NULL
  END IF; --v_InputXML  


  --create SLA action  
  INSERT INTO TBL_SLAACTIONTMPL(COL_CODE, COL_ACTIONORDER, COL_PROCESSORCODE, COL_SLAACTIONTPSLAEVENTTP, 
                                COL_SLAACTIONTP_SLAEVENTLEVEL)
  VALUES
  (SYS_GUID(),
   (SELECT NVL(MAX(COL_ACTIONORDER),0) + 1 FROM TBL_SLAACTIONTMPL WHERE COL_SLAACTIONTPSLAEVENTTP = v_SLAEventId),
   v_processorCode, v_SLAEventId,
   (SELECT COL_ID FROM TBL_DICT_SLAEVENTLEVEL WHERE COL_CODE = 'BLOCKER')
  )RETURNING COl_ID INTO v_SLAActionId;

  --create event rule parameters
  BEGIN 
   SELECT SUBSTR(v_InputXML.EXTRACT(v_path||'/Object').getStringval(), 1, 32767) 
   INTO v_eventObj
   FROM dual;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_eventObj :=NULL;
  END;
   
  IF v_eventObj IS NOT NULL THEN                      
    v_Result := f_STP_CreateSLACaseARPTmpl(ERRORCODE   => v_errorCode, 
                                           ERRORMESSAGE =>v_errorMessage, 
                                           INPUT        =>NULL, --preserve for future
                                           OBJECTSTATEEVENT =>v_eventObj, 
                                           STATECONFIG      =>v_stateConfigId, --preserve for future
                                           SLAACTIONID      =>v_SLAActionId);
                                          
    IF NVL(v_errorCode, 0)<>0 THEN GOTO cleanup; END IF;                                          
  END IF;
      
  v_errorCode :=NULL;
  v_errorMessage :=NULL;
  
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  RETURN 0;  

  --error block
  <<cleanup>>  
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;  
  RETURN -1; 

END;