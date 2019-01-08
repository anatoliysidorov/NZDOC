DECLARE
 v_Input            CLOB;
 v_InputXML         XMLTYPE;  
 v_StateId          NUMBER;
 v_SlaEventId2      NUMBER;
 v_stateConfigId    NUMBER;
 v_CaseSysTypeId    NUMBER;
 v_DateEvtTypeId    NUMBER;
  
 --calculated
 v_Result           INTEGER;
 v_eventObj         CLOB;
 v_eventSubType     NVARCHAR2(255);
 v_eventType        NVARCHAR2(255);
 v_path             NVARCHAR2(255);
 v_SLAEventId       NUMBER;
  
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
 
  --errors variables  
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
 
BEGIN
  v_CaseSysTypeId := :CaseSysTypeId;
  v_DateEvtTypeId := :DateEvtTypeId; 
  v_path          := :Path;
  v_StateId       := :StateId;       --preserve for a future
  v_SlaEventId2   := :SlaEventId2;
  v_Input         := :Input;    
  v_InputXML      := XMLTYPE(:Input);
  v_stateConfigId := :StConfigId; --preserve for a future
  
  v_errorMessage  := NULL;
  v_errorCode     := NULL;
  
  v_SLAEventId  := NULL; 

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
    
  v_eventObj      :=NULL;    
  v_eventSubType  :=NULL;    
  v_eventType     :=NULL;          

  IF (v_CaseSysTypeId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A Case Type Id is missing';
    GOTO cleanup;
  END IF;

  IF (v_DateEvtTypeId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A Date Event Type Id is missing';
    GOTO cleanup;
  END IF;

  IF (v_SlaEventId2 IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A SLA Event Id2 is missing';
    GOTO cleanup;
  END IF;

  IF (v_Input IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A XML data is missing';
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

      --create SLA event
      INSERT INTO TBL_SLAEVENTTMPL(COL_ATTEMPTCOUNT, COL_MAXATTEMPTS, COL_ID2,COL_INTERVALDS, COL_INTERVALYM,
                                   COL_SLAEVENTORDER, COL_SLAEVENTTP_DATEEVENTTYPE,COL_SLAEVENTTP_SLAEVENTLEVEL,
                                   COL_SLAEVENTTP_SLAEVENTTYPE, COL_SLAEVENTTMPLDICT_CST, COL_CODE)
      VALUES(0,1, v_SlaEventId2, v_intervalds, v_intervalym,
            (SELECT NVL(MAX(COL_SLAEVENTORDER),0) + 1 FROM TBL_SLAEVENTTMPL WHERE COL_SLAEVENTTMPLDICT_CST = v_CaseSysTypeId),
            v_DateEvtTypeId,
            (SELECT COL_ID FROM TBL_DICT_SLAEVENTLEVEL WHERE COL_CODE = 'BLOCKER'),
            (SELECT COL_ID FROM TBL_DICT_SLAEVENTTYPE WHERE LOWER(COL_CODE) = LOWER(v_eventSubType)),
            v_CaseSysTypeId, SYS_GUID()) RETURNING COl_ID INTO v_SLAEventId;

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
      )
      LOOP        
        v_eventType :=NULL;
        v_path :=NULL; 
    
        --define a type of event
        v_path := '//mxGraphModel/root/mxCell[@id='||TO_CHAR(rec.EVENTDID2)||']';
        v_eventType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/@type');
                       
        --create a SLA actions
        IF (v_eventType IS NOT NULL) AND (UPPER(v_eventType) IN ('EVENT')) THEN
          v_Result := f_STP_CreateSLACaseActTmpl(ERRORCODE    =>v_ErrorCode,    --output
                                                 ERRORMESSAGE =>v_ErrorMessage, --output
                                                 INPUT        =>v_Input, 
                                                 PATH         =>v_path,                                                
                                                 SLAEVENTID   =>v_SLAEventId,
                                                 STCONFIGID   =>v_stateConfigId); --preserve for a future
    
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