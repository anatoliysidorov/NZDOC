DECLARE
 v_Input            CLOB;
 v_InputXML         XMLTYPE;  
 v_StateId          NUMBER;
 v_SlaEventId2      NUMBER;
 v_stateConfigId    NUMBER;
  
 --calculated
 v_Result           INTEGER;
 v_eventObj         CLOB;
 v_eventSubType     NVARCHAR2(255);
 v_eventType        NVARCHAR2(255);
 v_path             NVARCHAR2(255);
 v_eventName        NVARCHAR2(255);
 v_eventCode        NVARCHAR2(255);
 v_StateSLAEventId  NUMBER;
 v_eventOrder       INTEGER;
  
  --SLA
  v_YEARS       NVARCHAR2(255);
  v_MONTHS      NVARCHAR2(255);
  v_DAYS        NVARCHAR2(255);
  v_HOURS       NVARCHAR2(255);
  v_MINUTES     NVARCHAR2(255);
  v_SECONDS     NVARCHAR2(255);
  v_WEEKS       NVARCHAR2(255);  
  v_intervalym  NVARCHAR2(255);
  v_intervalds  NVARCHAR2(255);
  
  v_serviceType     NVARCHAR2(255);
  v_serviceSubType  NVARCHAR2(255);

  v_transitionCode   NVARCHAR2(255);
  v_transitionId     NUMBER; 
  v_SLAEvtTypeId     NUMBER;  
 
  --errors variables  
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
 
