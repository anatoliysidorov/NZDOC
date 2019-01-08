DECLARE
  v_input                     xmltype;
  v_output                    VARCHAR2(32767);
  v_count                     INTEGER;
  v_count1                    INTEGER;
  v_result                    NVARCHAR2(255);
  v_result2                   NVARCHAR2(255);
  v_result3                   NVARCHAR2(255);
  v_result4                   NUMBER;
  v_id                        INTEGER;
  v_sourceid                  INTEGER;
  v_targetid                  INTEGER;
  v_name                      NVARCHAR2(255);
  v_description               NCLOB;
  v_executiontypecode         NVARCHAR2(255);
  v_executiontype             NVARCHAR2(255);
  v_eventtype                 NVARCHAR2(255);
  v_type                      NVARCHAR2(255);
  v_subtype                   NVARCHAR2(255);
  v_dependencytype            NVARCHAR2(255);
  v_dateeventtype             NVARCHAR2(255);
  v_participantcode           NVARCHAR2(255);
  v_connid                    INTEGER;
  v_connsourceid              INTEGER;
  v_conntargetid              INTEGER;
  v_connissource              INTEGER;
  v_connistarget              INTEGER;
  v_conngwtype                NVARCHAR2(255);
  v_connelementid             INTEGER;
  v_incomingcount             INTEGER;
  v_gwelementid               INTEGER;
  v_AdjDependencyId           INTEGER;
  v_ResolutionCode            NVARCHAR2(255);
  v_SourceElementId           INTEGER;
  v_SourceElementName         NVARCHAR2(255);
  v_SourceElementType         NVARCHAR2(255);
  v_TargetElementId           INTEGER;
  v_TargetElementName         NVARCHAR2(255);
  v_TargetElementType         NVARCHAR2(255);
  v_HierarchyLevel            INTEGER;
  v_RowNumber                 INTEGER;
  v_RuleCode                  NVARCHAR2(255);
  v_AssignRuleCode            NVARCHAR2(255);
  v_paramname                 NCLOB;
  v_paramname1                NCLOB;
  v_paramvalue                NCLOB;
  v_paramNamesCollectionFound INTEGER;
  v_intervalym                NVARCHAR2(255);
  v_intervalds                NVARCHAR2(255);
  v_channel                   NVARCHAR2(255);
  v_PageSend1                 NVARCHAR2(255);
  v_PageSend2                 NVARCHAR2(255);
  v_tasktypecode              NVARCHAR2(255);
  v_XMLParameters             NCLOB;
  v_path                      NVARCHAR2(255);

  --change case state parsing
  v_collectionCaseType      NCLOB;
  v_collectionCaseState     NCLOB;
  v_collectionResCode       NCLOB;
  v_caseTypeData            NVARCHAR2(255);
  v_collectionCaseTypeFound INTEGER;

  v_tmpStr    NVARCHAR2(255);
  v_tmpNumber NUMBER;

  --error(s) handling
  v_YEARS   NVARCHAR2(255);
  v_MONTHS  NVARCHAR2(255);
  v_DAYS    NVARCHAR2(255);
  v_HOURS   NVARCHAR2(255);
  v_MINUTES NVARCHAR2(255);
  v_SECONDS NVARCHAR2(255);
  v_WEEKS   NVARCHAR2(255);

  --out
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);

