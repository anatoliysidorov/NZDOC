  --start of rule
  DECLARE 
    v_InputXML         XMLTYPE;
    v_CaseSysTypeId    NUMBER;
    v_Input            CLOB;
    v_count            NUMBER;
    v_stateConfigId    NUMBER;
    v_path             NVARCHAR2(255);
    v_eventType        NVARCHAR2(255);

    --temp variables 
    v_Result        NUMBER;

    --errors variables
    v_errorCode     NUMBER;
    v_errorMessage  NVARCHAR2(255);

  BEGIN
    --init
    v_CaseSysTypeId := :CaseSysTypeId;
    v_Input         := :Input;

    v_InputXML          := NULL;
    v_count             := NULL;
    v_stateConfigId     := NULL;
    v_Result            := NULL;
    v_path              := NULL;
    v_eventType         := NULL;

    --check input data
    IF (v_CaseSysTypeId IS NULL) THEN
      v_errorCode :=101;
      v_errorMessage :='Case Type Id cannot be NULL';
      GOTO cleanup;
    END IF;
    
    --define if custom state machine is exists
    BEGIN
      SELECT  COUNT(1) INTO v_count
      FROM TBL_DICT_STATECONFIG
      WHERE COL_CASESYSTYPESTATECONFIG=v_CaseSysTypeId AND COL_ISCURRENT=1;
    END; 
   
    IF v_count=0 THEN
      v_errorCode :=101;
      v_errorMessage :='State Config record with Case Type Id '||TO_CHAR(v_CaseSysTypeId)||' not found.';
      GOTO cleanup;               
    END IF;

    IF v_count>1 THEN
      v_errorCode :=101;
      v_errorMessage :='State Config record is invalid for Case Type Id '||TO_CHAR(v_CaseSysTypeId);
      GOTO cleanup;               
    END IF;

    --work with existing record
    IF (v_count=1) AND (v_Input IS NOT NULL) THEN 
      --define an existing state config data
      BEGIN
        SELECT COL_ID INTO v_stateConfigId
        FROM TBL_DICT_STATECONFIG
        WHERE COL_CASESYSTYPESTATECONFIG=v_CaseSysTypeId AND COL_ISCURRENT=1;
      EXCEPTION WHEN NO_DATA_FOUND THEN
        v_errorCode := 102;
        v_errorMessage :='A State Config record not found';
        GOTO cleanup;
      WHEN TOO_MANY_ROWS THEN
        v_errorCode := 102;
        v_errorMessage :='Cant define a State Config record';
        GOTO cleanup;
      END; 
      
      --clean up a template data
      DELETE FROM TBL_AUTORULEPARAMTMPL
      WHERE COL_AUTORULEPARTPSLAACTIONTP IN
      (SELECT COL_ID FROM TBL_SLAACTIONTMPL 
      WHERE COL_SLAACTIONTPSLAEVENTTP IN 
      (SELECT COL_ID FROM TBL_SLAEVENTTMPL 
      WHERE COL_SLAEVENTTMPLDICT_CST =v_CaseSysTypeId));

      DELETE FROM TBL_SLAACTIONTMPL 
      WHERE COL_SLAACTIONTPSLAEVENTTP IN 
      (SELECT COL_ID FROM TBL_SLAEVENTTMPL 
      WHERE COL_SLAEVENTTMPLDICT_CST =v_CaseSysTypeId);

      DELETE FROM TBL_SLAEVENTTMPL 
      WHERE COL_SLAEVENTTMPLDICT_CST =v_CaseSysTypeId;


      v_InputXML := XMLTYPE(v_Input);
      -- process a new data
      --For each mxCell = eventConnection
      FOR rec IN
      (
       SELECT xmlD.NODEID, xmlD.SOURCE AS EVENTDID2, xmlD.TARGET AS STATEID2, st.COL_ID AS STATEID,
              --st.COL_STATECASESTATE AS SYSSTATEID,
              csdet.COL_CSEST_DTEVTPDATEEVENTTYPE AS DATEEVTTYPEID
              --det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName 
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
       INNER JOIN TBL_DICT_CSEST_DTEVTP csdet on st.COL_STATECASESTATE= csdet.COL_CSEST_DTEVTPCASESTATE
       INNER JOIN TBL_DICT_DATEEVENTTYPE DET on csdet.COL_CSEST_DTEVTPDATEEVENTTYPE = det.COL_ID
       WHERE UPPER(xmlD.NODETYPE)='EVENTCONNECTION' 
             AND NVL(det.COL_ISCASEMAINFLAG,0) = 1
      )
      LOOP
        v_eventType :=NULL;
        v_path :=NULL; 
    
        --define a type of event
        v_path := '//mxGraphModel/root/mxCell[@id='||TO_CHAR(rec.EVENTDID2)||']';
        v_eventType := f_UTIL_extract_value_xml(Input => v_InputXML, Path => v_path||'/@type');
            
        --create a SLA for Case event(s)
        IF (v_eventType IS NOT NULL) AND (UPPER(v_eventType)='SERVICE')  THEN           
          v_Result := f_STP_CreateSLACaseEvtTmpl(CASESYSTYPEID =>v_CaseSysTypeId, 
                                                 DATEEVTTYPEID =>rec.DATEEVTTYPEID, 
                                                 ERRORCODE    =>v_ErrorCode,      --output
                                                 ERRORMESSAGE =>v_ErrorMessage,   --output
                                                 INPUT        =>v_Input, 
                                                 PATH         =>v_path, 
                                                 STATEID      =>rec.STATEID,      --preserve for a future
                                                 SLAEVENTID2  =>rec.EVENTDID2,
                                                 STCONFIGID   =>v_stateConfigId); --preserve for a future
    
          IF NVL(v_errorCode,0)<>0 THEN GOTO cleanup; END IF;
        END IF;
      END LOOP;
    END IF;--work with existing record

    --exit block           
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

  END;--eof rule