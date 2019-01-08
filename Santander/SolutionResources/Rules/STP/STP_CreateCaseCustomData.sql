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
 v_transition       VARCHAR2(255);
 v_CaseStateId      NUMBER; 
 v_eventObj         CLOB;
 v_eventSubType     NVARCHAR2(255);
 v_eventType        NVARCHAR2(255);
 v_processorCode    NVARCHAR2(255); 
 v_path             NVARCHAR2(255);
 v_CreationMode     NVARCHAR2(255);
 v_eventOrder       INTEGER;
 v_isValidationRule INTEGER;
 v_evtMomentId      NUMBER;
 v_evtTypeId        NUMBER; 
 v_countTmp         NUMBER;

 --errors variables
 v_errorCode     NUMBER;
 v_errorMessage  NVARCHAR2(255);
 v_tempErrMsg    NCLOB; 
 v_tempErrCd     INTEGER;  
 
begin
  v_Input         := :Input;  
  v_stateConfigId := :STATECONFIG; 
  v_CreationMode  := NVL(:CreationMode, 'SINGLE_VER'); --STRONG MUST BE IN 'SINGLE_VER' or 'MULTIPLE_VER'

  v_InputXML      := XMLTYPE(Input);   
  v_errorMessage  := NULL;
  v_errorCode     := NULL;

  v_calccode      := NULL;
  v_activity      := NULL;
  v_stateConfigCode := NULL;
  v_stateConfigName := NULL;
  v_transition      := NULL;
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
  v_countTmp         :=NULL;

       
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

  IF (v_Input IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='Milestone data is missing';
    GOTO cleanup;
  END IF;

  BEGIN 
    SELECT UPPER(col_code), col_Name
    INTO v_stateConfigCode, v_stateConfigName
    FROM tbl_DICT_StateConfig
    WHERE col_id = v_stateConfigId;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errorCode      := 101;
    v_errorMessage   := 'Data from State Config is missing';
    GOTO cleanup;
  END;
     
  --For each mxCell = milestone
  FOR rec IN
  (
   SELECT NODEID, NODETYPE, CODE, NAME, DESCRIPTION, SYSTEMCODE
   FROM XMLTABLE('/mxGraphModel/root/mxCell'
      PASSING XMLTYPE.CREATEXML(v_Input) 
      COLUMNS
      NODEID              NUMBER         path '//@id',
      NODETYPE            VARCHAR2(255)  path '//@type',          
      NAME                VARCHAR2(255)  path '//Object/@NAME',
      CODE                VARCHAR2(255)  path '//Object/@CODE',
      SYSTEMCODE          VARCHAR2(255)  path '//Object/@SYSTEMCODE',
      DESCRIPTION         VARCHAR2(255)  path '//Object/@DESCRIPTION'
   ) WHERE UPPER(NODETYPE)='MILESTONE'
  )
  LOOP     

    -- Unique Case State Code 
    v_calccode := v_stateConfigCode || '_' || rec.CODE; 
     
    --Case State Config
    v_activity := 'root_CS_STATUS_' || v_calccode;
    
    --calculate a system case state id
    v_CaseStateId := NULL;
    v_StateId     := NULL;
    
    BEGIN
      SELECT COL_ID INTO v_CaseStateId  
      FROM TBL_DICT_CASESTATE 
      WHERE UPPER(COL_CODE)=UPPER(rec.SYSTEMCODE);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_CaseStateId :=NULL;
      v_errorCode :=102;
      v_errorMessage :='Cant found a System State value for Custom State Value "'||rec.CODE||'"';
      GOTO cleanup;
    END;

    IF v_CreationMode = 'SINGLE_VER' THEN

      v_countTmp :=NULL;

      SELECT COUNT(1) INTO v_countTmp
      FROM TBL_DICT_STATE
      WHERE LOWER(COL_COMMONCODE)=LOWER(rec.CODE) AND 
            COL_STATESTATECONFIG=v_stateConfigId;

      IF v_countTmp NOT IN (0, 1) THEN         
        v_errorCode :=102;
        v_errorMessage :='A System State is invalid or not found. Code is: "'||rec.CODE||'"';
        GOTO cleanup;
      END IF;
  
      --insert a data
      IF  v_countTmp=0 THEN      
        INSERT INTO TBL_DICT_STATE(COL_ID2, COL_STATESTATECONFIG, COL_NAME, COL_UCODE, 
                                   COL_DESCRIPTION ,COL_CODE, COL_ACTIVITY, COL_STATECASESTATE, COL_COMMONCODE)
        VALUES(rec.NODEID, v_stateConfigId,  rec.NAME,  SYS_GUID(),  
               rec.DESCRIPTION, v_calccode, v_activity, v_CaseStateId, rec.CODE); 
      END IF;
      
      --update a data
      IF  v_countTmp=1 THEN      
      
        BEGIN
          SELECT COl_ID INTO v_StateId
          FROM TBL_DICT_STATE
          WHERE LOWER(COL_COMMONCODE)=LOWER(rec.CODE) AND 
                COL_STATESTATECONFIG=v_stateConfigId;
        EXCEPTION WHEN NO_DATA_FOUND THEN v_StateId:=NULL;
        END; 
        
        UPDATE TBL_DICT_STATE
        SET COL_ID2 =rec.NODEID, 
            COL_NAME=rec.NAME, 
            COL_DESCRIPTION=rec.DESCRIPTION 
        WHERE COL_ID=v_StateId;  
      
        --delete old data
        v_Result := f_STP_DelMSStateData(STATEID =>v_StateId, DELSTATERECORD=>NULL);               
      END IF; --v_countTmp=1
    END IF;--'SINGLE_VER'
        
    IF v_CreationMode = 'MULTIPLE_VER' THEN
      --insert a data
      INSERT INTO TBL_DICT_STATE(COL_ID2, COL_STATESTATECONFIG, COL_NAME, COL_UCODE, 
                                 COL_DESCRIPTION ,COL_CODE, COL_ACTIVITY, COL_STATECASESTATE, COL_COMMONCODE)
      VALUES(rec.NODEID, v_stateConfigId,  rec.NAME,  SYS_GUID(),  
             rec.DESCRIPTION, v_calccode, v_activity, v_CaseStateId, rec.CODE);          
    END IF; --'MULTIPLE_VER'
  END LOOP;

  --delete all states what not exists in the XML
  IF v_CreationMode = 'SINGLE_VER' THEN
    FOR rec IN
    (SELECT COL_ID AS StateId, COL_COMMONCODE AS CommonCode
     FROM TBL_DICT_STATE
     WHERE COL_STATESTATECONFIG=v_stateConfigId)
    LOOP
      v_countTmp :=NULL;  
      SELECT COUNT(1) INTO v_countTmp
      FROM XMLTABLE('/mxGraphModel/root/mxCell'
        PASSING XMLTYPE.CREATEXML(v_Input) 
        COLUMNS
        NODEID              NUMBER         path '//@id',
        NODETYPE            VARCHAR2(255)  path '//@type',                  
        CODE                VARCHAR2(255)  path '//Object/@CODE'
      ) WHERE UPPER(NODETYPE)='MILESTONE' AND rec.CommonCode=CODE;
      
      IF v_countTmp=0 THEN
        --delete old data
        v_Result := f_STP_DelMSStateData(STATEID =>rec.StateId, DELSTATERECORD=>'YES');
      END IF;--v_countTmp=0
    END LOOP;
  END IF;--delete all states...
     
     
  --For each mxCell = connection
  FOR rec IN
  (
   SELECT NODEID, NODETYPE,  NAME, CODE, DESCRIPTION,  SOURCE, TARGET, 
          NULL AS SOURCESTATEID, NULL AS TARGETSTATEID, NULL AS STATENAMESOURCE, 
          NULL AS STATENAMETARGET, COLORCODE, ICONCODE, SORDER, NOTSHOWINUI

   FROM XMLTABLE('/mxGraphModel/root/mxCell'
      PASSING XMLTYPE.CREATEXML(v_Input)
      COLUMNS
      NODEID       NUMBER         path '//@id',
      NODETYPE     VARCHAR2(255)  path '//@type',
      SOURCE       NUMBER         path '//@source',
      TARGET       NUMBER         path '//@target',
      NAME         VARCHAR2(255)  path '//Object/@NAME',
      CODE         VARCHAR2(255)  path '//Object/@CODE',          
      DESCRIPTION  VARCHAR2(255)  path '//Object/@DESCRIPTION',
      COLORCODE    VARCHAR2(255)  path '//Object/@COLORCODE',
      ICONCODE     VARCHAR2(255)  path '//Object/@ICONCODE',
      SORDER       NUMBER         path '//Object/@SORDER',
      NOTSHOWINUI  NUMBER         path '//Object/@NOTSHOWINUI'
   ) WHERE UPPER(NODETYPE)='CONNECTION'
  )
  LOOP

    BEGIN
      SELECT COL_ID, COL_NAME INTO rec.SOURCESTATEID, rec.STATENAMESOURCE
      FROM TBL_DICT_STATE
      WHERE COL_STATESTATECONFIG=v_stateConfigId AND COL_ID2=rec.SOURCE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      rec.SOURCESTATEID :=NULL;
    WHEN TOO_MANY_ROWS THEN
      rec.SOURCESTATEID :=NULL;
    END;

    BEGIN
      SELECT COL_ID, COL_NAME INTO rec.TARGETSTATEID, rec.STATENAMETARGET
      FROM TBL_DICT_STATE
      WHERE COL_STATESTATECONFIG=v_stateConfigId AND COL_ID2=rec.TARGET;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      rec.TARGETSTATEID :=NULL;
    WHEN TOO_MANY_ROWS THEN
      rec.TARGETSTATEID :=NULL;
    END;

    IF (rec.SOURCESTATEID IS NULL) OR (rec.TARGETSTATEID IS NULL) THEN
      v_errorCode :=103;
      v_errorMessage :='Case Transition doesnt have source or target.';
      GOTO cleanup;
    END IF;

    v_countTmp :=NULL;
    IF (rec.SOURCESTATEID IS NOT NULL) AND (rec.TARGETSTATEID IS NOT NULL) THEN
      SELECT COUNT(1) INTO v_countTmp
      FROM TBL_DICT_TRANSITION t
      LEFT OUTER JOIN TBL_DICT_STATE st ON t.COL_SOURCETRANSITIONSTATE=st.COL_ID
      LEFT OUTER JOIN TBL_DICT_STATE tt ON t.COL_TARGETTRANSITIONSTATE=tt.COL_ID
      WHERE st.COL_STATESTATECONFIG = v_stateConfigId AND
            tt.COL_STATESTATECONFIG = v_stateConfigId AND
            t.COL_SOURCETRANSITIONSTATE = rec.SOURCESTATEID AND
            t.COL_TARGETTRANSITIONSTATE = rec.TARGETSTATEID;

      IF NVL(v_countTmp,0)<>0 THEN
        v_countTmp :=NULL;

        SELECT COUNT(1) INTO v_countTmp         
        FROM TBL_DICT_TRANSITION T
        WHERE t.COL_CODE=rec.CODE;

        IF NVL(v_countTmp,0)<>0 THEN
          v_errorCode :=103;
          v_errorMessage :='Case Transition "'||rec.NAME||'" (Code is: "'||rec.CODE||'"; Transition from "'||
                           rec.STATENAMESOURCE||'" to "'||rec.STATENAMETARGET||'") already exists.';
          GOTO cleanup;
        END IF;
      END IF;
    END IF;

    v_calccode := v_stateConfigCode || '_' || rec.CODE;
    v_transition := 'root_CS_STATUS_' || v_calccode;       

    INSERT INTO TBL_DICT_TRANSITION(COL_DESCRIPTION, COL_COMMONCODE, COL_UCODE, COL_TRANSITION, COL_NAME,
                                    COL_CODE, COL_SOURCETRANSITIONSTATE, COL_TARGETTRANSITIONSTATE, COL_ICONCODE, COL_COLORCODE, COL_SORDER, COL_NOTSHOWINUI)
    VALUES(rec.DESCRIPTION, rec.CODE, SYS_GUID(), v_transition, rec.NAME,
           v_calccode, rec.SOURCESTATEID, rec.TARGETSTATEID, rec.ICONCODE, rec.COLORCODE, rec.SORDER, rec.NOTSHOWINUI);

  END LOOP;
  
  
  --For each mxCell = eventConnection
  FOR rec IN
  (
   SELECT xmlD.NODEID, xmlD.SOURCE AS EVENTDID2, xmlD.TARGET AS STATEID2, st.COL_ID AS STATEID 
   FROM XMLTABLE( 
      '/mxGraphModel/root/mxCell'
      PASSING XMLTYPE.CREATEXML(v_Input) 
      COLUMNS
      NODEID    NUMBER          path '//@id',
      SOURCE    NUMBER          path '//@source',
      TARGET    NUMBER          path '//@target',      
      NODETYPE  VARCHAR2(255)   path '//@type'

   ) AS xmlD
   INNER JOIN TBL_DICT_STATE st ON st.COL_ID2=xmlD.TARGET AND st.COL_STATESTATECONFIG=v_stateConfigId
   WHERE UPPER(xmlD.NODETYPE)='EVENTCONNECTION'
   ORDER BY xmlD.TARGET ASC, xmlD.SOURCE ASC
  )
  LOOP
    v_eventType :=NULL;
    v_path :=NULL; 

    --define a type of event
    v_path := '//mxGraphModel/root/mxCell[@id='||TO_CHAR(rec.EVENTDID2)||']';
    v_eventType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/@type');
    
    --create a state event(s)
    IF (v_eventType IS NOT NULL) AND (UPPER(v_eventType) IN ('EVENT', 'VALIDATION_EVENT')) THEN      
      v_Result := f_STP_CreateMSStateEvent(ERRORCODE    =>v_ErrorCode, 
                                           ERRORMESSAGE =>v_ErrorMessage, 
                                           INPUT        =>v_Input, 
                                           PATH         =>v_path, 
                                           STATEID      =>rec.STATEID,
                                           SLASTATEID   =>NULL,
                                           STCONFIGID   =>v_stateConfigId);

      IF NVL(v_errorCode,0)<>0 THEN GOTO cleanup; END IF;
    END IF;

    --create a state SLA event(s)
    IF (v_eventType IS NOT NULL) AND (UPPER(v_eventType)='SERVICE')  THEN           
      v_Result := f_STP_CreateMSStateEventSLA(ERRORCODE    =>v_ErrorCode, 
                                              ERRORMESSAGE =>v_ErrorMessage, 
                                              INPUT        =>v_Input, 
                                              PATH         =>v_path, 
                                              STATEID      =>rec.STATEID,
                                              SLAEVENTID2  =>rec.EVENTDID2,
                                              STCONFIGID   =>v_stateConfigId);

      IF NVL(v_errorCode,0)<>0 THEN GOTO cleanup; END IF;
    END IF;
  END LOOP;

      
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