DECLARE
  v_input                  xmltype;
  v_output                 NCLOB;
  v_count                  INTEGER;
  v_result                 NVARCHAR2(255);
  v_result2                NVARCHAR2(255);
  v_elementid              INTEGER;
  v_code                   NVARCHAR2(255);
  v_name                   NVARCHAR2(255);
  v_description            NCLOB;
  v_procedureid            INTEGER;
  v_procedurecode          NVARCHAR2(255);
  v_inserttotask           NUMBER;
  v_taskType               NVARCHAR2(255);
  v_taskTypeId             INTEGER;
  v_stateConfigId          INTEGER;
  v_stateid                INTEGER;
  v_executionMethod        NVARCHAR2(255);
  v_executionMethodId      INTEGER;
  v_executionType          NVARCHAR2(255);
  v_executionTypeId        INTEGER;
  v_autoassignrule         NVARCHAR2(255);
  v_rootTaskTemplateId     INTEGER;
  v_taskTemplateId         INTEGER;
  v_taskEventId            INTEGER;
  v_taskEventTmplId        INTEGER;
  v_eventtype              NVARCHAR2(255);
  v_priority               NVARCHAR2(255);
  v_subtype                NVARCHAR2(255);
  v_resolutioncode         NVARCHAR2(255);
  v_sourceid               INTEGER;
  v_targetid               INTEGER;
  v_taskstateinitsourceid  INTEGER;
  v_taskstateinitsrctmplid INTEGER;
  v_taskstateinittargetid  INTEGER;
  v_taskstateinittrgtmplid INTEGER;
  v_type                   NVARCHAR2(255);
  v_processorcode          NVARCHAR2(255);
  v_taskDependencyId       INTEGER;
  v_taskDependencyTmplId   INTEGER;
  v_eventtask              INTEGER;
  v_executionMoment        NVARCHAR2(255);
  v_ruleCode               NVARCHAR2(255);
  v_taskstateinitiationid  INTEGER;
  v_taskstateinittmplid    INTEGER;
  v_slaeventid             INTEGER;
  v_slaeventtmplid         INTEGER;
  v_slaActionId            INTEGER;
  v_slaActionTmplId        INTEGER;
  v_distributionchannel    NVARCHAR2(255);
  v_fromrule               NVARCHAR2(255);
  v_torule                 NVARCHAR2(255);
  v_ccrule                 NVARCHAR2(255);
  v_bccrule                NVARCHAR2(255);
  v_templaterule           NVARCHAR2(255);
  v_attachmentsrule        NVARCHAR2(255);
  v_template               NVARCHAR2(255);
  v_from                   NVARCHAR2(255);
  v_to                     NVARCHAR2(255);
  v_cc                     NVARCHAR2(255);
  v_bcc                    NVARCHAR2(255);
  v_messagecode            NVARCHAR2(255);
  v_channel                NVARCHAR2(255);
  v_messageslack           NVARCHAR2(255);
  v_messagerule            NVARCHAR2(255);
  v_participantcode        NVARCHAR2(255);
  v_workbasketrule         NVARCHAR2(255);
  v_category               NVARCHAR2(255);
  v_mediatype              NVARCHAR2(255);
  v_pagesend1              NVARCHAR2(255);
  v_pagesend2              NVARCHAR2(255);
  v_pagesendparamsrule1    NVARCHAR2(255);
  v_pagesendparamsrule2    NVARCHAR2(255);
  v_customdatarule         NVARCHAR2(255);

  --xml using
  v_XMLParameters NCLOB;
  v_XMLcount      INTEGER;
  v_XMLPathName   NVARCHAR2(255);
  v_XMLPathValue  NVARCHAR2(255);
  v_XMLParamName  NVARCHAR2(255);
  v_XMLParamValue NVARCHAR2(4000);

  --out
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);

