DECLARE
 v_Input            CLOB;
 v_InputXML         XMLTYPE;  
 v_StateId          NUMBER;
 v_SlaStateId       NUMBER;
 v_stateConfigId    NUMBER;
  
 --calculated
 v_Result           INTEGER;
 v_eventObj         CLOB;
 v_eventSubType     NVARCHAR2(255);
 v_eventType        NVARCHAR2(255);
 v_processorCode    NVARCHAR2(255); 
 v_path             NVARCHAR2(255);
 v_executionMoment  NVARCHAR2(255);
 v_insertedSLAActionId  NUMBER;
 v_insertedStEvtId      NUMBER;
 v_eventOrder       INTEGER;
 v_typeOfEvt        NVARCHAR2(255);
 v_evtMomentId      NUMBER;
 v_evtTypeId        NUMBER;
 v_eventName        NVARCHAR2(255);
 v_eventCode        NVARCHAR2(255);
 v_eventNameDef     NVARCHAR2(255);
 v_eventCodeDef     NVARCHAR2(255);
 v_transitionCode   NVARCHAR2(255);
 v_transitionId     NUMBER; 
 
 --errors variables
 v_errorCode     NUMBER;
 v_errorMessage  NVARCHAR2(255);
 
BEGIN
  v_path          := :Path;
  v_StateId       := :StateId; 
  v_SlaStateId    := :SlaStateId;
  v_Input         := :Input;    
  v_InputXML      := XMLTYPE(:Input);
  v_stateConfigId := :StConfigId; ----preserve for future
  
  v_errorMessage  := NULL;
  v_errorCode     := NULL;
   
  v_insertedSLAActionId := NULL;
  v_insertedStEvtId     := NULL;
  v_executionMoment     := NULL;
  
  v_eventObj        :=NULL;    
  v_eventSubType    :=NULL;    
  v_eventType       :=NULL;    
  v_processorCode   :=NULL; 
  v_eventName       :=NULL;
  v_eventCode       :=NULL;
  v_eventNameDef    :=NULL;
  v_eventCodeDef    :=NULL;       
  v_eventOrder      :=0; 
  v_typeOfEvt       :=NULL;
  v_evtMomentId     :=NULL;
  v_evtTypeId       :=NULL;
  v_transitionCode  :=NULL;
  v_transitionId    :=NULL;  

  IF (v_StateId IS NULL) AND (v_SlaStateId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='Both State Id and SLA State Id is missing';
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
    v_eventName := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@eventName'); 
    v_eventCode := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@eventCode'); 
    v_transitionCode := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@transitionCode'); 
    v_eventOrder :=  TO_NUMBER(NVL(f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@SORDER'),0)); 
    
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
        SELECT COL_MSPROCESSORCODE, COL_CODE, COl_NAME  
        INTO v_processorCode, v_eventCodeDef,  v_eventNameDef
        FROM TBL_DICT_ACTIONTYPE WHERE UPPER(col_code) = UPPER(v_eventType);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        v_processorCode := null;
      END;
      IF v_processorCode IS NOT NULL THEN
        v_eventCode := NVL(v_eventCode, v_eventCodeDef);
        v_eventName := NVL(v_eventName, v_eventNameDef);
      END IF;
      IF v_processorCode IS NULL THEN
        IF (UPPER(v_eventType) IN ('RULE', 'VALIDATION_RULE')) AND UPPER(v_eventSubType)='RULE' THEN
          v_processorCode := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@rule_code');
          v_eventCode := NVL(v_eventCode, UPPER(v_processorCode));
          v_eventName := NVL(v_eventName, v_processorCode);
        END IF;
      END IF; --v_processorCode IS NULL
    END IF;--v_eventType IS NOT NULL
  END IF; --v_InputXML  

  --create state event 
  IF (v_SlaStateId IS NULL)  AND (v_StateId IS NOT NULL) THEN
    --EventOrder Calculation 
    IF NVL(v_eventOrder, 0)=0 THEN
      BEGIN
        SELECT NVL(MAX(COL_EVENTORDER),0)+1 INTO v_eventOrder
        FROM TBL_DICT_STATEEVENT 
        WHERE COL_STATEEVENTSTATE=v_StateId;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN v_eventOrder := 0;    
        WHEN OTHERS THEN v_eventOrder := 0; 
      END;
    END IF;
    
    --define a transition id if exists
    IF v_transitionCode IS NOT NULL THEN
      BEGIN
        SELECT COL_ID INTO v_transitionId
        FROM TBL_DICT_TRANSITION 
        WHERE COL_TARGETTRANSITIONSTATE=v_StateId AND COL_COMMONCODE=v_transitionCode;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN v_transitionId := NULL;    
        WHEN OTHERS THEN v_transitionId := NULL;       
      END;
    END IF;

    INSERT INTO TBL_DICT_STATEEVENT(COL_STATEEVENTSTATE, COL_STATEEVENTEVENTMOMENT, COL_STATEEVENTEVENTTYPE,
                                    COL_EVENTORDER, COL_EVENTSUBTYPE, COL_EVENTTYPE, COL_PROCESSORCODE,
                                    COL_EVENTCODE, COL_EVENTNAME, COL_UCODE, COL_STEVT_TRANS)
    VALUES (v_StateId, v_evtMomentId, v_evtTypeId,
            v_eventOrder, v_eventSubType, v_eventType, v_processorCode, 
            v_eventCode, v_eventName, SYS_GUID(), v_transitionId)
    RETURNING COl_ID INTO v_insertedStEvtId;
  END IF;

  --create SLA action  
  IF (v_SlaStateId IS NOT NULL)  AND (v_StateId IS NULL) THEN
    --EventOrder Calculation 
    BEGIN
      SELECT NVL(MAX(COL_SLAACTIONORDER),0)+1 INTO v_eventOrder
      FROM TBL_DICT_STATESLAACTION 
      WHERE COL_STATESLAACTNSTATESLAEVNT=v_SlaStateId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN v_eventOrder := 0;    
      WHEN OTHERS THEN v_eventOrder := 0; 
    END;
    INSERT INTO TBL_DICT_STATESLAACTION(COL_PROCESSORCODE, COL_SLAACTIONORDER,
                                        COL_STATESLAACTNSTATESLAEVNT, COL_EVENTCODE, COL_EVENTNAME, COL_UCODE)
    VALUES (v_processorCode, v_eventOrder, v_SlaStateId, v_eventCode, v_eventName, SYS_GUID())
    RETURNING COl_ID INTO v_insertedSLAActionId;
  END IF;

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
    v_Result := f_STP_CreateCaseCustomARP(ERRORCODE   => v_errorCode, 
                                          ERRORMESSAGE =>v_errorMessage, 
                                          INPUT        =>NULL, --preserve for future
                                          OBJECTSTATEEVENT =>v_eventObj, 
                                          STATECONFIG      =>v_stateConfigId, --preserve for future
                                          STATEEVENTID     =>v_insertedStEvtId,
                                          SLAACTIONID      =>v_insertedSLAActionId);
                                          
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