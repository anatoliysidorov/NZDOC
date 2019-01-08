DECLARE
 v_Input            CLOB;
 v_InputXML         XMLTYPE;
 v_stateConfigId    NUMBER;  
 v_StateId          NUMBER;
  
 --calculated
 v_Result           INTEGER;
 v_calccode         VARCHAR2(255);
 v_activity         VARCHAR2(255); 
 v_stateConfigCode  VARCHAR2(255);
 v_stateConfigName  VARCHAR2(255);
 v_defStateConfigId  VARCHAR2(255);
 v_defStateCodeS     VARCHAR2(255);
 v_defStateCodeT     VARCHAR2(255);

 v_CaseStateId      NUMBER; 
 v_eventObj         CLOB;
 v_eventSubType     NVARCHAR2(255);
 v_eventType        NVARCHAR2(255);
 v_processorCode    NVARCHAR2(255); 
 v_path             NVARCHAR2(255);
 v_eventOrder       INTEGER;
 v_isValidationRule INTEGER;
 v_evtMomentId      NUMBER;
 v_evtTypeId        NUMBER; 
 v_isFinish         NUMBER;
 v_tmpNum           NUMBER;

 --errors variables
 v_errorCode     NUMBER;
 v_errorMessage  NVARCHAR2(4000);

 
begin
  v_Input         := :Input;  
  v_stateConfigId := :STATECONFIG;--preserve for a future 

  v_InputXML      := XMLTYPE(Input); 
  
  v_errorMessage  := NULL;
  v_errorCode     := NULL;

  v_calccode      := NULL;
  v_activity      := NULL;
  v_stateConfigCode := NULL;
  v_stateConfigName := NULL;  
  v_CaseStateId     := NULL;
    
  v_StateId         := NULL;  
  v_eventObj        :=NULL;    
  v_eventSubType    :=NULL;    
  v_eventType       :=NULL;    
  v_processorCode   :=NULL; 
  v_path            :=NULL;
  v_eventOrder      :=0; 
  v_isValidationRule :=NULL;
  v_evtMomentId      :=NULL;
  v_evtTypeId        :=NULL;  

  v_defStateConfigId :=NULL;  

