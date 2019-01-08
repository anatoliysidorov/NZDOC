DECLARE
  v_mxCell        CLOB;
  v_input         XMLTYPE;
  v_stateConfigId NUMBER;
  v_StateEventId  NUMBER;
  v_SLAActionId   NUMBER;

  --calculated
  v_Result        INTEGER;
  v_XMLParameters NCLOB;
  v_path          NVARCHAR2(255);
  v_caseTypeId    NUMBER;

  --change case state parsing
  v_collectionCaseType      NCLOB;
  v_collectionCaseState     NCLOB;
  v_collectionResCode       NCLOB;
  v_caseTypeData            NVARCHAR2(255);
  v_collectionCaseTypeFound INTEGER;

  v_paramname  NCLOB;
  v_paramname1 NCLOB;
  v_paramvalue NCLOB;
  v_subtype    NVARCHAR2(255);
  v_eventtype  NVARCHAR2(255);

  v_tmpStr NVARCHAR2(255);

  --errors variables
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
  v_tempErrMsg   NCLOB;
  v_tempErrCd    INTEGER;

BEGIN
  v_mxCell        := :Input;
  v_stateConfigId := :STATECONFIG;
  v_StateEventId  := :STATEEVENTID;
  v_SLAActionId   := :SLAACTIONID;
  v_XMLParameters := :OBJECTSTATEEVENT;

  v_caseTypeId   := NULL;
  v_errorMessage := NULL;
  v_errorCode    := NULL;

  -- validation  
  IF (v_XMLParameters IS NULL) THEN
    v_errorCode    := 101;
    v_errorMessage := 'Milestone data is missing';
    GOTO cleanup;
  END IF;

  IF (v_StateEventId IS NULL) AND (v_SLAActionId IS NULL) THEN
    v_errorCode    := 101;
    v_errorMessage := 'Both State Event Id and SLA Action Id cannot be NULL';
    GOTO cleanup;
  END IF;

  --preserve a compatibility with old sql code  
  IF v_mxCell IS NULL THEN
    v_mxCell := '<mxGraphModel><root><mxCell>' || v_XMLParameters || '</mxCell></root></mxGraphModel>';
  END IF;

  v_Input := XMLTYPE(v_mxCell);

  --"change case state" parsing
  v_collectionCaseType      := NULL;
  v_collectionCaseState     := NULL;
  v_collectionResCode       := NULL;
  v_eventType               := NULL;
  v_subType                 := NULL;
  v_collectionCaseTypeFound := NULL;
  v_eventType               := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell/Object/@eventType');
  v_subType                 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell/Object/@subtype');

  IF UPPER(v_eventType) = 'CHANGECASESTATE' AND UPPER(v_subType) = 'CHANGECASESTATE' THEN
    v_subType := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell/Object/Object/@as');
    IF UPPER(v_subType) = 'CASETYPES' THEN
      --get Object
      v_path := '/mxGraphModel/root/mxCell/Object/Object';
      IF v_input.EXISTSNODE(v_path) = 1 THEN
        v_paramname1 := SUBSTR(v_input.extract(v_path).getStringval(), 1, 32767);
        IF v_paramname1 IS NOT NULL THEN
          FOR recXML IN (SELECT dbms_lob.SUBSTR(substr1, 4000, 1) AS substr2
                           FROM (SELECT REGEXP_SUBSTR(str1, '\w+=\"[^\"]+\"', 1, LEVEL) AS substr1
                                   FROM (SELECT v_paramname1 AS str1 FROM DUAL)
                                 CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(str1, '\w+=\"[^\"]+\"')) + 1)
                          WHERE substr1 IS NOT NULL) LOOP
            v_caseTypeData := NULL;
            IF recXML.substr2 IS NOT NULL OR recXML.substr2 <> '' THEN
              SELECT SUBSTR(recXML.substr2, INSTR(recXML.substr2, '=', 1) + 2, (LENGTH(recXML.substr2) - INSTR(recXML.substr2, '=', 1) - 2)) INTO v_caseTypeData FROM dual;
              IF SUBSTR(recXML.substr2, 1, INSTR(recXML.substr2, '=', 1) - 1) = 'CASETYPE_CODE' THEN
                v_collectionCaseType      := v_collectionCaseType || v_caseTypeData || ',';
                v_collectionCaseTypeFound := 1;
              END IF;
              IF SUBSTR(recXML.substr2, 1, INSTR(recXML.substr2, '=', 1) - 1) = 'CASE_STATE' THEN
                v_collectionCaseState := v_collectionCaseState || v_caseTypeData || ',';
              END IF;
              IF SUBSTR(recXML.substr2, 1, INSTR(recXML.substr2, '=', 1) - 1) = 'RESOLUTION_CODE' THEN
                v_collectionResCode := v_collectionResCode || v_caseTypeData || ',';
              END IF;
            END IF;
          END LOOP;
          v_tmpStr              := '"';
          v_collectionCaseType  := v_collectionCaseType || v_tmpStr;
          v_collectionCaseState := v_collectionCaseState || v_tmpStr;
          v_collectionResCode   := v_collectionResCode || v_tmpStr;
          v_collectionCaseType  := REGEXP_REPLACE(v_collectionCaseType, ',"', '', 1, 1);
          v_collectionCaseState := REGEXP_REPLACE(v_collectionCaseState, ',"', '', 1, 1);
          v_collectionResCode   := REGEXP_REPLACE(v_collectionResCode, ',"', '', 1, 1);
        END IF;
      END IF;
    
      --save parameters
      IF (v_collectionCaseType IS NOT NULL) AND (v_collectionCaseState IS NOT NULL) AND (v_collectionResCode IS NOT NULL) THEN
      
        INSERT INTO TBL_AUTORULEPARAMTMPL
          (COL_PARAMVALUE, COL_PARAMCODE, COL_CODE, COL_AUTORULEPARAMTPCASETYPE, COL_AUTORULEPARTMPLSTATEEVENT, COL_DICT_STATESLAACTIONARP)
        VALUES
          (v_collectionCaseType, 'COLLECTION_CASE_TYPE_CODE', SYS_GUID(), v_caseTypeId, v_StateEventId, v_SLAActionId);
      
        INSERT INTO TBL_AUTORULEPARAMTMPL
          (COL_PARAMVALUE, COL_PARAMCODE, COL_CODE, COL_AUTORULEPARAMTPCASETYPE, COL_AUTORULEPARTMPLSTATEEVENT, COL_DICT_STATESLAACTIONARP)
        VALUES
          (v_collectionCaseState, 'COLLECTION_CASE_STATE_CODE', SYS_GUID(), v_caseTypeId, v_StateEventId, v_SLAActionId);
      
        INSERT INTO TBL_AUTORULEPARAMTMPL
          (COL_PARAMVALUE, COL_PARAMCODE, COL_CODE, COL_AUTORULEPARAMTPCASETYPE, COL_AUTORULEPARTMPLSTATEEVENT, COL_DICT_STATESLAACTIONARP)
        VALUES
          (v_collectionResCode, 'COLLECTION_CASE_RESOLUTION_CODE', SYS_GUID(), v_caseTypeId, v_StateEventId, v_SLAActionId);
      END IF;
    END IF;
  END IF;

  --parsing of /Object/Object parameters collection  
  v_paramname  := NULL;
  v_paramname1 := NULL;
  v_paramvalue := NULL;

  v_paramname1 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell/Object/Object/@paramNames');
  IF v_paramname1 IS NOT NULL THEN
    FOR rec IN (SELECT to_char(regexp_substr(v_paramname1, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS ParamName
                  FROM dual
                CONNECT BY dbms_lob.getlength(regexp_substr(v_paramname1, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) LOOP
      IF v_paramvalue IS NULL THEN
        v_paramvalue := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell/Object/Object/@' || rec.ParamName);
      ELSE
        v_paramvalue := v_paramvalue || ',' || f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell/Object/Object/@' || rec.ParamName);
      END IF;
    END LOOP;
  
    --save parameters
    INSERT INTO TBL_AUTORULEPARAMTMPL
      (COL_PARAMVALUE, COL_PARAMCODE, COL_CODE, COL_AUTORULEPARAMTPCASETYPE, COL_AUTORULEPARTMPLSTATEEVENT, COL_DICT_STATESLAACTIONARP)
    VALUES
      (v_paramvalue, 'paramValues', SYS_GUID(), v_caseTypeId, v_StateEventId, v_SLAActionId);
  END IF;

  --get global Object for saving all parameters
  v_paramname  := NULL;
  v_paramname1 := NULL;
  v_paramvalue := NULL;

  v_path := '/mxGraphModel/root/mxCell/Object';
  IF v_input.EXISTSNODE(v_path) = 1 THEN
    v_paramname1 := SUBSTR(v_input.EXTRACT(v_path).getStringval(), 1, 32767);
  ELSE
    v_paramname1 := NULL;
  END IF;

  IF v_paramname1 IS NOT NULL THEN
    FOR recXML IN (SELECT dbms_lob.SUBSTR(substr1, 4000, 1) AS substr2
                     FROM (SELECT REGEXP_SUBSTR(str1, '\w+=\"[^\"]+\"', 1, LEVEL) AS substr1
                             FROM (SELECT v_paramname1 AS str1 FROM DUAL)
                           CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(str1, '\w+=\"[^\"]+\"')) + 1)
                    WHERE substr1 IS NOT NULL) LOOP
      IF (recXML.substr2 IS NOT NULL OR recXML.substr2 <> '') AND (UPPER(recXML.substr2) NOT IN ('AS="DATA"', 'AS="EVENTPARAMS"', 'AS="CASETYPES"', 'AS="TASKTYPEDATA"')
         --add here excluded items from XML
         ) THEN
      
        v_paramname  := NULL;
        v_paramvalue := NULL;
      
        BEGIN
          SELECT REGEXP_SUBSTR(recXML.substr2, '\w+', 1, 1),
                 REGEXP_SUBSTR(recXML.substr2, '\"[^\"]+\"', 1, 1)
            INTO v_paramname,
                 v_paramvalue
            FROM dual;
        EXCEPTION
          WHEN OTHERS THEN
            v_paramname  := NULL;
            v_paramvalue := NULL;
        END;
      
        IF (v_paramname IS NOT NULL) AND (v_paramvalue IS NOT NULL) THEN
          BEGIN
            SELECT SUBSTR(v_paramvalue, 2, LENGTH(v_paramvalue) - 2) INTO v_paramvalue FROM dual;
          EXCEPTION
            WHEN OTHERS THEN
              v_paramvalue := NULL;
          END;
        END IF;
      
        BEGIN
          SELECT SUBSTR(v_paramname, 1, 255) INTO v_tmpStr FROM dual;
        EXCEPTION
          WHEN OTHERS THEN
            v_tmpStr := NULL;
        END;
      
        --convert a parameter's name to the same name as in the procedure builder
        --send email event          
        IF UPPER(v_eventType) = 'MAIL' AND UPPER(v_subType) = 'EMAIL' THEN
          IF UPPER(v_tmpStr) = 'DISTRIBUTIONCHANNEL' THEN
            v_tmpStr := 'DistributionChannel';
          END IF;
          IF UPPER(v_tmpStr) = 'FROM' THEN
            v_tmpStr := 'From';
          END IF;
          IF UPPER(v_tmpStr) = 'FROM_RULE' THEN
            v_tmpStr := 'FromRule';
          END IF;
          IF UPPER(v_tmpStr) = 'TO' THEN
            v_tmpStr := 'To';
          END IF;
          IF UPPER(v_tmpStr) = 'TO_RULE' THEN
            v_tmpStr := 'ToRule';
          END IF;
          IF UPPER(v_tmpStr) = 'CC' THEN
            v_tmpStr := 'Cc';
          END IF;
          IF UPPER(v_tmpStr) = 'BCC' THEN
            v_tmpStr := 'Bcc';
          END IF;
          IF UPPER(v_tmpStr) = 'TEMPLATE' THEN
            v_tmpStr := 'Template';
          END IF;
          IF UPPER(v_tmpStr) = 'TEMPLATE_RULE' THEN
            v_tmpStr := 'TemplateRule';
          END IF;
          IF UPPER(v_tmpStr) = 'CC_RULE' THEN
            v_tmpStr := 'CcRule';
          END IF;
          IF UPPER(v_tmpStr) = 'ATTACHMENTS_RULE' THEN
            v_tmpStr := 'AttachmentsRule';
          END IF;
          IF UPPER(v_tmpStr) = 'BCC_RULE' THEN
            v_tmpStr := 'BccRule';
          END IF;
        END IF; ----send email event
      
        --send sms event          
        IF UPPER(v_eventType) = 'MESSAGETXT' AND UPPER(v_subType) = 'INTEGRATION_TWILIO' THEN
          IF UPPER(v_tmpStr) = 'MESSAGE_CODE' THEN
            v_tmpStr := 'MessageCode';
          END IF;
          IF UPPER(v_tmpStr) = 'MESSAGE_RULE' THEN
            v_tmpStr := 'MessageRule';
          END IF;
          IF UPPER(v_tmpStr) = 'TO' THEN
            v_tmpStr := 'To';
          END IF;
          IF UPPER(v_tmpStr) = 'TO_RULE' THEN
            v_tmpStr := 'ToRule';
          END IF;
          IF UPPER(v_tmpStr) = 'TO_RULE' THEN
            v_tmpStr := 'ToRule';
          END IF;
          IF UPPER(v_tmpStr) = 'FROM' THEN
            v_tmpStr := 'From';
          END IF;
          IF UPPER(v_tmpStr) = 'FROM_RULE' THEN
            v_tmpStr := 'FromRule';
          END IF;
        END IF; ----send sms event  
      
        --save parameters
        IF (v_tmpStr IS NOT NULL) AND UPPER(v_tmpStr) NOT IN ('AS',
                                                              'RN',
                                                              '_CALC_MODIFIED_EXTENDED',
                                                              '_CALC_MODIFIED',
                                                              '_CALC_CREATED_EXTENDED',
                                                              '_CALC_CREATED',
                                                              'MODIFIEDDURATION',
                                                              'MODIFIEDBY_NAME',
                                                              'CREATEDDURATION',
                                                              'CREATEDBY_NAME'
                                                              --add here excluded items from XML 
                                                              ) THEN
          INSERT INTO TBL_AUTORULEPARAMTMPL
            (COL_PARAMVALUE, COL_PARAMCODE, COL_CODE, COL_AUTORULEPARAMTPCASETYPE, COL_AUTORULEPARTMPLSTATEEVENT, COL_DICT_STATESLAACTIONARP)
          VALUES
            (v_paramvalue, v_tmpStr, SYS_GUID(), v_caseTypeId, v_StateEventId, v_SLAActionId);
        END IF;
      END IF;
    END LOOP;
  END IF;

  v_errorCode    := NULL;
  v_errorMessage := NULL;

  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
  RETURN 0;

  --error block
  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
  RETURN - 1;

END;