BEGIN

  /*
  VV
  TODO: add parsing for Case dependency  
  */

  --init
  v_errorcode    := 0;
  v_errormessage := '';

  v_MONTHS  := NULL;
  v_DAYS    := NULL;
  v_HOURS   := NULL;
  v_MINUTES := NULL;
  v_SECONDS := NULL;
  v_WEEKS   := NULL;
  v_YEARS   := NULL;

  v_input := xmltype(:Input);
  DELETE FROM tbl_processcache;
  v_count := 1;
  WHILE (TRUE) LOOP
    v_XMLParameters := NULL;
    v_result        := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@id');
    IF v_result IS NULL THEN
      EXIT;
    END IF;
    BEGIN
      v_id := to_number(v_result);
    EXCEPTION
      WHEN VALUE_ERROR THEN
        v_count := v_count + 1;
        CONTINUE;
    END;
    v_type := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@type');
    IF v_type = 'connection' THEN
      v_type := 'dependency';
    END IF;
    IF v_type = 'service' THEN
      v_type := 'sla';
    END IF;
    v_tmpStr     := NULL;
    v_paramname  := NULL;
    v_paramvalue := NULL;
    v_paramname1 := NULL;
    v_name       := NULL;
    v_intervalym := NULL;
    v_intervalds := NULL;
    IF v_type = 'root' THEN
      v_name := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@name');
    ELSIF v_type = 'task' THEN
      v_name := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@name');
      v_name := dbms_xmlgen.convert(v_name, dbms_xmlgen.ENTITY_DECODE);
    ELSIF v_type = 'gateway' THEN
      v_name := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@name');
    ELSIF v_type = 'event' THEN
      v_name := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@NAME');
    
      --get /Object/Object parameters collection  
      v_paramname  := NULL;
      v_paramvalue := NULL;
      v_paramname  := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Object/@paramNames');
      IF v_paramname IS NOT NULL THEN
        FOR rec IN (SELECT to_char(regexp_substr(v_paramname, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS ParamName
                      FROM dual
                    CONNECT BY dbms_lob.getlength(regexp_substr(v_paramname, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) LOOP
          IF v_paramvalue IS NULL THEN
            v_paramvalue := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Object/@' || rec.ParamName);
          ELSE
            v_paramvalue := v_paramvalue || ',' || f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Object/@' || rec.ParamName);
          END IF;
        END LOOP;
      END IF;
    
      --"change case state" parsing
      v_collectionCaseType      := NULL;
      v_collectionCaseState     := NULL;
      v_collectionResCode       := NULL;
      v_eventType               := NULL;
      v_subType                 := NULL;
      v_collectionCaseTypeFound := NULL;
      v_eventType               := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@eventType');
      v_subType                 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@subtype');
    
      IF (UPPER(v_eventType) IN ('CHANGECASESTATE', 'CHANGEMILESTONE')) AND (UPPER(v_subType) IN ('CHANGECASESTATE', 'CHANGEMILESTONE')) THEN
        v_subType := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Object/@as');
        IF UPPER(v_subType) = 'CASETYPES' THEN
          --get Object for XML collection      
          v_path := '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Object';
          IF v_input.EXISTSNODE(v_path) = 1 THEN
            v_paramname1 := SUBSTR(v_input.extract(v_path).getStringval(), 1, 32767);
            IF v_paramname1 IS NOT NULL THEN
              v_collectionCaseType  := '<Parameter name="COLLECTION_CASE_TYPE_CODE" value="';
              v_collectionCaseState := '<Parameter name="COLLECTION_CASE_STATE_CODE" value="';
              v_collectionResCode   := '<Parameter name="COLLECTION_CASE_RESOLUTION_CODE" value="';
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
              v_collectionCaseType  := REGEXP_REPLACE(v_collectionCaseType, ',"', '"/> ', 1, 1);
              v_collectionCaseState := REGEXP_REPLACE(v_collectionCaseState, ',"', '"/> ', 1, 1);
              v_collectionResCode   := REGEXP_REPLACE(v_collectionResCode, ',"', '"/> ', 1, 1);
            END IF;
          END IF;
        END IF;
      END IF;
      v_paramname1 := NULL;
      v_eventType  := NULL;
      v_subType    := NULL;
    
      --get global Object for XML collection      
      v_path := '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object';
      IF v_input.existsnode(v_path) = 1 THEN
        v_paramname1 := substr(v_input.extract(v_path).getStringval(), 1, 32767);
      ELSE
        v_paramname1 := NULL;
      END IF;
    
      v_XMLParameters             := '<Parameters>';
      v_paramNamesCollectionFound := NULL;
      IF v_paramname1 IS NOT NULL THEN
        FOR recXML IN (SELECT dbms_lob.substr(substr1, 4000, 1) AS substr2
                         FROM (SELECT REGEXP_SUBSTR(str1, '\w+=\"[^\"]+\"', 1, LEVEL) AS substr1
                                 FROM (SELECT v_paramname1 AS str1 FROM DUAL)
                               CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(str1, '\w+=\"[^\"]+\"')) + 1)
                        WHERE substr1 IS NOT NULL) LOOP
          IF recXML.substr2 IS NOT NULL OR recXML.substr2 <> '' THEN
            IF SUBSTR(recXML.substr2, 1, INSTR(recXML.substr2, '=', 1) - 1) = 'paramNames' THEN
              v_paramNamesCollectionFound := 1;
            END IF;
          
            --do mark as "already exists in collection" (exists inside a v_paramvalue) parameter as !_ || recXML.substr2 
            IF (v_paramname IS NOT NULL) AND (v_paramNamesCollectionFound = 1) THEN
              FOR recCheck IN (SELECT to_char(regexp_substr(v_paramname, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS ParamName
                                 FROM dual
                               CONNECT BY dbms_lob.getlength(regexp_substr(v_paramname, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) LOOP
                IF SUBSTR(recXML.substr2, 1, INSTR(recXML.substr2, '=', 1) - 1) = recCheck.ParamName THEN
                  recXML.substr2 := '!_' || recXML.substr2;
                END IF;
              END LOOP;
            END IF;
            v_tmpStr        := '<Parameter name="';
            v_XMLParameters := v_XMLParameters || v_tmpStr;
            v_tmpStr        := recXML.substr2;
            --do mark as "already exists in "set case state" collection             
            IF SUBSTR(v_tmpStr, 1, INSTR(v_tmpStr, '=', 1) - 1) IN ('CASE_STATE', 'RESOLUTION_CODE', 'CASETYPE_CODE') AND v_collectionCaseTypeFound = 1 THEN
              v_tmpStr := '!_' || v_tmpStr;
            END IF;
            v_XMLParameters := v_XMLParameters || REGEXP_REPLACE(v_tmpStr, '=', '" value=', 1, 1);
            v_tmpStr        := '/> ';
            v_XMLParameters := v_XMLParameters || v_tmpStr;
          END IF;
        END LOOP;
        IF v_paramname IS NOT NULL THEN
          v_XMLParameters := v_XMLParameters || '<Parameter name="paramValues" value="' || v_paramvalue || '"/> ';
        END IF;
      END IF;
    
      --add a "set case state" collection 
      IF v_collectionCaseTypeFound = 1 THEN
        v_XMLParameters := v_XMLParameters || v_collectionCaseType;
        v_XMLParameters := v_XMLParameters || v_collectionCaseState;
        v_XMLParameters := v_XMLParameters || v_collectionResCode;
      END IF;
    
      v_tmpStr        := '</Parameters>';
      v_XMLParameters := v_XMLParameters || v_tmpStr;
    
      v_channel := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@channel');
      IF v_channel IS NULL THEN
        v_channel := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@Channel');
      END IF; --events
    
    ELSIF v_type = 'sla' THEN
      v_YEARS   := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@YEARS');
      v_MONTHS  := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MONTHS');
      v_DAYS    := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@DAYS');
      v_HOURS   := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@HOURS');
      v_MINUTES := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MINUTES');
      v_SECONDS := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@SECONDS');
      v_WEEKS   := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@WEEKS');
    
      v_Result := f_STP_processSLAPeriod(ERRORCODE    => v_errorcode,
                                         ERRORMESSAGE => v_errormessage,
                                         INTDS        => v_intervalds,
                                         INTYM        => v_intervalym,
                                         PDAYS        => v_DAYS,
                                         PHOURS       => v_HOURS,
                                         PMINUTES     => v_MINUTES,
                                         PMONTHS      => v_MONTHS,
                                         PSECONDS     => v_SECONDS,
                                         PWEEKS       => v_WEEKS,
                                         PYEARS       => v_YEARS);
      IF v_errorCode IS NOT NULL THEN
        GOTO cleanup;
      END IF;
    
      v_XMLParameters := '<Parameters>';
      IF v_intervalym IS NOT NULL THEN
        v_XMLParameters := v_XMLParameters || '<Parameter name="IntervalYM" value="' || v_intervalym || '"/> ';
      END IF;
    
      IF v_intervalds IS NOT NULL THEN
        v_XMLParameters := v_XMLParameters || '<Parameter name="IntervalDS" value="' || v_intervalds || '"/> ';
      END IF;
    
      --get global Object for XML collection            
      v_path := '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object';
      IF v_input.existsnode(v_path) = 1 THEN
        v_paramname1 := substr(v_input.extract(v_path).getStringval(), 1, 32767);
      ELSE
        v_paramname1 := NULL;
      END IF;
    
      IF v_paramname1 IS NOT NULL THEN
        FOR recXML IN (SELECT dbms_lob.substr(substr1, 4000, 1) AS substr2
                         FROM (SELECT REGEXP_SUBSTR(str1, '\w+=\"[^\"]+\"', 1, LEVEL) AS substr1
                                 FROM (SELECT v_paramname1 AS str1 FROM DUAL)
                               CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(str1, '\w+=\"[^\"]+\"')) + 1)
                        WHERE substr1 IS NOT NULL) LOOP
          v_tmpStr := recXML.substr2;
          IF v_tmpStr IS NOT NULL OR v_tmpStr <> '' THEN
            v_tmpStr        := '<Parameter name="';
            v_XMLParameters := v_XMLParameters || v_tmpStr;
            v_tmpStr        := recXML.substr2;
            v_XMLParameters := v_XMLParameters || REGEXP_REPLACE(v_tmpStr, '=', '" value=', 1, 1);
            v_tmpStr        := '/> ';
            v_XMLParameters := v_XMLParameters || v_tmpStr;
          END IF;
        END LOOP;
      END IF;
    
      v_tmpStr        := '</Parameters>';
      v_XMLParameters := v_XMLParameters || v_tmpStr;
    END IF; --sla
  
    v_executiontypecode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@execution_type_code');
    v_executiontype     := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@executionType');
  
    IF v_type = 'task' THEN
      v_executiontype := v_executiontypecode;
    END IF;
    v_dependencytype := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@dependency_type');
    v_eventtype      := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@eventType');
    IF v_type = 'sla' THEN
      v_subtype       := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@serviceType');
      v_dateeventtype := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@COUNT_FROM');
    ELSE
      v_subtype       := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@subtype');
      v_dateeventtype := NULL;
    END IF;
    v_RuleCode       := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@rule_code');
    v_AssignRuleCode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@AUTO_ASSIGN');
    IF (v_eventtype = 'priority' OR (v_eventtype = 'close' AND v_subtype = 'closecase') OR (v_eventtype = 'resolve' AND v_subtype = 'resolvecase') OR
       (lower(v_eventtype) = 'assigntask' AND lower(v_subtype) = 'assigntask') OR (lower(v_eventtype) = 'assigncase' AND lower(v_subtype) = 'assigncase') OR
       (v_eventtype = 'mail' AND v_subtype = 'email') OR (v_eventtype = 'history' AND v_subtype = 'history') OR (v_eventtype = 'togenesys' AND v_subtype = 'integration_genesys') OR
       (v_eventtype = 'slack' AND v_subtype = 'integration_slack') OR (v_eventtype = 'messageTxt' AND v_subtype = 'integration_twilio') OR v_eventtype = 'case_in_process' OR
       v_eventtype = 'case_new_state' OR v_eventtype = 'close_task' OR v_eventtype = 'task_in_process' OR v_eventtype = 'task_new_state' OR v_eventtype = 'inject_procedure' OR
       v_eventtype = 'inject_tasktype' OR (v_eventtype = 'changeCaseState' AND v_subtype = 'changecasestate') OR (v_eventtype = 'changeMilestone' AND v_subtype = 'changemilestone') OR
       (v_eventtype = 'change_task_state' AND v_subtype = 'change_task_state')) AND v_RuleCode IS NULL THEN
      BEGIN
        SELECT col_processorcode INTO v_RuleCode FROM tbl_dict_actiontype WHERE lower(col_code) = lower(v_eventtype);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_RuleCode := NULL;
      END;
    END IF;
    IF v_eventtype = 'togenesys' AND v_subtype = 'integration_genesys' THEN
      v_PageSend1 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PageSend1');
      v_PageSend2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PageSend2');
      IF v_PageSend1 IS NULL AND v_PageSend2 IS NOT NULL THEN
        v_PageSend1 := v_PageSend2;
      END IF;
    END IF;
    v_description := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@description');
    IF v_description IS NULL THEN
      v_description := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@DESCRIPTION');
    END IF;
    v_participantcode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PARTICIPANT_CODE');
    IF v_participantcode IS NULL THEN
      v_participantcode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PARTICIPANT');
    END IF;
  
    v_tasktypecode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@task_type_code');
    IF v_tasktypecode IS NULL THEN
      v_tasktypecode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TASKTYPE');
    END IF;
  
    --validate task type         
    v_tmpNumber := NULL;
    IF UPPER(v_type) = 'TASK' THEN
      SELECT COUNT(1) INTO v_tmpNumber FROM TBL_DICT_TASKSYSTYPE WHERE UPPER(COl_CODE) = UPPER(v_tasktypecode);
      IF v_tmpNumber <> 1 THEN
        v_errorcode    := 101;
        v_errormessage := 'A Task Type with code "' || v_tasktypecode || '" is invalid. Please, check a Task Type record(s).';
        GOTO cleanup;
      END IF;
      
     --collect a task parameters 
     v_XMLParameters := '<Parameters>'; 
       v_path := '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object';
       IF v_input.existsnode(v_path) = 1 THEN
         v_paramname1 := substr(v_input.extract(v_path).getStringval(), 1, 32767);
       ELSE
         v_paramname1 := NULL;
       END IF;
  
      IF v_paramname1 IS NOT NULL THEN
        FOR recXML IN (SELECT dbms_lob.substr(substr1, 4000, 1) AS substr2
                         FROM (SELECT REGEXP_SUBSTR(str1, '\w+=\"[^\"]+\"', 1, LEVEL) AS substr1
                                 FROM (SELECT v_paramname1 AS str1 FROM DUAL)
                               CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(str1, '\w+=\"[^\"]+\"')) + 1)
                        WHERE substr1 IS NOT NULL) 
        LOOP
          v_tmpStr := recXML.substr2;
          IF v_tmpStr IS NOT NULL OR v_tmpStr <> '' THEN
            v_tmpStr        := '<Parameter name="';
            v_XMLParameters := v_XMLParameters || v_tmpStr;
            v_tmpStr        := recXML.substr2;
            v_XMLParameters := v_XMLParameters || REGEXP_REPLACE(v_tmpStr, '=', '" value=', 1, 1);
            v_tmpStr        := '/> ';
            v_XMLParameters := v_XMLParameters || v_tmpStr;
          END IF;
        END LOOP;
      END IF;
      
      v_tmpStr        := '</Parameters>';
      v_XMLParameters := v_XMLParameters || v_tmpStr;
      
    END IF;
  
    INSERT INTO tbl_processcache
      (col_elementid,
       col_type,
       col_subtype,
       col_procedureid,
       col_name,
       col_code,
       col_value,
       col_tasktypecode,
       col_executiontypecode,
       col_description,
       col_inputsubtype,
       col_outputsubtype,
       col_executiontype,
       col_source,
       col_target,
       col_fromrule,
       col_fromparam,
       col_torule,
       col_toparam,
       col_templaterule,
       col_template,
       col_rulecode,
       col_autoassignrule,
       col_resolutioncode,
       col_prioritycode,
       col_priority,
       col_messageslack,
       col_messagerule,
       col_messagecode,
       col_executionmoment,
       col_eventtype,
       col_distributionchannel,
       col_dependencytype,
       col_conditiontype,
       col_channel,
       col_ccrule,
       col_cc,
       col_bccrule,
       col_bcc,
       col_attachmentrule,
       col_participantcode,
       col_workbasketrule,
       col_paramname,
       col_paramvalue,
       col_intervalym,
       col_intervalds,
       col_dateeventtype,
       col_category,
       col_mediatype,
       col_pagesend1,
       col_pagesend2,
       col_pagesendparamsrule1,
       col_pagesendparamsrule2,
       col_customdatarule,
       col_procedurecode,
       col_inserttotask,
       col_defaultstate,
       col_parameters)
    VALUES
      (v_id,
       v_type,
       v_subtype,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@PROCEDURE_ID'),
       v_name,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@code'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@value'),
       v_tasktypecode,
       v_executiontypecode,
       v_description,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@inputSubType'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@outputSubType'),
       v_executiontype,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@source'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@target'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@FROM_RULE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@FROM'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TO_RULE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TO'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TEMPLATE_RULE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TEMPLATE'),
       v_RuleCode,
       v_AssignRuleCode,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@RESOLUTION_CODE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PRIORITY_CODE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@priority'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@messageSlack'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MESSAGE_RULE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MESSAGE_CODE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@execution_moment'),
       v_eventtype,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@DistributionChannel'),
       v_dependencytype,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@condition_type'),
       v_channel,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@CC_RULE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@CC'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@BCC_RULE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@BCC'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@ATTACHMENTS_RULE'),
       v_participantcode,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@WORKBASKET_RULE'),
       v_paramname,
       v_paramvalue,
       v_intervalym,
       v_intervalds,
       v_dateeventtype,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@Category'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MediaType'),
       v_PageSend1,
       v_PageSend2,
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PageSendParamsRule1'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PageSendParamsRule2'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@CustomDataRule'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PROCEDURE_CODE'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@INSERT_TO_TASK'),
       f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@DEFAULTSTATE'),
       v_XMLParameters);
    IF v_type = 'gateway' THEN
      BEGIN
        SELECT COUNT(*) AS IncomingCount,
               pc.col_elementid AS GatewayId
          INTO v_incomingcount,
               v_gwelementid
          FROM tbl_processcache pc
         INNER JOIN tbl_processcache pc2
            ON pc.col_elementid = pc2.col_target
         WHERE pc.col_type = 'gateway'
           AND pc.col_elementid = v_id
         GROUP BY pc.col_elementid;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_incomingcount := 1;
          v_gwelementid   := v_id;
      END;
      IF v_incomingcount = 1 THEN
        UPDATE tbl_processcache SET col_istask = 0 WHERE col_elementid = v_id;
      ELSIF v_incomingcount > 1 THEN
        UPDATE tbl_processcache SET col_istask = 1 WHERE col_elementid = v_id;
      END IF;
    END IF;
    IF v_type = 'dependency' THEN
      v_count1         := 1;
      v_ResolutionCode := NULL;
      WHILE (TRUE) LOOP
        v_result := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Array/add[' || to_char(v_count1) || ']/@value');
        IF v_result IS NULL THEN
          EXIT;
        END IF;
        IF v_ResolutionCode IS NULL THEN
          v_ResolutionCode := v_result;
        ELSE
          v_ResolutionCode := v_ResolutionCode || ',' || v_result;
        END IF;
        v_count1 := v_count1 + 1;
      END LOOP;
      IF v_dependencytype IS NULL THEN
        BEGIN
          SELECT s.Id,
                 s.ElementId,
                 s.SourceId,
                 s.TargetId,
                 s.IsSource,
                 s.IsTarget,
                 s.GWType
            INTO v_connid,
                 v_connelementid,
                 v_connsourceid,
                 v_conntargetid,
                 v_connissource,
                 v_connistarget,
                 v_conngwtype
            FROM (SELECT pc.col_id             AS Id,
                         pc.col_elementid      AS ElementId,
                         pc.col_source         AS SourceId,
                         pc.col_target         AS TargetId,
                         1                     AS IsSource,
                         0                     AS IsTarget,
                         pc2.col_outputsubtype AS GWType
                    FROM tbl_processcache pc
                   INNER JOIN tbl_processcache pc2
                      ON pc2.col_elementid = pc.col_source
                     AND pc2.col_type = 'gateway'
                   WHERE pc.col_elementid = v_id
                     AND pc.col_type = 'dependency'
                  UNION
                  SELECT pc.col_id            AS Id,
                         pc.col_elementid     AS ElementId,
                         pc.col_source        AS SourceId,
                         pc.col_target        AS TargetId,
                         0                    AS IsSource,
                         1                    AS IsTarget,
                         pc2.col_inputsubtype AS GWType
                    FROM tbl_processcache pc
                   INNER JOIN tbl_processcache pc2
                      ON pc2.col_elementid = pc.col_target
                     AND pc2.col_type = 'gateway'
                   WHERE pc.col_elementid = v_id
                     AND pc.col_type = 'dependency') s;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_conngwtype := NULL;
        END;
        v_dependencytype := v_conngwtype;
      END IF;
      UPDATE tbl_processcache SET col_resolutioncode = v_ResolutionCode, col_dependencytype = v_dependencytype WHERE col_elementid = v_id;
    END IF;
    v_count := v_count + 1;
  END LOOP;
  FOR rec IN (SELECT pc.col_elementid AS ElementId,
                     pc2.col_type     AS SourceType
                FROM tbl_processcache pc
               INNER JOIN tbl_processcache pc2
                  ON pc.col_source = pc2.col_elementid
               WHERE pc.col_type = 'gateway') LOOP
    BEGIN
      SELECT COUNT(*) AS IncomingCount,
             pc.col_elementid AS GatewayId
        INTO v_incomingcount,
             v_gwelementid
        FROM tbl_processcache pc
       INNER JOIN tbl_processcache pc2
          ON pc.col_elementid = pc2.col_target
       WHERE pc.col_type = 'gateway'
         AND pc.col_elementid = v_id
       GROUP BY pc.col_elementid;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_incomingcount := 1;
        v_gwelementid   := v_id;
    END;
    IF v_incomingcount = 1 THEN
      UPDATE tbl_processcache SET col_istask = 0 WHERE col_elementid = v_id;
    ELSIF v_incomingcount > 1 THEN
      UPDATE tbl_processcache SET col_istask = 1 WHERE col_elementid = v_id;
    END IF;
  END LOOP;
  FOR rec IN (SELECT pc.col_elementid AS ElementId,
                     pc2.col_type     AS SourceType
                FROM tbl_processcache pc
               INNER JOIN tbl_processcache pc2
                  ON pc.col_source = pc2.col_elementid
               WHERE pc.col_type = 'dependency') LOOP
    IF rec.SourceType = 'task' THEN
      v_SourceElementId := 0;
    ELSIF rec.SourceType <> 'task' AND rec.SourceType <> 'gateway' THEN
      v_SourceElementId := 0;
    ELSE
      BEGIN
        FOR rec2 IN (SELECT AdjDependencyId,
                            ResolutionCode,
                            SourceElementId,
                            SourceElementName,
                            SourceElementType,
                            TargetElementId,
                            TargetElementName,
                            TargetElementType,
                            HierarchyLevel,
                            RowNumber
                       FROM (SELECT s2.AdjDependencyId,
                                    s2.ResolutionCode,
                                    s2.SourceElementId,
                                    s2.SourceElementName,
                                    s2.SourceElementType,
                                    s2.TargetElementId,
                                    s2.TargetElementName,
                                    s2.TargetElementType,
                                    s2.HierarchyLevel,
                                    row_number() over(ORDER BY HierarchyLevel ASC) AS RowNumber
                               FROM (SELECT s1.AdjDependencyId,
                                            s1.ResolutionCode,
                                            s1.SourceElementId,
                                            s1.SourceElementName,
                                            s1.SourceElementType,
                                            s1.TargetElementId,
                                            s1.TargetElementName,
                                            s1.TargetElementType,
                                            LEVEL AS HierarchyLevel
                                       FROM (SELECT pc.col_elementid      AS AdjDependencyId,
                                                    pc.col_resolutioncode AS ResolutionCode,
                                                    pc2.col_elementid     AS SourceElementId,
                                                    pc2.col_name          AS SourceElementName,
                                                    pc2.col_type          AS SourceElementType,
                                                    pc3.col_elementid     AS TargetElementId,
                                                    pc3.col_name          AS TargetElementName,
                                                    pc3.col_type          AS TargetElementType
                                               FROM tbl_processcache pc
                                              INNER JOIN tbl_processcache pc2
                                                 ON pc.col_source = pc2.col_elementid
                                                AND pc2.col_type IN ('task', 'gateway')
                                              INNER JOIN tbl_processcache pc3
                                                 ON pc.col_target = pc3.col_elementid
                                                AND pc3.col_type IN ('task', 'gateway')
                                              WHERE pc.col_type = 'dependency') s1
                                     CONNECT BY PRIOR s1.SourceElementId = s1.TargetElementId
                                            AND s1.SourceElementType = 'task'
                                      START WITH s1.AdjDependencyId = rec.ElementId) s2)
                      ORDER BY RowNumber) LOOP
          IF rec2.SourceElementType = 'task' THEN
            v_SourceElementId := rec2.SourceElementId;
            EXIT;
          END IF;
        END LOOP;
      END;
      UPDATE tbl_processcache SET col_source2 = v_SourceElementId WHERE col_elementid = rec.ElementId;
    END IF;
  END LOOP;
  FOR rec IN (SELECT col_elementid AS ElementId,
                     col_eventtype AS EventType
                FROM tbl_processcache
               WHERE col_type IN ('event', 'sla')) LOOP
    v_id := NULL;
    BEGIN
      SELECT pc.col_target,
             pc2.col_elementid,
             pc2.col_type
        INTO v_id,
             v_sourceid,
             v_type
        FROM tbl_processcache pc
       INNER JOIN tbl_processcache pc2
          ON pc.col_target = pc2.col_elementid
       WHERE pc.col_type = 'eventConnection'
         AND pc.col_source = rec.ElementId
         AND pc2.col_type IN ('task', 'sla');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_id := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_id := NULL;
    END;
    IF v_id IS NULL THEN
      BEGIN
        SELECT pc.col_source,
               pc2.col_elementid,
               pc2.col_type
          INTO v_id,
               v_sourceid,
               v_type
          FROM tbl_processcache pc
         INNER JOIN tbl_processcache pc2
            ON pc.col_source = pc2.col_elementid
         WHERE pc.col_type = 'eventConnection'
           AND pc.col_target = rec.ElementId
           AND pc2.col_type IN ('task', 'sla');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_id := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_id := NULL;
      END;
    END IF;
    IF v_id IS NOT NULL THEN
      v_RuleCode := NULL;
      IF v_type = 'sla' THEN
        BEGIN
          SELECT col_slaprocessorcode INTO v_RuleCode FROM tbl_dict_actiontype WHERE lower(col_code) = lower(rec.EventType);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_RuleCode := NULL;
        END;
      END IF;
      IF v_RuleCode IS NOT NULL THEN
        UPDATE tbl_processcache SET col_eventtask = v_id, col_rulecode = v_RuleCode WHERE col_elementid = rec.ElementId;
      ELSE
        UPDATE tbl_processcache SET col_eventtask = v_id WHERE col_elementid = rec.ElementId;
      END IF;
    END IF;
  END LOOP;

  <<cleanup>>
  :ErrorCode    := v_errorcode;
  :ErrorMessage := v_errormessage;

  RETURN NULL;

END;