BEGIN

  /*
  VV
  TODO: add parsing for Case dependency  
  */

  v_output := f_WFL_parseProcModel(Input => :Input, ErrorCode => v_errorcode, ErrorMessage => v_errormessage);
  IF v_errorcode > 0 THEN
    GOTO cleanup;
  END IF;

  BEGIN
    SELECT col_procedureid INTO v_procedureid FROM tbl_processcache WHERE col_procedureid IS NOT NULL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_procedureid := NULL;
      RETURN - 1;
    WHEN TOO_MANY_ROWS THEN
      v_procedureid := NULL;
      RETURN - 1;
  END;
  v_count := f_WFL_deleteProcContentTmpl(v_procedureid);
  v_count := f_WFL_deleteProcContent(v_procedureid);
  --v_code := f_UTIL_extract_value_xml(Input => v_input, Path => '/Process/Procedure/@code');
  BEGIN
    SELECT col_elementid,
           col_procedureid,
           col_code
      INTO v_elementid,
           v_procedureid,
           v_code
      FROM tbl_processcache
     WHERE col_type = 'root';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_procedureid := NULL;
      RETURN - 1;
    WHEN TOO_MANY_ROWS THEN
      v_procedureid := NULL;
      RETURN - 1;
  END;
  BEGIN
    SELECT col_id
      INTO v_rootTaskTemplateId
      FROM tbl_tasktemplate
     WHERE col_proceduretasktemplate = v_procedureid
       AND lower(col_name) = 'root';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO tbl_tasktemplate
        (col_name, col_taskid, col_tasktmpldict_tasksystype, col_proceduretasktemplate, col_parentttid, col_execmethodtasktemplate, col_taskorder, col_id2, col_code)
      VALUES
        ('Root', 'Root', NULL, v_procedureid, 0, NULL, 1, to_number(v_result), sys_guid());
      SELECT gen_tbl_tasktemplate.currval INTO v_rootTaskTemplateId FROM dual;
    WHEN TOO_MANY_ROWS THEN
      DELETE FROM tbl_tasktemplate
       WHERE col_proceduretasktemplate = v_procedureid
         AND lower(col_name) = 'root';
      INSERT INTO tbl_tasktemplate
        (col_name, col_taskid, col_tasktmpldict_tasksystype, col_proceduretasktemplate, col_parentttid, col_execmethodtasktemplate, col_taskorder, col_id2, col_code)
      VALUES
        ('Root', 'Root', NULL, v_procedureid, 0, NULL, 1, to_number(v_result), sys_guid());
      SELECT gen_tbl_tasktemplate.currval INTO v_rootTaskTemplateId FROM dual;
  END;

  --Tasks and gateways
  v_count := 1;
  FOR rec IN (SELECT col_elementid         AS ElementId,
                     col_type              AS TYPE,
                     col_istask            AS IsTask,
                     col_name              AS NAME,
                     col_tasktypecode      AS TaskType,
                     col_executiontypecode AS ExecutionType,
                     col_description       AS Description,
                     col_rulecode          AS RuleCode,
                     col_autoassignrule    AS AutoAssignRule,
                     col_defaultstate      AS DefaultState,
                     col_parameters        AS XMLParameters,

                     /*VV: a new values add here please*/
                     NULL                  AS taskIsHidden                     
                FROM tbl_processcache
               WHERE col_type IN ('task', 'gateway')
               ORDER BY col_elementid) 
  LOOP
    IF rec.Type = 'task' OR (rec.Type = 'gateway' AND rec.IsTask = 1) THEN
      v_name           := rec.Name;
      v_tasktype       := rec.TaskType;
      v_ruleCode       := rec.RuleCode;
      v_autoassignrule := rec.AutoAssignRule;
      BEGIN
        SELECT col_id,
               col_stateconfigtasksystype
          INTO v_taskTypeId,
               v_stateConfigId
          FROM tbl_dict_tasksystype
         WHERE col_code = v_tasktype;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_taskTypeId    := NULL;
          v_stateConfigId := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_taskTypeId    := NULL;
          v_stateConfigId := NULL;
      END;
      -- Execution Method is used to make initiation method property for all task states AUTOMATIC (Initiation Method in TBL_MAP_TASKSTATEINITIATION)
      v_executionMethod := rec.ExecutionType;
      BEGIN
        SELECT col_id INTO v_executionMethodId FROM tbl_dict_initmethod WHERE col_code = v_executionMethod;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_executionMethodId := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_executionMethodId := NULL;
      END;
      -- Execution Type is always 'MANUAL' (in the current implememntation) and is used as the property of the entire task (Execution Method in TBL_TASK)
      v_executiontype := 'MANUAL';
      BEGIN
        SELECT col_id INTO v_executionTypeId FROM tbl_dict_executionmethod WHERE col_code = v_executionType;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_executionTypeId := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_executionTypeId := NULL;
      END;
      --Calculate task state machine configuration
      IF v_stateConfigId IS NULL THEN
        BEGIN
          SELECT col_id
            INTO v_stateConfigId
            FROM tbl_dict_stateconfig
           WHERE col_isdefault = 1
             AND lower(col_type) = 'task';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_stateConfigId := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_stateConfigId := NULL;
        END;
      END IF;
      --Calculate task state in which task must be created
      IF rec.DefaultState IS NULL THEN
        v_stateid := NULL;
      ELSIF lower(rec.DefaultState) = 'default' THEN
        BEGIN
          SELECT col_id
            INTO v_stateid
            FROM tbl_dict_taskstate
           WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateconfigid, 0)
             AND col_isdefaultoncreate = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_stateid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_stateid := NULL;
        END;
      ELSIF lower(rec.DefaultState) = 'start' THEN
        BEGIN
          SELECT col_id
            INTO v_stateid
            FROM tbl_dict_taskstate
           WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateconfigid, 0)
             AND col_isstart = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_stateid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_stateid := NULL;
        END;
      ELSIF lower(rec.DefaultState) = 'assign' THEN
        BEGIN
          SELECT col_id
            INTO v_stateid
            FROM tbl_dict_taskstate
           WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateconfigid, 0)
             AND col_isassign = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_stateid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_stateid := NULL;
        END;
      ELSIF lower(rec.DefaultState) = 'inprocess' THEN
        BEGIN
          SELECT col_id
            INTO v_stateid
            FROM tbl_dict_taskstate
           WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateconfigid, 0)
             AND col_isdefaultoncreate2 = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_stateid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_stateid := NULL;
        END;
      ELSIF lower(rec.DefaultState) = 'resolve' THEN
        BEGIN
          SELECT col_id
            INTO v_stateid
            FROM tbl_dict_taskstate
           WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateconfigid, 0)
             AND col_isresolve = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_stateid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_stateid := NULL;
        END;
      ELSIF lower(rec.DefaultState) = 'finish' THEN
        BEGIN
          SELECT col_id
            INTO v_stateid
            FROM tbl_dict_taskstate
           WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateconfigid, 0)
             AND col_isfinish = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_stateid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_stateid := NULL;
        END;
      ELSE
        BEGIN
          SELECT col_id
            INTO v_stateid
            FROM tbl_dict_taskstate
           WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateconfigid, 0)
             AND col_isdefaultoncreate = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_stateid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_stateid := NULL;
        END;
      END IF;
    
      IF rec.XMLParameters IS NOT NULL THEN
        v_XMLcount := 1;
        WHILE (TRUE) 
        LOOP
          v_XMLPathName   := '/Parameters/Parameter[' || TO_CHAR(v_XMLcount) || ']/@name';
          v_XMLPathValue  := '/Parameters/Parameter[' || TO_CHAR(v_XMLcount) || ']/@value';
          v_XMLParamName  := NULL;
          v_XMLParamValue := NULL;
          v_XMLParamName := F_UTIL_EXTRACT_VALUE_XML(Input => xmltype(rec.XMLParameters), Path => v_XMLPathName);

          IF v_XMLParamName IS NULL THEN EXIT; END IF;

          v_XMLParamValue := F_UTIL_EXTRACT_VALUE_XML(xmltype(rec.XMLParameters), v_XMLPathValue);
          IF UPPER(v_XMLParamName) = 'ISHIDDENTASK' THEN
            rec.taskIsHidden := TO_NUMBER(v_XMLParamValue);
          END IF;
          v_XMLcount := v_XMLcount + 1;
        END LOOP;
      END IF;
    
      INSERT INTO tbl_tasktemplate(col_name, col_tasktmpldict_tasksystype, col_proceduretasktemplate,
                                  col_parentttid, col_execmethodtasktemplate, col_taskorder,
                                  col_description, col_id2, col_processorcode, col_tasktmpldict_taskstate,
                                  col_code, COL_ISHIDDEN)
      VALUES
        (v_name, v_taskTypeId, v_procedureid, v_rootTaskTemplateId, v_executionTypeId, v_count, 
         rec.Description, rec.ElementId, v_ruleCode, v_stateid, sys_guid(), rec.taskIsHidden);
         
      SELECT gen_tbl_tasktemplate.currval INTO v_taskTemplateId FROM dual;
      
      FOR rec2 IN (SELECT col_id       AS StateId,
                          col_code     AS StateCode,
                          col_name     AS StateName,
                          col_activity AS StateActivity,
                          col_isfinish AS IsFinishState,
                          col_isstart  AS IsStartState,
                          col_isassign AS IsAssignState
                     FROM tbl_dict_taskstate
                    WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)) LOOP
        INSERT INTO tbl_map_taskstateinitiation
          (col_map_taskstateinittasktmpl, col_map_tskstinit_tskst, col_map_tskstinit_initmtd, col_assignprocessorcode, col_code)
        VALUES
          (v_taskTemplateId,
           (SELECT col_id
              FROM tbl_dict_taskstate
             WHERE col_activity = rec2.StateActivity
               AND nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)),
           CASE WHEN nvl(rec2.IsStartState, 0) = 0 AND nvl(rec2.IsFinishState, 0) = 0 THEN (SELECT col_id FROM tbl_dict_initmethod WHERE col_code = 'AUTOMATIC') WHEN rec2.IsStartState = 1 THEN
           (SELECT col_id FROM tbl_dict_initmethod WHERE col_code = 'AUTOMATIC_RULE') WHEN rec2.IsFinishState = 1 THEN (SELECT col_id
              FROM tbl_dict_initmethod
             WHERE col_code = (CASE
                     WHEN v_executionMethod = 'MANUAL' THEN
                      'MANUAL'
                     WHEN v_executionMethod = 'AUTOMATIC' THEN
                      'AUTOMATIC'
                     ELSE
                      'MANUAL'
                   END)) ELSE (SELECT col_id FROM tbl_dict_initmethod WHERE col_code = 'AUTOMATIC') END,
           CASE WHEN nvl(rec2.IsAssignState, 0) = 1 THEN v_autoassignrule ELSE NULL END,
           sys_guid());
        INSERT INTO tbl_map_taskstateinittmpl
          (col_map_taskstinittpltasktpl, col_map_tskstinittpl_tskst, col_map_tskstinittpl_initmtd, col_assignprocessorcode, col_code)
        VALUES
          (v_taskTemplateId,
           (SELECT col_id
              FROM tbl_dict_taskstate
             WHERE col_activity = rec2.StateActivity
               AND nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)),
           CASE WHEN nvl(rec2.IsStartState, 0) = 0 AND nvl(rec2.IsFinishState, 0) = 0 THEN (SELECT col_id FROM tbl_dict_initmethod WHERE col_code = 'AUTOMATIC') WHEN rec2.IsStartState = 1 THEN
           (SELECT col_id FROM tbl_dict_initmethod WHERE col_code = 'AUTOMATIC_RULE') WHEN rec2.IsFinishState = 1 THEN (SELECT col_id
              FROM tbl_dict_initmethod
             WHERE col_code = (CASE
                     WHEN v_executionMethod = 'MANUAL' THEN
                      'MANUAL'
                     WHEN v_executionMethod = 'AUTOMATIC' THEN
                      'AUTOMATIC'
                     ELSE
                      'MANUAL'
                   END)) ELSE (SELECT col_id FROM tbl_dict_initmethod WHERE col_code = 'AUTOMATIC') END,
           CASE WHEN nvl(rec2.IsAssignState, 0) = 1 THEN v_autoassignrule ELSE NULL END,
           sys_guid());
      END LOOP;
    END IF;
    v_count := v_count + 1;
  END LOOP;
  --End of tasks and gateways

  --Dependencies--
  v_count := 1;
  FOR rec IN (SELECT col_elementid      AS ElementId,
                     col_dependencytype AS DependencyType,
                     col_resolutioncode AS ResolutionCode,
                     col_source         AS SOURCE,
                     col_target         AS Target,
                     col_source2        AS Source2,
                     col_conditiontype  AS ConditionType,
                     col_rulecode       AS RuleCode
                FROM tbl_processcache
               WHERE col_type = 'dependency'
               ORDER BY col_elementid) LOOP
    v_elementid      := rec.ElementId;
    v_sourceid       := nvl(rec.Source2, rec.Source);
    v_targetid       := rec.Target;
    v_type           := rec.DependencyType;
    v_ResolutionCode := rec.ResolutionCode;
    BEGIN
      SELECT col_tasktypecode
        INTO v_tasktype
        FROM tbl_processcache
       WHERE col_elementid = v_sourceid
         AND col_type = 'task';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_tasktype := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_tasktype := NULL;
    END;
    BEGIN
      SELECT col_id,
             col_stateconfigtasksystype
        INTO v_taskTypeId,
             v_stateConfigId
        FROM tbl_dict_tasksystype
       WHERE col_code = v_tasktype;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskTypeId    := NULL;
        v_stateConfigId := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_taskTypeId    := NULL;
        v_stateConfigId := NULL;
    END;
    --Calculate task state machine configuration
    IF v_stateConfigId IS NULL THEN
      BEGIN
        SELECT col_id
          INTO v_stateConfigId
          FROM tbl_dict_stateconfig
         WHERE col_isdefault = 1
           AND lower(col_type) = 'task';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_stateConfigId := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_stateConfigId := NULL;
      END;
    END IF;
    --Calculate TaskStateInit source
    BEGIN
      SELECT col_id
        INTO v_taskstateinitsourceid
        FROM tbl_map_taskstateinitiation
       WHERE col_map_taskstateinittasktmpl = (SELECT col_id
                                                FROM tbl_tasktemplate
                                               WHERE col_id2 = v_sourceid
                                                 AND col_proceduretasktemplate = v_procedureid)
         AND col_map_tskstinit_tskst = (SELECT col_id
                                          FROM tbl_dict_taskstate
                                         WHERE col_activity = (SELECT col_activity
                                                                 FROM tbl_dict_taskstate
                                                                WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                                                  AND col_isfinish = 1)
                                           AND nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskstateinitsourceid := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_taskstateinitsourceid := NULL;
    END;
    BEGIN
      SELECT col_id
        INTO v_taskstateinitsrctmplid
        FROM tbl_map_taskstateinittmpl
       WHERE col_map_taskstinittpltasktpl = (SELECT col_id
                                               FROM tbl_tasktemplate
                                              WHERE col_id2 = v_sourceid
                                                AND col_proceduretasktemplate = v_procedureid)
         AND col_map_tskstinittpl_tskst = (SELECT col_id
                                             FROM tbl_dict_taskstate
                                            WHERE col_activity = (SELECT col_activity
                                                                    FROM tbl_dict_taskstate
                                                                   WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                                                     AND col_isfinish = 1)
                                              AND nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskstateinitsrctmplid := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_taskstateinitsrctmplid := NULL;
    END;
    BEGIN
      SELECT col_tasktypecode
        INTO v_tasktype
        FROM tbl_processcache
       WHERE col_elementid = v_targetid
         AND col_type = 'task';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_tasktype := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_tasktype := NULL;
    END;
    BEGIN
      SELECT col_id,
             col_stateconfigtasksystype
        INTO v_taskTypeId,
             v_stateConfigId
        FROM tbl_dict_tasksystype
       WHERE col_code = v_tasktype;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskTypeId    := NULL;
        v_stateConfigId := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_taskTypeId    := NULL;
        v_stateConfigId := NULL;
    END;
    --Calculate task state machine configuration
    IF v_stateConfigId IS NULL THEN
      BEGIN
        SELECT col_id
          INTO v_stateConfigId
          FROM tbl_dict_stateconfig
         WHERE col_isdefault = 1
           AND lower(col_type) = 'task';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_stateConfigId := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_stateConfigId := NULL;
      END;
    END IF;
    --Calculate TaskStateInit target
    BEGIN
      SELECT col_id
        INTO v_taskstateinittargetid
        FROM tbl_map_taskstateinitiation
       WHERE col_map_taskstateinittasktmpl = (SELECT col_id
                                                FROM tbl_tasktemplate
                                               WHERE col_id2 = v_targetid
                                                 AND col_proceduretasktemplate = v_procedureid)
         AND col_map_tskstinit_tskst = (SELECT col_id
                                          FROM tbl_dict_taskstate
                                         WHERE col_activity = /*'root_TSK_Status_STARTED'*/
                                               (SELECT col_activity
                                                  FROM tbl_dict_taskstate
                                                 WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                                   AND col_isstart = 1)
                                           AND nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskstateinittargetid := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_taskstateinittargetid := NULL;
    END;
    BEGIN
      SELECT col_id
        INTO v_taskstateinittrgtmplid
        FROM tbl_map_taskstateinittmpl
       WHERE col_map_taskstinittpltasktpl = (SELECT col_id
                                               FROM tbl_tasktemplate
                                              WHERE col_id2 = v_targetid
                                                AND col_proceduretasktemplate = v_procedureid)
         AND col_map_tskstinittpl_tskst = (SELECT col_id
                                             FROM tbl_dict_taskstate
                                            WHERE col_activity = (SELECT col_activity
                                                                    FROM tbl_dict_taskstate
                                                                   WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                                                     AND col_isstart = 1)
                                              AND nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskstateinittrgtmplid := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_taskstateinittrgtmplid := NULL;
    END;
    IF lower(rec.DependencyType) = 'and' THEN
      v_type          := 'FSCA';
      v_processorcode := 'f_ECX_verifyResCodeANDMatch';
    ELSIF lower(rec.DependencyType) = 'inclusivegw' THEN
      v_type          := 'FSCIN';
      v_processorcode := 'f_ECX_verifyResCodeINMatch';
    ELSIF lower(rec.DependencyType) = 'fsclr' AND rec.ConditionType = 'rule' THEN
      v_type          := 'FSCLR';
      v_processorcode := rec.RuleCode;
    ELSIF lower(rec.DependencyType) = 'fsclr' AND rec.ResolutionCode IS NOT NULL THEN
      v_type          := 'FSCLR';
      v_processorcode := 'f_ECX_verifyResCodeMatch';
    ELSIF lower(rec.DependencyType) = 'fsclr' AND rec.ResolutionCode IS NULL THEN
      v_type          := 'FSCLR';
      v_processorcode := NULL;
    ELSIF lower(rec.DependencyType) = 'fsc' THEN
      v_type          := 'FSC';
      v_processorcode := NULL;
    END IF;
    IF v_taskstateinitsourceid IS NOT NULL AND v_taskstateinittargetid IS NOT NULL THEN
      INSERT INTO tbl_taskdependency
        (col_id2, col_tskdpndprnttskstateinit, col_tskdpndchldtskstateinit, col_type, col_processorcode, col_code)
      VALUES
        (v_elementid, v_taskstateinitsourceid, v_taskstateinittargetid, v_type, v_processorcode, sys_guid());
      SELECT gen_tbl_taskdependency.currval INTO v_taskDependencyId FROM dual;
      IF NOT (v_subtype IN ('FSC', 'FSCLR') AND v_resolutioncode IS NULL) THEN
        INSERT INTO tbl_autoruleparameter (col_autoruleparamtaskdep, col_paramcode, col_paramvalue, col_code) VALUES (v_taskDependencyId, 'ResolutionCode', v_resolutioncode, sys_guid());
      END IF;
    END IF;
    IF v_taskstateinitsrctmplid IS NOT NULL AND v_taskstateinittrgtmplid IS NOT NULL THEN
      INSERT INTO tbl_taskdependencytmpl
        (col_id2, col_taskdpprnttptaskstinittp, col_taskdpchldtptaskstinittp, col_type, col_processorcode, col_code)
      VALUES
        (v_elementid, v_taskstateinitsrctmplid, v_taskstateinittrgtmplid, v_type, v_processorcode, sys_guid());
      SELECT gen_tbl_taskdependencytmpl.currval INTO v_taskDependencyTmplId FROM dual;
      IF NOT (v_subtype IN ('FSC', 'FSCLR') AND v_resolutioncode IS NULL) THEN
        INSERT INTO tbl_autoruleparamtmpl (col_autoruleparamtptaskdeptp, col_paramcode, col_paramvalue, col_code) VALUES (v_taskDependencyTmplId, 'ResolutionCode', v_resolutioncode, sys_guid());
      END IF;
    END IF;
    v_count := v_count + 1;
  END LOOP;
  --End of dependencies

  --Slas
  v_count := 1;
  FOR rec IN (SELECT col_elementid AS ElementId,
                     col_eventtask AS EventTask,
                     col_subtype   AS SUBTYPE,
                     /*col_eventtype as EventType, 
                     col_prioritycode as PriorityCode, col_priority as Priority,
                     col_resolutioncode as ResolutionCode, col_distributionchannel as DistributionChannel, col_fromrule as FromRule, col_torule as ToRule, col_ccrule as CcRule, col_bccrule as BccRule,
                     col_templaterule as TemplateRule, col_template as Template, col_attachmentrule as AttachmentRule, col_fromparam as FromParam, col_toparam as ToParam, col_cc as Cc, col_bcc as Bcc,
                     col_messagecode as MessageCode, col_channel as Channel, col_messageslack as MessageSlack, col_messagerule as MessageRule, col_executionmoment as ExecutionMoment, col_rulecode as RuleCode,
                     col_paramname as ParamName, col_paramvalue as ParamValue,*/
                     col_intervalym    AS IntervalYM,
                     col_intervalds    AS IntervalDS,
                     col_dateeventtype AS DateEventType,
                     col_parameters    AS XMLParameters
              /*VV: a new values add here please*/
                FROM tbl_processcache
               WHERE col_type = 'sla'
               ORDER BY col_elementid) LOOP
    --use a XML instead a column's data and/or preserve a backward compatibility
    IF rec.XMLParameters IS NOT NULL THEN
      v_XMLcount := 1;
      WHILE (TRUE) LOOP
        v_XMLPathName   := '/Parameters/Parameter[' || TO_CHAR(v_XMLcount) || ']/@name';
        v_XMLPathValue  := '/Parameters/Parameter[' || TO_CHAR(v_XMLcount) || ']/@value';
        v_XMLParamName  := NULL;
        v_XMLParamValue := NULL;
      
        v_XMLParamName := F_UTIL_EXTRACT_VALUE_XML(Input => xmltype(rec.XMLParameters), Path => v_XMLPathName);
        IF v_XMLParamName IS NULL THEN
          EXIT;
        END IF;
        v_XMLParamValue := F_UTIL_EXTRACT_VALUE_XML(xmltype(rec.XMLParameters), v_XMLPathValue);
      
        IF UPPER(v_XMLParamName) = 'SERVICETYPE' THEN
          rec.Subtype := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'INTERVALYM' THEN
          rec.IntervalYM := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'INTERVALDS' THEN
          rec.IntervalDS := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'COUNT_FROM' THEN
          rec.DateEventType := v_XMLParamValue;
        END IF;
      
        v_XMLcount := v_XMLcount + 1;
      END LOOP;
    END IF; --eof use a XML
  
    v_eventtask := rec.EventTask;
    BEGIN
      SELECT col_id
        INTO v_taskTemplateId
        FROM tbl_tasktemplate
       WHERE col_proceduretasktemplate = v_procedureid
         AND col_id2 = v_eventtask;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskTemplateId := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_taskTemplateId := NULL;
    END;
    INSERT INTO tbl_slaevent
      (col_id2,
       col_slaeventtasktemplate,
       col_slaeventdict_slaeventtype,
       col_slaeventorder,
       col_slaevent_dateeventtype,
       col_intervalym,
       col_intervalds,
       col_slaevent_slaeventlevel,
       col_attemptcount,
       col_maxattempts)
    VALUES
      (rec.ElementId,
       v_taskTemplateId,
       (SELECT col_id FROM tbl_dict_slaeventtype WHERE lower(col_code) = lower(rec.Subtype)),
       (SELECT nvl(MAX(col_slaeventorder), 0) + 1 FROM tbl_slaevent WHERE col_slaeventtasktemplate = v_taskTemplateId),
       (SELECT col_id FROM tbl_dict_dateeventtype WHERE col_code = rec.DateEventType),
       rec.IntervalYM,
       rec.IntervalDS,
       (SELECT col_id FROM tbl_dict_slaeventlevel WHERE col_code = 'BLOCKER'),
       0,
       1);
    INSERT INTO tbl_slaeventtmpl
      (col_id2,
       col_slaeventtptasktemplate,
       col_slaeventtp_slaeventtype,
       col_slaeventorder,
       col_slaeventtp_dateeventtype,
       col_intervalym,
       col_intervalds,
       col_slaeventtp_slaeventlevel,
       col_attemptcount,
       col_maxattempts)
    VALUES
      (rec.ElementId,
       v_taskTemplateId,
       (SELECT col_id FROM tbl_dict_slaeventtype WHERE lower(col_code) = lower(rec.Subtype)),
       (SELECT nvl(MAX(col_slaeventorder), 0) + 1 FROM tbl_slaevent WHERE col_slaeventtasktemplate = v_taskTemplateId),
       (SELECT col_id FROM tbl_dict_dateeventtype WHERE col_code = rec.DateEventType),
       rec.IntervalYM,
       rec.IntervalDS,
       (SELECT col_id FROM tbl_dict_slaeventlevel WHERE col_code = 'BLOCKER'),
       0,
       1);
  END LOOP;
  --End Slas

  --Events
  v_count := 1;
  FOR rec IN (SELECT col_elementid           AS ElementId,
                     col_eventtask           AS EventTask,
                     col_eventtype           AS EventType,
                     col_subtype             AS SUBTYPE,
                     col_prioritycode        AS PriorityCode,
                     col_priority            AS Priority,
                     col_resolutioncode      AS ResolutionCode,
                     col_distributionchannel AS DistributionChannel,
                     col_fromrule            AS FromRule,
                     col_torule              AS ToRule,
                     col_ccrule              AS CcRule,
                     col_bccrule             AS BccRule,
                     col_templaterule        AS TemplateRule,
                     col_template            AS Template,
                     col_attachmentrule      AS AttachmentRule,
                     col_fromparam           AS FromParam,
                     col_toparam             AS ToParam,
                     col_cc                  AS Cc,
                     col_bcc                 AS Bcc,
                     col_messagecode         AS MessageCode,
                     col_channel             AS Channel,
                     col_messageslack        AS MessageSlack,
                     col_messagerule         AS MessageRule,
                     col_participantcode     AS ParticipantCode,
                     col_workbasketrule      AS WorkbasketRule,
                     col_executionmoment     AS ExecutionMoment,
                     col_rulecode            AS RuleCode,
                     col_paramname           AS ParamName,
                     col_paramvalue          AS ParamValue,
                     col_category            AS Category,
                     col_mediatype           AS MediaType,
                     col_pagesend1           AS PageSend1,
                     col_pagesend2           AS PageSend2,
                     col_pagesendparamsrule1 AS PageSendParamsRule1,
                     col_pagesendparamsrule2 AS PageSendParamsRule2,
                     col_customdatarule      AS CustomDataRule,
                     col_name                AS NAME,
                     col_description         AS Description,
                     col_procedurecode       AS ProcedureCode,
                     col_tasktypecode        AS TaskTypeCode,
                     col_inserttotask        AS InsertToTask,
                     col_parameters          AS XMLParameters,
                     /*VV: a new values add here please*/
                     
                     --"change case state"
                     NULL AS CaseTypeCode,
                     NULL AS CaseStateCode,
                     NULL AS CaseResCode,
                     
                     --"execution_state"
                     NULL AS ExecutionState,
                     
                     --"change task state"
                     NULL AS TaskStateCode
              
                FROM tbl_processcache
               WHERE col_type = 'event'
               ORDER BY col_elementid) LOOP
    --use a XML instead a column's data and/or preserve a backward compatibility
    IF rec.XMLParameters IS NOT NULL THEN
      v_XMLcount := 1;
      WHILE (TRUE) LOOP
        v_XMLPathName   := '/Parameters/Parameter[' || TO_CHAR(v_XMLcount) || ']/@name';
        v_XMLPathValue  := '/Parameters/Parameter[' || TO_CHAR(v_XMLcount) || ']/@value';
        v_XMLParamName  := NULL;
        v_XMLParamValue := NULL;
      
        v_XMLParamName := F_UTIL_EXTRACT_VALUE_XML(Input => xmltype(rec.XMLParameters), Path => v_XMLPathName);
        IF v_XMLParamName IS NULL THEN
          EXIT;
        END IF;
        v_XMLParamValue := F_UTIL_EXTRACT_VALUE_XML(xmltype(rec.XMLParameters), v_XMLPathValue);
      
        IF UPPER(v_XMLParamName) = 'INSERT_TO_TASK' THEN
          rec.InsertToTask := TO_NUMBER(v_XMLParamValue);
        END IF;
        IF UPPER(v_XMLParamName) = 'TASK_TYPE_CODE' THEN
          rec.TaskTypeCode := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PROCEDURE_CODE' THEN
          rec.ProcedureCode := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'NAME' THEN
          rec.Name := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'DESCRIPTION' THEN
          rec.Description := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'CUSTOMDATARULE' THEN
          rec.CustomDataRule := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PAGESENDPARAMSRULE2' THEN
          rec.PageSendParamsRule2 := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PAGESENDPARAMSRULE1' THEN
          rec.PageSendParamsRule1 := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PAGESEND2' THEN
          rec.PageSend2 := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PAGESEND1' THEN
          rec.PageSend1 := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'MEDIATYPE' THEN
          rec.MediaType := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'CATEGORY' THEN
          rec.Category := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PARAMNAMES' THEN
          rec.ParamName := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PARAMVALUES' THEN
          rec.ParamValue := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'RULE_CODE' THEN
          rec.RuleCode := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'EXECUTION_MOMENT' THEN
          rec.ExecutionMoment := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'WORKBASKET_RULE' THEN
          rec.WorkbasketRule := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PARTICIPANT_CODE' THEN
          rec.ParticipantCode := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'MESSAGE_RULE' THEN
          rec.MessageRule := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'MESSAGESLACK' THEN
          rec.MessageSlack := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'CHANNEL' THEN
          rec.Channel := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'MESSAGE_CODE' THEN
          rec.MessageCode := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'BCC' THEN
          rec.Bcc := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'CC' THEN
          rec.Cc := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'TO' THEN
          rec.ToParam := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'FROM' THEN
          rec.FromParam := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'ATTACHMENTS_RULE' THEN
          rec.AttachmentRule := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'TEMPLATE' THEN
          rec.Template := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'TEMPLATE_RULE' THEN
          rec.TemplateRule := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'BCC_RULE' THEN
          rec.BccRule := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'CC_RULE' THEN
          rec.CcRule := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PRIORITY_CODE' THEN
          rec.PriorityCode := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'PRIORITY' THEN
          rec.Priority := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'RESOLUTION_CODE' THEN
          rec.ResolutionCode := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'DISTRIBUTIONCHANNEL' THEN
          rec.DistributionChannel := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'FROM_RULE' THEN
          rec.FromRule := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'TO_RULE' THEN
          rec.ToRule := v_XMLParamValue;
        END IF;
        --"change case state" 
        IF UPPER(v_XMLParamName) = 'COLLECTION_CASE_TYPE_CODE' THEN
          rec.CaseTypeCode := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'COLLECTION_CASE_STATE_CODE' THEN
          rec.CaseStateCode := v_XMLParamValue;
        END IF;
        IF UPPER(v_XMLParamName) = 'COLLECTION_CASE_RESOLUTION_CODE' THEN
          rec.CaseResCode := v_XMLParamValue;
        END IF;
        --"execution_state"
        IF UPPER(v_XMLParamName) = 'EXECUTION_STATE' THEN
          rec.ExecutionState := v_XMLParamValue;
        END IF;
        --"change task state"            
        IF UPPER(v_XMLParamName) = 'TASK_STATE' THEN
          rec.TaskStateCode := v_XMLParamValue;
        END IF;
      
        v_XMLcount := v_XMLcount + 1;
      END LOOP;
    END IF; --eof use a XML
  
    v_eventtask := rec.EventTask;
    BEGIN
      SELECT col_elementid,
             col_type
        INTO v_elementid,
             v_type
        FROM tbl_processcache
       WHERE col_elementid = v_eventtask
         AND col_type IN ('task', 'sla');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_elementid := NULL;
        v_type      := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_elementid := NULL;
        v_type      := NULL;
    END;
    IF v_type = 'task' THEN
      BEGIN
        SELECT col_tasktypecode
          INTO v_tasktype
          FROM tbl_processcache
         WHERE col_elementid = v_eventtask
           AND col_type = 'task';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_tasktype := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_tasktype := NULL;
      END;
      BEGIN
        SELECT col_id,
               col_stateconfigtasksystype
          INTO v_taskTypeId,
               v_stateConfigId
          FROM tbl_dict_tasksystype
         WHERE col_code = v_tasktype;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_taskTypeId    := NULL;
          v_stateConfigId := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_taskTypeId    := NULL;
          v_stateConfigId := NULL;
      END;
      --Calculate task state machine configuration
      IF v_stateConfigId IS NULL THEN
        BEGIN
          SELECT col_id
            INTO v_stateConfigId
            FROM tbl_dict_stateconfig
           WHERE col_isdefault = 1
             AND lower(col_type) = 'task';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_stateConfigId := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_stateConfigId := NULL;
        END;
      END IF;
    END IF;
    v_eventtype := rec.EventType;
    v_subtype   := rec.Subtype;
  
    IF v_eventtype = 'priority' THEN
      v_priority := rec.PriorityCode;
    ELSIF (v_eventtype = 'close' AND v_subtype = 'closecase') OR (v_eventtype = 'resolve' AND v_subtype = 'resolvecase') THEN
      v_resolutioncode := rec.ResolutionCode;
    ELSIF v_eventtype = 'mail' AND v_subtype = 'email' THEN
      v_distributionchannel := rec.DistributionChannel;
      v_fromrule            := rec.FromRule;
      v_torule              := rec.ToRule;
      v_ccrule              := rec.CcRule;
      v_bccrule             := rec.BccRule;
      v_templaterule        := rec.TemplateRule;
      v_template            := rec.Template;
      v_attachmentsrule     := rec.AttachmentRule;
      v_from                := rec.FromParam;
      v_to                  := rec.ToParam;
      v_cc                  := rec.Cc;
      v_bcc                 := rec.Bcc;
    ELSIF v_eventtype = 'history' AND v_subtype = 'history' THEN
      v_messagecode := rec.MessageCode;
    ELSIF v_eventtype = 'assignTask' AND v_subtype = 'assignTask' THEN
      v_participantcode := rec.ParticipantCode;
      v_workbasketrule  := rec.WorkbasketRule;
    ELSIF v_eventtype = 'assignCase' AND v_subtype = 'assignCase' THEN
      v_participantcode := rec.ParticipantCode;
      v_workbasketrule  := rec.WorkbasketRule;
    ELSIF v_eventtype = 'togenesys' AND v_subtype = 'integration_genesys' THEN
      v_channel             := rec.Channel;
      v_priority            := rec.Priority;
      v_category            := rec.Category;
      v_mediatype           := rec.MediaType;
      v_pagesend1           := rec.PageSend1;
      v_pagesend2           := rec.PageSend2;
      v_pagesendparamsrule1 := rec.PageSendParamsRule1;
      v_pagesendparamsrule2 := rec.PageSendParamsRule2;
      v_customdatarule      := rec.CustomDataRule;
    ELSIF v_eventtype = 'slack' AND v_subtype = 'integration_slack' THEN
      v_channel      := rec.Channel;
      v_messageslack := rec.MessageSlack;
    ELSIF v_eventtype = 'messageTxt' AND v_subtype = 'integration_twilio' THEN
      v_messagecode := rec.MessageCode;
      v_fromrule    := rec.FromRule;
      v_torule      := rec.ToRule;
      v_messagerule := rec.MessageRule;
      v_from        := rec.FromParam;
      v_to          := rec.ToParam;
    ELSIF v_eventtype = 'close_task' THEN
      v_resolutioncode := rec.ResolutionCode;
    ELSIF v_eventtype = 'inject_procedure' THEN
      v_name          := rec.Name;
      v_description   := rec.Description;
      v_procedurecode := rec.ProcedureCode;
      v_inserttotask  := rec.InsertToTask;
    ELSIF v_eventtype = 'inject_tasktype' THEN
      v_name            := rec.Name;
      v_description     := rec.Description;
      v_tasktype        := rec.TaskTypeCode;
      v_participantcode := rec.ParticipantCode;
      v_inserttotask    := rec.InsertToTask;
    END IF;
  
    --use an "execution_state" from XML instead an "execution_moment" and preserve a backward compatibility
    IF rec.ExecutionState IS NULL THEN
      v_executionMoment := rec.ExecutionMoment;
    END IF;
  
    IF rec.ExecutionState IS NOT NULL THEN
      v_executionMoment := rec.ExecutionState;
    END IF;
  
    --INSERT into tbl_log(col_data1) values(v_executionMoment);
    v_ruleCode := rec.RuleCode;
    IF v_type = 'task' THEN
    
      --use "execution_moment" (old)
      IF rec.ExecutionState IS NULL THEN
        BEGIN
          --INSERT into tbl_log(col_data1) values('rec.ExecutionState IS NULL'||'(old)');
          SELECT col_id
            INTO v_taskstateinitiationid
            FROM tbl_map_taskstateinitiation
           WHERE col_map_taskstateinittasktmpl = (SELECT col_id
                                                    FROM tbl_tasktemplate
                                                   WHERE col_proceduretasktemplate = v_procedureid
                                                     AND col_id2 = v_eventtask)
             AND col_map_tskstinit_tskst = (CASE
                   WHEN lower(v_executionMoment) = 'closed' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_CLOSED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isfinish = 1))
                   WHEN lower(v_executionMoment) = 'start' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_STARTED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isstart = 1))
                   WHEN lower(v_executionMoment) = 'in_progress' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_IN_PROCESS'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isdefaultoncreate2 = 1))
                   WHEN lower(v_executionMoment) = 'assigned' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_ASSIGNED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isassign = 1))
                   WHEN lower(v_executionMoment) = 'resolved' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_RESOLVED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isresolve = 1))
                   ELSE
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_CLOSED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isfinish = 1))
                 END);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_taskstateinitiationid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_taskstateinitiationid := NULL;
        END;
      
        BEGIN
          SELECT col_id
            INTO v_taskstateinittmplid
            FROM tbl_map_taskstateinittmpl
           WHERE col_map_taskstinittpltasktpl = (SELECT col_id
                                                   FROM tbl_tasktemplate
                                                  WHERE col_proceduretasktemplate = v_procedureid
                                                    AND col_id2 = v_eventtask)
             AND col_map_tskstinittpl_tskst = (CASE
                   WHEN lower(v_executionMoment) = 'closed' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_CLOSED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isfinish = 1))
                   WHEN lower(v_executionMoment) = 'start' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_STARTED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isstart = 1))
                   WHEN lower(v_executionMoment) = 'in_progress' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_IN_PROCESS'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isdefaultoncreate2 = 1))
                   WHEN lower(v_executionMoment) = 'assigned' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_ASSIGNED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isassign = 1))
                   WHEN lower(v_executionMoment) = 'resolved' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_RESOLVED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isresolve = 1))
                   ELSE
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_CLOSED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isfinish = 1))
                 END);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_taskstateinittmplid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_taskstateinittmplid := NULL;
        END;
      END IF;
    
      --use "execution_state" (new)
      IF rec.ExecutionState IS NOT NULL THEN
        BEGIN
          --INSERT into tbl_log(col_data1) values('rec.ExecutionState IS NOT NULL'||' (new) '||rec.ExecutionState);
          --INSERT into tbl_log(col_data1) values('v_stateConfigId='||TO_CHAR(v_stateConfigId));
          SELECT col_id
            INTO v_taskstateinitiationid
            FROM tbl_map_taskstateinitiation
           WHERE col_map_taskstateinittasktmpl = (SELECT col_id
                                                    FROM tbl_tasktemplate
                                                   WHERE col_proceduretasktemplate = v_procedureid
                                                     AND col_id2 = v_eventtask)
             AND col_map_tskstinit_tskst = (CASE
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_CLOSED' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_CLOSED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isfinish = 1))
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_STARTED' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_STARTED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isstart = 1))
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_IN_PROCESS' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_IN_PROCESS'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isdefaultoncreate2 = 1))
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_AUTO_ASSIGNMENT' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_ASSIGNED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isassign = 1))
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_NEW' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = (SELECT col_activity
                                              FROM tbl_dict_taskstate
                                             WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                               AND col_isdefaultoncreate = 1))
                   ELSE
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_CLOSED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isfinish = 1))
                 END);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_taskstateinitiationid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_taskstateinitiationid := NULL;
        END;
      
        --INSERT into tbl_log(col_data1) values('v_taskstateinitiationid='||TO_CHAR(v_taskstateinitiationid));
      
        BEGIN
          SELECT col_id
            INTO v_taskstateinittmplid
            FROM tbl_map_taskstateinittmpl
           WHERE col_map_taskstinittpltasktpl = (SELECT col_id
                                                   FROM tbl_tasktemplate
                                                  WHERE col_proceduretasktemplate = v_procedureid
                                                    AND col_id2 = v_eventtask)
             AND col_map_tskstinittpl_tskst = (CASE
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_CLOSED' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_CLOSED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isfinish = 1))
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_STARTED' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_STARTED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isstart = 1))
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_IN_PROCESS' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_IN_PROCESS'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isdefaultoncreate2 = 1))
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_AUTO_ASSIGNMENT' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_ASSIGNED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isassign = 1))
                   WHEN UPPER(v_executionMoment) = 'DEFAULT_TASK_NEW' THEN
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_RESOLVED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isdefaultoncreate = 1))
                   ELSE
                    (SELECT col_id
                       FROM tbl_dict_taskstate
                      WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                        AND col_activity = /*'root_TSK_Status_CLOSED'*/
                            (SELECT col_activity
                               FROM tbl_dict_taskstate
                              WHERE nvl(col_stateconfigtaskstate, 0) = nvl(v_stateConfigId, 0)
                                AND col_isfinish = 1))
                 END);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_taskstateinittmplid := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_taskstateinittmplid := NULL;
        END;
      END IF;
    
      --INSERT into tbl_log(col_data1) values('v_taskstateinittmplid='||TO_CHAR(v_taskstateinittmplid));
    
      INSERT INTO tbl_taskevent
        (col_id2, col_code, col_taskeventtaskstateinit, col_processorcode, col_taskeventmomenttaskevent, col_taskeventtypetaskevent, col_taskeventorder)
      VALUES
        (rec.ElementId,
         sys_guid(),
         v_taskstateinitiationid,
         v_ruleCode,
         (SELECT col_id FROM tbl_dict_taskeventmoment WHERE col_code = 'AFTER'),
         (SELECT col_id FROM tbl_dict_taskeventtype WHERE col_code = 'ACTION'),
         (SELECT nvl(MAX(col_taskeventorder), 0) + 1 FROM tbl_taskevent WHERE col_taskeventtaskstateinit = v_taskstateinitiationid));
    
      SELECT gen_tbl_taskevent.currval INTO v_taskEventId FROM dual;
    
      INSERT INTO tbl_taskeventtmpl
        (col_id2, col_code, col_taskeventtptaskstinittp, col_processorcode, col_taskeventmomnttaskeventtp, col_taskeventtypetaskeventtp, col_taskeventorder)
      VALUES
        (rec.ElementId,
         sys_guid(),
         v_taskstateinittmplid,
         v_ruleCode,
         (SELECT col_id FROM tbl_dict_taskeventmoment WHERE col_code = 'AFTER'),
         (SELECT col_id FROM tbl_dict_taskeventtype WHERE col_code = 'ACTION'),
         (SELECT nvl(MAX(col_taskeventorder), 0) + 1 FROM tbl_taskeventtmpl WHERE col_taskeventtptaskstinittp = v_taskstateinittmplid));
    
      SELECT gen_tbl_taskeventtmpl.currval INTO v_taskEventTmplId FROM dual;
    
      IF v_eventtype = 'rule' AND rec.ParamName IS NOT NULL AND rec.ParamValue IS NOT NULL THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        IF rec.ParamName IS NOT NULL THEN
          FOR rec2 IN (SELECT s1.ParamName  AS ParamName,
                              s2.ParamValue AS ParamValue
                         FROM (SELECT ROWNUM AS RowNumber,
                                      to_char(regexp_substr(rec.ParamName, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS ParamName
                                 FROM dual
                               CONNECT BY dbms_lob.getlength(regexp_substr(rec.ParamName, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s1
                        INNER JOIN (SELECT ROWNUM AS RowNumber,
                                          to_char(regexp_substr(rec.ParamValue, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS ParamValue
                                     FROM dual
                                   CONNECT BY dbms_lob.getlength(regexp_substr(rec.ParamValue, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s2
                           ON s1.RowNumber = s2.RowNumber) LOOP
            INSERT INTO tbl_autoruleparameter
              (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
            VALUES
              (sys_guid(), v_taskEventId, v_taskstateinitiationid, rec2.ParamName, rec2.ParamValue);
            INSERT INTO tbl_autoruleparamtmpl
              (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
            VALUES
              (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, rec2.ParamName, rec2.ParamValue);
          END LOOP;
        END IF;
      
      ELSIF v_eventtype = 'priority' AND v_priority IS NOT NULL THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'priority', v_priority);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'priority', v_priority);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF (v_eventtype = 'close' AND v_subtype = 'closecase') OR (v_eventtype = 'resolve' AND v_subtype = 'resolvecase') THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ResolutionCode', v_resolutioncode);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ResolutionCode', v_resolutioncode);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'mail' AND v_subtype = 'email' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'DistributionChannel', v_distributionchannel);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'FromRule', v_fromrule);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ToRule', v_torule);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'CcRule', v_ccrule);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'BccRule', v_bccrule);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'TemplateRule', v_templaterule);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Template', v_template);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'AttachmentsRule', v_attachmentsrule);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'From', v_from);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'To', v_to);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Cc', v_cc);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Bcc', v_bcc);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'DistributionChannel', v_distributionchannel);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'FromRule', v_fromrule);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ToRule', v_torule);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'CcRule', v_ccrule);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'BccRule', v_bccrule);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'TemplateRule', v_templaterule);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Template', v_template);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'AttachmentsRule', v_attachmentsrule);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'From', v_from);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'To', v_to);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Cc', v_cc);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Bcc', v_bcc);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'history' AND v_subtype = 'history' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MessageCode', v_messagecode);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MessageCode', v_messagecode);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'assignTask' AND v_subtype = 'assignTask' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ParticipantCode', v_participantcode);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'WorkbasketRule', v_workbasketrule);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ParticipantCode', v_participantcode);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'WorkbasketRule', v_workbasketrule);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'assignCase' AND v_subtype = 'assignCase' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ParticipantCode', v_participantcode);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'WorkbasketRule', v_workbasketrule);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ParticipantCode', v_participantcode);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'WorkbasketRule', v_workbasketrule);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'togenesys' AND v_subtype = 'integration_genesys' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Channel', v_channel);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'priority', v_priority);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Category', v_category);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MediaType', v_mediatype);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'PageSend1', v_pagesend1);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'PageSend2', v_pagesend2);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'PageSendParamsRule1', v_pagesendparamsrule1);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'PageSendParamsRule2', v_pagesendparamsrule2);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'CustomDataRule', v_customdatarule);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Channel', v_channel);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'priority', v_priority);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Category', v_category);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MediaType', v_mediatype);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'PageSend1', v_pagesend1);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'PageSend2', v_pagesend2);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'PageSendParamsRule1', v_pagesendparamsrule1);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'PageSendParamsRule2', v_pagesendparamsrule2);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'CustomDataRule', v_customdatarule);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'slack' AND v_subtype = 'integration_slack' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Channel', v_channel);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MessageSlack', v_messageslack);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Channel', v_channel);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MessageSlack', v_messageslack);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'messageTxt' AND v_subtype = 'integration_twilio' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MessageCode', v_messagecode);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'FromRule', v_fromrule);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ToRule', v_torule);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MessageRule', v_messagerule);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'From', v_from);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'To', v_to);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MessageCode', v_messagecode);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'FromRule', v_fromrule);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ToRule', v_torule);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MessageRule', v_messagerule);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'From', v_from);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'To', v_to);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'case_in_process' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'case_new_state' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'close_task' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ResolutionCode', v_resolutioncode);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ResolutionCode', v_resolutioncode);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'task_in_process' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'task_new_state' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'inject_procedure' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Name', v_name);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Description', v_description);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ProcedureCode', v_procedurecode);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'InsertToTask', v_inserttotask);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Name', v_name);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Description', v_description);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ProcedureCode', v_procedurecode);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'InsertToTask', v_inserttotask);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
      ELSIF v_eventtype = 'inject_tasktype' THEN
        --select gen_tbl_taskevent.currval into v_taskEventId from dual;
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Name', v_name);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Description', v_description);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'TaskTypeCode', v_tasktype);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ParticipantCode', v_participantcode);
        INSERT INTO tbl_autoruleparameter
          (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'InsertToTask', v_inserttotask);
        UPDATE tbl_taskevent SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventId;
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Name', v_name);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Description', v_description);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'TaskTypeCode', v_tasktype);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ParticipantCode', v_participantcode);
        INSERT INTO tbl_autoruleparamtmpl
          (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        VALUES
          (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'InsertToTask', v_inserttotask);
        UPDATE tbl_taskeventtmpl SET col_processorcode = v_ruleCode WHERE col_id = v_taskEventTmplId;
      
        --"change case state"
      ELSIF (v_eventtype = 'changeCaseState' AND v_subtype = 'changecasestate') OR (v_eventtype = 'changeMilestone' AND v_subtype = 'changemilestone') THEN
      
        /*select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ResolutionCode', v_resolutioncode);*/
        /*
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'CaseState', v_casestate);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
        */
        IF rec.CaseTypeCode IS NOT NULL AND rec.CaseStateCode IS NOT NULL AND rec.CaseResCode IS NOT NULL THEN
          --SELECT gen_tbl_taskevent.currval INTO v_taskEventId FROM dual;
          FOR rec2 IN (SELECT dct.col_id       AS CaseTypeId,
                              s1.CaseTypeCode  AS CaseTypeCode,
                              s2.CaseStateCode AS CaseStateCode,
                              s3.CaseResCode   AS CaseResCode
                         FROM (SELECT ROWNUM AS RowNumber,
                                      to_char(regexp_substr(rec.CaseTypeCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS CaseTypeCode
                                 FROM dual
                               CONNECT BY dbms_lob.getlength(regexp_substr(rec.CaseTypeCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s1
                        INNER JOIN (SELECT ROWNUM AS RowNumber,
                                          to_char(regexp_substr(rec.CaseStateCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS CaseStateCode
                                     FROM dual
                                   CONNECT BY dbms_lob.getlength(regexp_substr(rec.CaseStateCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s2
                           ON s1.RowNumber = s2.RowNumber
                        INNER JOIN (SELECT ROWNUM AS RowNumber,
                                          to_char(regexp_substr(rec.CaseResCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS CaseResCode
                                     FROM dual
                                   CONNECT BY dbms_lob.getlength(regexp_substr(rec.CaseResCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s3
                           ON s1.RowNumber = s3.RowNumber
                        INNER JOIN TBL_DICT_CASESYSTYPE dct
                           ON UPPER(s1.CaseTypeCode) = UPPER(dct.COL_CODE)) LOOP
          
            INSERT INTO TBL_AUTORULEPARAMETER
              (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue, col_AutoRuleParamCaseSysType)
            VALUES
              (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'CaseState', rec2.CaseStateCode, rec2.CaseTypeId);
          
            INSERT INTO TBL_AUTORULEPARAMETER
              (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue, col_AutoRuleParamCaseSysType)
            VALUES
              (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ResolutionCode', rec2.CaseResCode, rec2.CaseTypeId);
          
            INSERT INTO TBL_AUTORULEPARAMTMPL
              (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue, col_AutoRuleParamTpCaseType)
            VALUES
              (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'CaseState', rec2.CaseStateCode, rec2.CaseTypeId);
          
            INSERT INTO TBL_AUTORULEPARAMTMPL
              (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue, col_AutoRuleParamTpCaseType)
            VALUES
              (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ResolutionCode', rec2.CaseResCode, rec2.CaseTypeId);
          END LOOP;
        END IF;
      
      ELSIF (v_eventtype = 'change_task_state' AND v_subtype = 'change_task_state') THEN
        IF rec.TaskStateCode IS NOT NULL AND rec.ResolutionCode IS NOT NULL THEN
        
          INSERT INTO TBL_AUTORULEPARAMETER
            (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
          VALUES
            (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'TaskState', rec.TaskStateCode);
        
          INSERT INTO TBL_AUTORULEPARAMETER
            (col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
          VALUES
            (sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ResolutionCode', rec.ResolutionCode);
        
          INSERT INTO TBL_AUTORULEPARAMTMPL
            (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
          VALUES
            (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'TaskState', rec.TaskStateCode);
        
          INSERT INTO TBL_AUTORULEPARAMTMPL
            (col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
          VALUES
            (sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ResolutionCode', rec.ResolutionCode);
        END IF;
      END IF;
    END IF;
  
    IF v_type = 'sla' THEN
      BEGIN
        SELECT col_id
          INTO v_slaeventid
          FROM tbl_slaevent
         WHERE col_id2 = v_eventtask
           AND col_slaeventtasktemplate IN (SELECT col_id FROM tbl_tasktemplate WHERE col_proceduretasktemplate = v_procedureid);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_slaeventid := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_slaeventid := NULL;
      END;
      BEGIN
        SELECT col_id
          INTO v_slaeventtmplid
          FROM tbl_slaeventtmpl
         WHERE col_id2 = v_eventtask
           AND col_slaeventtptasktemplate IN (SELECT col_id FROM tbl_tasktemplate WHERE col_proceduretasktemplate = v_procedureid);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_slaeventtmplid := NULL;
        WHEN TOO_MANY_ROWS THEN
          v_slaeventtmplid := NULL;
      END;
    
      INSERT INTO tbl_slaaction
        (col_code, col_slaactionslaevent, col_processorcode, col_slaaction_slaeventlevel, col_actionorder)
      VALUES
        (sys_guid(), v_slaeventid, v_ruleCode, NULL, (SELECT nvl(MAX(col_actionorder), 0) + 1 FROM tbl_slaaction WHERE col_slaactionslaevent = v_slaeventid));
    
      SELECT gen_tbl_slaaction.currval INTO v_slaActionId FROM dual;
    
      INSERT INTO tbl_slaactiontmpl
        (col_code, col_slaactiontpslaeventtp, col_processorcode, col_slaactiontp_slaeventlevel, col_actionorder)
      VALUES
        (sys_guid(), v_slaeventtmplid, v_ruleCode, NULL, (SELECT nvl(MAX(col_actionorder), 0) + 1 FROM tbl_slaactiontmpl WHERE col_slaactiontpslaeventtp = v_slaeventtmplid));
    
      SELECT gen_tbl_slaactiontmpl.currval INTO v_slaActionTmplId FROM dual;
    
      IF v_eventtype = 'rule' AND rec.ParamName IS NOT NULL AND rec.ParamValue IS NOT NULL THEN
        SELECT gen_tbl_slaaction.currval INTO v_slaActionId FROM dual;
        IF rec.ParamName IS NOT NULL THEN
          FOR rec2 IN (SELECT s1.ParamName  AS ParamName,
                              s2.ParamValue AS ParamValue
                         FROM (SELECT ROWNUM AS RowNumber,
                                      to_char(regexp_substr(rec.ParamName, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS ParamName
                                 FROM dual
                               CONNECT BY dbms_lob.getlength(regexp_substr(rec.ParamName, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s1
                        INNER JOIN (SELECT ROWNUM AS RowNumber,
                                          to_char(regexp_substr(rec.ParamValue, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS ParamValue
                                     FROM dual
                                   CONNECT BY dbms_lob.getlength(regexp_substr(rec.ParamValue, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s2
                           ON s1.RowNumber = s2.RowNumber) LOOP
            INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, rec2.ParamName, rec2.ParamValue);
            INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, rec2.ParamName, rec2.ParamValue);
          END LOOP;
        END IF;
      ELSIF v_eventtype = 'priority' AND v_priority IS NOT NULL THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'priority', v_priority);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'priority', v_priority);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF (v_eventtype = 'close' AND v_subtype = 'closecase') OR (v_eventtype = 'resolve' AND v_subtype = 'resolvecase') THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'ResolutionCode', v_resolutioncode);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'ResolutionCode', v_resolutioncode);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'mail' AND v_subtype = 'email' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'DistributionChannel', v_distributionchannel);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'FromRule', v_fromrule);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'ToRule', v_torule);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'CcRule', v_ccrule);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'BccRule', v_bccrule);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'TemplateRule', v_templaterule);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'Template', v_template);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'AttachmentsRule', v_attachmentsrule);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'From', v_from);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'To', v_to);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'Cc', v_cc);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'Bcc', v_bcc);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'DistributionChannel', v_distributionchannel);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'FromRule', v_fromrule);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'ToRule', v_torule);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'CcRule', v_ccrule);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'BccRule', v_bccrule);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'TemplateRule', v_templaterule);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'Template', v_template);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'AttachmentsRule', v_attachmentsrule);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'From', v_from);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'To', v_to);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'Cc', v_cc);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'Bcc', v_bcc);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'history' AND v_subtype = 'history' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'MessageCode', v_messagecode);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'MessageCode', v_messagecode);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'togenesys' AND v_subtype = 'integration_genesys' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'Channel', v_channel);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'priority', v_priority);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'Channel', v_channel);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'priority', v_priority);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'slack' AND v_subtype = 'integration_slack' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'Channel', v_channel);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'MessageSlack', v_messageslack);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'Channel', v_channel);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'MessageSlack', v_messageslack);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'messageTxt' AND v_subtype = 'integration_twilio' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'MessageCode', v_messagecode);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'FromRule', v_fromrule);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'ToRule', v_torule);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'MessageRule', v_messagerule);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'From', v_from);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'To', v_to);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'MessageCode', v_messagecode);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'FromRule', v_fromrule);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'ToRule', v_torule);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'MessageRule', v_messagerule);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'From', v_from);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'To', v_to);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'case_in_process' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'case_new_state' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'close_task' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'ResolutionCode', v_resolutioncode);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'ResolutionCode', v_resolutioncode);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'task_in_process' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'task_new_state' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'inject_procedure' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'Name', v_name);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'Description', v_description);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'ProcedureCode', v_procedurecode);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'InsertToTask', v_inserttotask);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'Name', v_name);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'Description', v_description);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'ProcedureCode', v_procedurecode);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'InsertToTask', v_inserttotask);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
      ELSIF v_eventtype = 'inject_tasktype' THEN
        --select gen_tbl_slaaction.currval into v_slaActionId from dual;
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'Name', v_name);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'Description', v_description);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'TaskTypeCode', v_tasktype);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'ParticipantCode', v_participantcode);
        INSERT INTO tbl_autoruleparameter (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'InsertToTask', v_inserttotask);
        UPDATE tbl_slaaction SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionId;
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'Name', v_name);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'Description', v_description);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'TaskTypeCode', v_tasktype);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'ParticipantCode', v_participantcode);
        INSERT INTO tbl_autoruleparamtmpl (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'InsertToTask', v_inserttotask);
        UPDATE tbl_slaactiontmpl SET col_processorcode = v_ruleCode WHERE col_id = v_slaActionTmplId;
        --"change case state"
      ELSIF (v_eventtype = 'changeCaseState' AND v_subtype = 'changecasestate') OR (v_eventtype = 'changeMilestone' AND v_subtype = 'changemilestone') THEN
        /*select gen_tbl_slaaction.currval into v_slaActionId from dual;        
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'ResolutionCode', v_resolutioncode);*/
      
        /*
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'CaseState', v_casestate);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
        */
        IF rec.CaseTypeCode IS NOT NULL AND rec.CaseStateCode IS NOT NULL AND rec.CaseResCode IS NOT NULL THEN
          --select gen_tbl_slaaction.currval into v_slaActionId from dual;
          FOR rec2 IN (SELECT dct.col_id       AS CaseTypeId,
                              s1.CaseTypeCode  AS CaseTypeCode,
                              s2.CaseStateCode AS CaseStateCode,
                              s3.CaseResCode   AS CaseResCode
                         FROM (SELECT ROWNUM AS RowNumber,
                                      to_char(regexp_substr(rec.CaseTypeCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS CaseTypeCode
                                 FROM dual
                               CONNECT BY dbms_lob.getlength(regexp_substr(rec.CaseTypeCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s1
                        INNER JOIN (SELECT ROWNUM AS RowNumber,
                                          to_char(regexp_substr(rec.CaseStateCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS CaseStateCode
                                     FROM dual
                                   CONNECT BY dbms_lob.getlength(regexp_substr(rec.CaseStateCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s2
                           ON s1.RowNumber = s2.RowNumber
                        INNER JOIN (SELECT ROWNUM AS RowNumber,
                                          to_char(regexp_substr(rec.CaseResCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS CaseResCode
                                     FROM dual
                                   CONNECT BY dbms_lob.getlength(regexp_substr(rec.CaseResCode, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s3
                           ON s1.RowNumber = s3.RowNumber
                        INNER JOIN TBL_DICT_CASESYSTYPE dct
                           ON UPPER(s1.CaseTypeCode) = UPPER(dct.COL_CODE)) LOOP
          
            INSERT INTO TBL_AUTORULEPARAMETER
              (col_code, col_autoruleparamslaaction, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue, col_AutoRuleParamCaseSysType)
            VALUES
              (sys_guid(), v_slaActionId, v_taskstateinitiationid, 'CaseState', rec2.CaseStateCode, rec2.CaseTypeId);
          
            INSERT INTO TBL_AUTORULEPARAMETER
              (col_code, col_autoruleparamslaaction, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue, col_AutoRuleParamCaseSysType)
            VALUES
              (sys_guid(), v_slaActionId, v_taskstateinitiationid, 'ResolutionCode', rec2.CaseResCode, rec2.CaseTypeId);
          
            INSERT INTO TBL_AUTORULEPARAMTMPL
              (col_code, col_autorulepartpslaactiontp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue, col_AutoRuleParamTpCaseType)
            VALUES
              (sys_guid(), v_slaActionTmplId, v_taskstateinittmplid, 'CaseState', rec2.CaseStateCode, rec2.CaseTypeId);
          
            INSERT INTO TBL_AUTORULEPARAMTMPL
              (col_code, col_autorulepartpslaactiontp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue, col_AutoRuleParamTpCaseType)
            VALUES
              (sys_guid(), v_slaActionTmplId, v_taskstateinittmplid, 'ResolutionCode', rec2.CaseResCode, rec2.CaseTypeId);
          END LOOP;
        END IF;
      
        --"change task state"
      ELSIF (v_eventtype = 'change_task_state' AND v_subtype = 'change_task_state') THEN
        IF rec.TaskStateCode IS NOT NULL AND rec.ResolutionCode IS NOT NULL THEN
        
          INSERT INTO TBL_AUTORULEPARAMETER
            (col_code, col_autoruleparamslaaction, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
          VALUES
            (sys_guid(), v_slaActionId, v_taskstateinitiationid, 'TaskState', rec.TaskStateCode);
        
          INSERT INTO TBL_AUTORULEPARAMETER
            (col_code, col_autoruleparamslaaction, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
          VALUES
            (sys_guid(), v_slaActionId, v_taskstateinitiationid, 'ResolutionCode', rec.ResolutionCode);
        
          INSERT INTO TBL_AUTORULEPARAMTMPL
            (col_code, col_autorulepartpslaactiontp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
          VALUES
            (sys_guid(), v_slaActionTmplId, v_taskstateinittmplid, 'TaskState', rec.TaskStateCode);
        
          INSERT INTO TBL_AUTORULEPARAMTMPL
            (col_code, col_autorulepartpslaactiontp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
          VALUES
            (sys_guid(), v_slaActionTmplId, v_taskstateinittmplid, 'ResolutionCode', rec.ResolutionCode);
        END IF;
      
        --"Assign Task"/"Assign Case"
      ELSIF (v_eventtype = 'assignTask' AND v_subtype = 'assignTask') OR (v_eventtype = 'assignCase' AND v_subtype = 'assignCase') THEN
      
        INSERT INTO TBL_AUTORULEPARAMETER (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'ParticipantCode', v_participantcode);
      
        INSERT INTO TBL_AUTORULEPARAMETER (col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionId, 'WorkbasketRule', v_workbasketrule);
      
        INSERT INTO TBL_AUTORULEPARAMTMPL (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'ParticipantCode', v_participantcode);
      
        INSERT INTO TBL_AUTORULEPARAMTMPL (col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue) VALUES (sys_guid(), v_slaActionTmplId, 'WorkbasketRule', v_workbasketrule);
      
      END IF;
    END IF;
    v_count := v_count + 1;
  END LOOP;
  --End of events

  RETURN 0;

  <<cleanup>>
  :ErrorCode    := v_errorcode;
  :ErrorMessage := v_errormessage;

  RETURN - 1;

END;