BEGIN
  v_path          := :Path;
  v_StateId       := :StateId; 
  v_SlaEventId2   := :SlaEventId2;
  v_Input         := :Input;    
  v_InputXML      := XMLTYPE(:Input);
  v_stateConfigId := :StConfigId; ----preserve for future
  
  v_errorMessage  := NULL;
  v_errorCode     := NULL;
  
  v_StateSLAEventId  := NULL; 

  v_YEARS         :=NULL;
  v_MONTHS        :=NULL;
  v_DAYS          :=NULL;
  v_HOURS         :=NULL;
  v_MINUTES       :=NULL;
  v_SECONDS       :=NULL;
  v_WEEKS         :=NULL;  
  v_intervalym    := NULL;
  v_intervalds    := NULL;
  
  v_serviceType     := NULL;
  v_serviceSubType  := NULL;    
  v_eventName       := NULL;
  v_eventCode       := NULL;

  v_eventObj      :=NULL;    
  v_eventSubType  :=NULL;    
  v_eventType     :=NULL; 
  v_eventOrder    :=0; 
  v_SLAEvtTypeId    :=NULL;  

  v_transitionCode  :=NULL;
  v_transitionId    :=NULL;  

  IF (v_StateId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='State Id is missing';
    GOTO cleanup;
  END IF;

  IF (v_SlaEventId2 IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='SLA Event Id2 is missing';
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
    v_eventType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@serviceType');
    v_eventSubType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@subtype');
    v_eventName := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@serviceName'); 
    v_eventCode := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@serviceCode');
    v_transitionCode := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@transitionCode'); 

    IF v_eventType IS NOT NULL THEN
      v_YEARS   := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@YEARS');
      v_MONTHS  := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@MONTHS');
      v_DAYS    := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@DAYS');
      v_HOURS   := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@HOURS');
      v_MINUTES := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@MINUTES');
      v_SECONDS := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@SECONDS');
      v_WEEKS   := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@WEEKS');
      v_serviceType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@serviceType');
      v_serviceSubType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/Object/@subtype');

      v_Result := f_STP_processSLAPeriod(ERRORCODE    =>v_errorcode, 
                                         ERRORMESSAGE =>v_errormessage, 
                                         INTDS        =>v_intervalds, 
                                         INTYM        =>v_intervalym, 
                                         PDAYS        =>v_DAYS, 
                                         PHOURS       =>v_HOURS, 
                                         PMINUTES     =>v_MINUTES, 
                                         PMONTHS      =>v_MONTHS, 
                                         PSECONDS     =>v_SECONDS, 
                                         PWEEKS       =>v_WEEKS, 
                                         PYEARS       =>v_YEARS);
      IF NVL(v_errorCode,0)<>0 THEN GOTO cleanup; END IF;

      v_eventName :=NVL(v_eventName, v_eventType);
      v_eventCode := NVL(v_eventCode, 'SLA_'||UPPER(v_eventType));
      
      --EventOrder Calculation 
      BEGIN
        SELECT NVL(MAX(COL_SLAEVENTORDER),0)+1 INTO v_eventOrder
        FROM TBL_DICT_STATESLAEVENT 
        WHERE COL_STATESLAEVENTDICT_STATE=v_StateId;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN v_eventOrder := 0;    
        WHEN OTHERS THEN v_eventOrder := 0; 
      END;
      
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
      
      BEGIN
        SELECT COl_ID INTO v_SLAEvtTypeId
        FROM TBL_DICT_SLAEVENTTYPE
        WHERE UPPER(COL_CODE)=UPPER(v_eventType);
      EXCEPTION
          WHEN NO_DATA_FOUND THEN v_SLAEvtTypeId := NULL;
      END;      
      
      --create state SLA event
      INSERT INTO TBL_DICT_STATESLAEVENT(COL_UCODE, COL_INTERVALDS, COL_INTERVALYM, 
                                         COL_ATTEMPTCOUNT, COL_MAXATTEMPTS, 
                                         COL_STATESLAEVENTDICT_STATE, COL_SLAEVENTORDER,
                                         COL_STATESLAEVENTSLAEVENTLVL, COL_SERVICETYPE,
                                         COL_SERVICESUBTYPE, COL_EVENTCODE, COL_EVENTNAME, 
                                         COL_STSLAEVT_TRANS, COL_DICT_SSE_SLAEVENTTYPE)
      VALUES (SYS_GUID(), v_intervalds, v_intervalym,
              0,1, v_StateId, v_eventOrder,
              (SELECT COL_ID FROM TBL_DICT_SLAEVENTLEVEL WHERE COL_CODE = 'BLOCKER'),
              v_serviceType, v_serviceSubType, v_eventCode, v_eventName, v_transitionId, v_SLAEvtTypeId)
      RETURNING COl_ID INTO v_StateSLAEventId;

      --For each mxCell = eventConnection (SLA only)
      FOR rec IN
      (
       SELECT xmlD.NODEID, xmlD.SOURCE AS EVENTDID2, xmlD.TARGET AS SLAEvtID2
       FROM XMLTABLE( 
          '/mxGraphModel/root/mxCell'
          PASSING XMLTYPE.CREATEXML(v_Input) 
          COLUMNS
          NODEID    NUMBER          path '//@id',
          SOURCE    NUMBER          path '//@source',
          TARGET    NUMBER          path '//@target',      
          NODETYPE  VARCHAR2(255)   path '//@type'
    
       ) AS xmlD       
       WHERE UPPER(xmlD.NODETYPE)='EVENTCONNECTION' AND xmlD.TARGET=v_SlaEventId2               
       ORDER BY xmlD.TARGET ASC, xmlD.SOURCE ASC
      )
      LOOP        
        v_eventType :=NULL;
        v_path :=NULL; 
    
        --define a type of event
        v_path := '//mxGraphModel/root/mxCell[@id='||TO_CHAR(rec.EVENTDID2)||']';
        v_eventType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/@type');
                       
        --create a state event(s)
        IF (v_eventType IS NOT NULL) AND (UPPER(v_eventType) IN ('EVENT')) THEN
          v_Result := f_STP_CreateMSStateEvent(ERRORCODE    =>v_ErrorCode, 
                                               ERRORMESSAGE =>v_ErrorMessage, 
                                               INPUT        =>v_Input, 
                                               PATH         =>v_path, 
                                               STATEID      =>NULL,
                                               SLASTATEID   =>v_StateSLAEventId,
                                               STCONFIGID   =>v_stateConfigId);
    
          IF NVL(v_errorCode,0)<>0 THEN GOTO cleanup; END IF;
        END IF;
      END LOOP;--event(s) on SLA
    END IF; --v_eventType IS NOT NULL
  END IF; --v_InputXML  
            
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