/*       
  -- validation if record is not exist
  IF NVL(v_stateConfigId, 0) > 0 THEN
    v_Result := f_UTIL_getId(errorcode    => v_errorCode,
           errormessage => v_errorMessage,
           id           => v_stateConfigId,
           tablename    => 'tbl_DICT_StateConfig');
    IF ErrorCode > 0 THEN
     GOTO cleanup;
    END IF;
  END IF;
*/
  
  IF (v_Input IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='<br>Milestone data is missing';
    GOTO cleanup;
  END IF;

/*  
  BEGIN 
    SELECT UPPER(col_code), col_Name
    INTO v_stateConfigCode, v_stateConfigName
    FROM tbl_DICT_StateConfig
    WHERE col_id = v_stateConfigId;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errorCode      := 101;
    v_errorMessage   := '<br>Data from State Config is missing';
    GOTO cleanup;
  END;
*/     
  --For each mxCell = milestone
  FOR rec IN
  (
   SELECT xmlM.NODEID, xmlM.NODETYPE, xmlM.CODE, xmlM.NAME, xmlM.SYSTEMCODE,
          cs.COL_ISSTART AS ISSTART, cs.COL_ISRESOLVE AS ISRESOLVE, cs.COL_ISFIX AS ISFIX,
          cs.COL_ISFINISH AS ISFINISH, cs.COL_ISASSIGN AS ISASSIGN
   FROM XMLTABLE('/mxGraphModel/root/mxCell'
      PASSING XMLTYPE.CREATEXML(v_Input) 
      COLUMNS
      NODEID              NUMBER         path '//@id',
      NODETYPE            VARCHAR2(255)  path '//@type',          
      NAME                VARCHAR2(255)  path '//Object/@NAME',
      CODE                VARCHAR2(255)  path '//Object/@CODE',
      SYSTEMCODE          VARCHAR2(255)  path '//Object/@SYSTEMCODE'
   ) AS xmlM
   LEFT JOIN TBL_DICT_CASESTATE cs ON xmlM.SYSTEMCODE=cs.COL_CODE
   WHERE UPPER(NODETYPE)='MILESTONE'
  )
  LOOP     

    -- Unique Case State Code 
    v_calccode := v_stateConfigCode || '_' || rec.CODE; 
     
    --Case State Config
    v_activity := 'root_CS_STATUS_' || v_calccode;
    
    --calculate a system case state id
    v_CaseStateId :=NULL;
    
    BEGIN
      SELECT COL_ID INTO v_CaseStateId  
      FROM TBL_DICT_CASESTATE 
      WHERE UPPER(COL_CODE)=UPPER(rec.SYSTEMCODE);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_CaseStateId :=NULL;
      v_errorCode :=102;
      v_errorMessage :='<br>Cant found a System State value for Custom State Value "'||rec.CODE||'"';
      GOTO cleanup;
    END;

    --validate section
    --
    --Only event(s) allowed on the Closed state
    --DCM-5079            
    IF NVL(rec.ISFINISH,0)=1 THEN
      --For each mxCell = eventConnection
      FOR rec2 IN
      (
       SELECT xmlD.NODEID, xmlD.SOURCE AS EVENTDID2, xmlD.TARGET AS STATEID2--, st.COL_ID AS STATEID 
       FROM XMLTABLE( 
          '/mxGraphModel/root/mxCell'
          PASSING XMLTYPE.CREATEXML(v_Input) 
          COLUMNS
          NODEID    NUMBER          path '//@id',
          SOURCE    NUMBER          path '//@source',
          TARGET    NUMBER          path '//@target',      
          NODETYPE  VARCHAR2(255)   path '//@type'
    
       ) AS xmlD
       --INNER JOIN TBL_DICT_STATE st ON st.COL_ID2=xmlD.TARGET AND st.COL_STATESTATECONFIG=v_stateConfigId
       WHERE UPPER(xmlD.NODETYPE)='EVENTCONNECTION' AND xmlD.TARGET=rec.NODEID
      )
      LOOP
        v_eventType :=NULL;
        v_path :=NULL; 
    
        --define a type of event
        v_path := '//mxGraphModel/root/mxCell[@id='||TO_CHAR(rec2.EVENTDID2)||']';
        v_eventType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/@type');
                        
        IF (v_eventType IS NOT NULL) AND (UPPER(v_eventType)='SERVICE')  THEN           
          v_errorCode :=102;
          v_errorMessage :=v_errorMessage||'<br> A State "'||rec.NAME||'" has a link with SLA Event. This is not allowed.';
        END IF;
      END LOOP;--eof For each mxCell = eventConnection
    END IF;--NVL(rec.ISFINISH,0)=1
  END LOOP; -- eof For each mxCell = milestone


  --validate a custom state machine with system state
  --DCM-5312
  BEGIN
    SELECT COl_ID INTO v_defStateConfigId
    FROM TBL_DICT_STATECONFIG
    WHERE COL_ISDEFAULT=1 AND COL_ISCURRENT=1 AND UPPER(COL_TYPE)='CASE';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN      
      v_errorCode :=102;
      v_errorMessage :='<br>Cant found a System State Configuration';
      GOTO cleanup;
  END;

  --For each mxCell = connection 
  FOR rec IN
  (
   SELECT NODEID, NODETYPE,  NAME, CODE, SOURCE, TARGET
   FROM XMLTABLE( 
      '/mxGraphModel/root/mxCell'
      PASSING XMLTYPE.CREATEXML(v_Input) 
      COLUMNS
      NODEID         NUMBER         path '//@id',
      SOURCE         NUMBER         path '//@source',
      TARGET         NUMBER         path '//@target',      
      NODETYPE       VARCHAR2(255)  path '//@type',      
      NAME           VARCHAR2(255)  path '//Object/@NAME',
      CODE           VARCHAR2(255)  path '//Object/@CODE'
   ) WHERE UPPER(NODETYPE)='CONNECTION'
  )
  LOOP
    v_defStateCodeS :=NULL;
    v_defStateCodeT :=NULL;
    v_path          :=NULL; 
    v_tmpNum        := NULL;

    --define a sys source and target
    v_path := '//mxGraphModel/root/mxCell[@id='||TO_CHAR(rec.SOURCE)||']/Object';
    v_defStateCodeS := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/@SYSTEMCODE');

    v_path := '//mxGraphModel/root/mxCell[@id='||TO_CHAR(rec.TARGET)||']/Object';
    v_defStateCodeT := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/@SYSTEMCODE');
    
    IF v_defStateCodeS IS NULL THEN
      v_errorCode :=102;
      v_errorMessage :='<br>Invalid XML Configuration for Transition "'||rec.Name||'". Code ('||rec.CODE||')'||
                       '<br>Cant found a Source System State';
      GOTO cleanup;
    END IF;

    IF v_defStateCodeT IS NULL THEN
      v_errorCode :=102;
      v_errorMessage :='<br>Invalid XML Configuration for Transition "'||rec.Name||'". Code ('||rec.CODE||')'||
                       '<br>Cant found a Target System State';
      GOTO cleanup;
    END IF;

    --define a system transitions
    SELECT COUNT(1) INTO v_tmpNum 
    FROM TBL_DICT_CASETRANSITION t 
    LEFT OUTER JOIN TBL_DICT_CASESTATE st ON t.COL_SOURCECASETRANSCASESTATE=st.Col_ID
    LEFT OUTER JOIN TBL_DICT_CASESTATE tt ON t.COL_TARGETCASETRANSCASESTATE=tt.Col_ID  
    WHERE st.COL_STATECONFIGCASESTATE = v_defStateConfigId AND
          tt.COL_STATECONFIGCASESTATE = v_defStateConfigId AND
          st.COL_CODE = v_defStateCodeS AND
          tt.COL_CODE = v_defStateCodeT;
    
    IF v_tmpNum =0 THEN
      v_errorCode :=102;
      v_errorMessage :='<br>Transition "'||rec.Name||'", Code ('||rec.CODE||') is not allowed by System State Configuration.'||
                       '<br>Please contact your System Administrator.';
      GOTO cleanup;
    END IF;
  END LOOP; --eof For each mxCell = connection

  IF NVL(v_errorCode,0)<>0 THEN GOTO cleanup; END IF;
      
  v_errorCode :=NULL;
  v_errorMessage :=NULL;

  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  RETURN 0;  

  --error block
  <<cleanup>>
  :ErrorCode := v_errorCode;
  :ErrorMessage := 'A model is not valid. Error(s):'||v_errorMessage;
  RETURN -1;

END;