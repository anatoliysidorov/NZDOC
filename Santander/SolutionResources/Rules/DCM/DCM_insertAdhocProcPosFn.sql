DECLARE
  v_result              NUMBER;
  v_TaskId              INTEGER;
  v_TaskIdCustom        INTEGER;
  v_CaseId              INTEGER;
  v_StartTaskId         INTEGER;
  v_StartTaskDate       DATE;
  v_TransactionId       INTEGER;
  v_BusTaskId           NVARCHAR2(255);
  v_affectedRows        INTEGER;
  v_ErrorCode           NUMBER;
  v_ErrorMessage        NCLOB;
  v_sourceid            INTEGER;
  v_parentid            INTEGER;
  v_parentid2           INTEGER;
  v_depth               INTEGER;
  v_TokenDomain         NVARCHAR2(255);
  v_workflow            NVARCHAR2(255);
  v_activitycode        NVARCHAR2(255);
  v_workflowcode        NVARCHAR2(255);
  v_stateClosed         NVARCHAR2(255);
  v_stateNew            NVARCHAR2(255);
  v_stateStarted        NVARCHAR2(255);
  v_stateAssigned       NVARCHAR2(255);
  v_stateInProgress     NVARCHAR2(255);
  v_stateConfigId       INTEGER;
  v_createdby           NVARCHAR2(255);
  v_createddate         DATE;
  v_modifiedby          NVARCHAR2(255);
  v_modifieddate        DATE;
  v_owner               NVARCHAR2(255);
  v_rootname            NVARCHAR2(255);
  v_name                NVARCHAR2(255);
  v_description         NCLOB;
  v_required            NUMBER;
  v_leaf                INTEGER;
  v_icon                NVARCHAR2(255);
  v_iconcls             NVARCHAR2(255);
  v_taskorder           INTEGER;
  v_enabled             NUMBER;
  v_hoursworked         NUMBER;
  v_systemtype          NVARCHAR2(255);
  v_DateAssigned        DATE;
  v_prefix              NVARCHAR2(255);
  v_workbasketid        INTEGER;
  v_position            NVARCHAR2(255);
  v_attachedproc        INTEGER;
  v_attachedproccode    NVARCHAR2(255);
  v_count               INTEGER;
  v_adhocTaskTypeId     INTEGER;
  v_adhocTaskTypeCode   NVARCHAR2(255);
  v_adhocExecMehodId    INTEGER;
  v_deleteroot          NUMBER;
  v_customdataprocessor NVARCHAR2(255);
  v_TaskExtId           INTEGER;
  v_Input               NCLOB;
  v_draft               NUMBER;
  v_DebugSession        NVARCHAR2(255);

  v_validationresult NUMBER;
  v_historymsg       NCLOB;
  v_Attributes       NVARCHAR2(4000);

  --------------------------------
  v_preventDocFolderCreate NUMBER;
  v_CaseFrom               NVARCHAR2(255);
  v_DocumentsName          NVARCHAR2(255);
  v_DocumentsURL           NVARCHAR2(255);
  V_SV_URL                 NVARCHAR2(255);
  V_SV_FILENAME            NVARCHAR2(255);
  v_parentfolder_id        NUMBER;
  v_outData CLOB;
  
  CURSOR urls(sv_urls IN NCLOB) IS
    SELECT * FROM TABLE(Asf_split(sv_urls, '|||'));
  CURSOR file_names(sv_names IN NCLOB) IS
    SELECT * FROM TABLE(Asf_split(sv_names, '|||'));

BEGIN
  v_CaseId           := :CaseId;
  v_createdby        := SYS_CONTEXT('CLIENTCONTEXT', 'AccessSubject');
  v_createddate      := SYSDATE;
  v_modifiedby       := v_createdby;
  v_modifieddate     := v_createddate;
  v_owner            := v_createdby;
  v_sourceid         := :sourceid;
  v_rootname         := :RootName;
  v_deleteroot       := :DeleteRoot;
  v_description      := :Description;
  v_required         := 0;
  v_leaf             := 1;
  v_icon             := NULL;
  v_iconcls          := v_icon;
  v_enabled          := 1;
  v_hoursworked      := NULL;
  v_systemtype       := NULL;
  v_DateAssigned     := v_createddate;
  v_prefix           := 'TASK';
  v_workbasketid     := :WorkbasketId;
  v_position         := :Position;
  v_attachedproc     := :AttachedProcedure;
  v_attachedproccode := :AttachedProcCode;
  v_Input            := :Input;

  v_validationresult := NULL;
  v_historymsg       := NULL;
  v_outData      := NULL;

  IF v_Input IS NULL THEN
    v_Input := '<CustomData><Attributes></Attributes></CustomData>';
  END IF;
  v_draft                  := :Draft;
  v_TransactionId          := NULL;
  :ErrorCode               := 0;
  :ErrorMessage            := NULL;
  v_preventDocFolderCreate := NVL(:preventDocFolderCreate, 0);
  v_CaseFrom               := NVL(:CaseFrom, 'main'); --options are either 'main' or 'portal'

  v_TokenDomain := f_UTIL_getDomainFn();
  v_workflow    := f_DCM_getTaskWorkflowCodeFn();

  v_stateNew        := f_dcm_getTaskNewState();
  v_stateStarted    := f_dcm_getTaskStartedState();
  v_stateAssigned   := f_dcm_getTaskAssignedState();
  v_stateClosed     := f_dcm_getTaskClosedState();
  v_stateInProgress := f_DCM_getTaskInProcessState();

  --IF SOURCE TASK IS NOT DEFINED APPEND ADHOC TASK TO CASE ROOT TASK
  IF v_sourceid IS NULL THEN
    v_position := 'append';
  END IF;

  --FIND SOURCE TASK IF NOT DEFINED
  IF v_sourceid IS NULL THEN
    BEGIN
      SELECT col_id
        INTO v_sourceid
        FROM tbl_task
       WHERE col_casetask = v_CaseId
         AND nvl(col_parentid, 0) = 0;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_sourceid     := NULL;
        v_ErrorCode    := 101;
        v_ErrorMessage := 'Source task not found';
        :ErrorCode     := v_ErrorCode;
        :ErrorMessage  := v_ErrorMessage;
        RETURN - 1;
    END;
  END IF;

  IF v_attachedproc IS NULL AND v_attachedproccode IS NOT NULL THEN
    BEGIN
      SELECT col_id INTO v_attachedproc FROM tbl_procedure WHERE lower(col_code) = lower(v_attachedproccode);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_attachedproc := NULL;
    END;
  END IF;

  IF v_rootname IS NULL THEN
    BEGIN
      SELECT col_name INTO v_rootname FROM tbl_procedure WHERE col_id = v_attachedproc;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_rootname := NULL;
    END;
  END IF;

  BEGIN
    SELECT col_id,
           col_casetask,
           col_depth,
           col_id
      INTO v_TaskId,
           v_CaseId,
           v_depth,
           v_parentid
      FROM tbl_task
     WHERE col_id = v_sourceId;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_TaskId       := NULL;
      v_ErrorCode    := 101;
      v_ErrorMessage := 'Source task not found';
      :ErrorCode     := v_ErrorCode;
      :ErrorMessage  := v_ErrorMessage;
      RETURN - 1;
  END;

  BEGIN
    SELECT col_id INTO v_adhocTaskTypeId FROM tbl_dict_tasksystype WHERE lower(col_code) = 'adhoc';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_adhocTaskTypeId := NULL;
      v_ErrorCode       := 101;
      v_ErrorMessage    := 'Adhoc task type not found';
      :ErrorCode        := v_ErrorCode;
      :ErrorMessage     := v_ErrorMessage;
      RETURN - 1;
  END;

  BEGIN
    SELECT col_roottasktypecode INTO v_adhocTaskTypeCode FROM tbl_procedure WHERE col_id = v_attachedproc;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_adhocTaskTypeCode := NULL;
  END;

  IF v_adhocTaskTypeCode IS NOT NULL THEN
    BEGIN
      SELECT col_id INTO v_result FROM tbl_dict_tasksystype WHERE lower(col_code) = lower(v_adhocTaskTypeCode);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_result := NULL;
    END;
    IF v_result IS NOT NULL THEN
      v_adhocTaskTypeId := v_result;
    END IF;
  END IF;

  BEGIN
    SELECT col_id INTO v_adhocExecMehodId FROM tbl_dict_executionmethod WHERE lower(col_code) = 'manual';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_adhocExecMehodId := NULL;
      v_ErrorCode        := 101;
      v_ErrorMessage     := 'Adhoc execution method not found';
      :ErrorCode         := v_ErrorCode;
      :ErrorMessage      := v_ErrorMessage;
      RETURN - 1;
  END;

  IF v_position IS NULL THEN
    v_position := 'append';
  END IF;

  v_Attributes := '<SourceTaskId>' || TO_CHAR(v_sourceid) || '</SourceTaskId>' || '<Position>' || TO_CHAR(v_position) || '</Position>' || '<RootName>' || TO_CHAR(v_rootname) || '</RootName>' ||
                  '<WorkbasketId>' || TO_CHAR(v_workbasketid) || '</WorkbasketId>' || '<AttachedProcId>' || TO_CHAR(v_attachedproc) || '</AttachedProcId>' || '<AttachedProcCode>' ||
                  TO_CHAR(v_attachedproccode) || '</AttachedProcCode>';

  /*--
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -INSERT_ADHOC_PROC- 
     AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,  
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'INSERT_ADHOC_PROC',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'VALIDATION',
                                       historymessage   => v_historymsg,
                                       procedureid      => v_attachedproc,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);

  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                       issystem       => 0,
                                       MESSAGE        => 'Validation Common event(s)',
                                       messagecode    => 'CommonEvent',
                                       targetid       => v_sourceid,
                                       targettype     => 'TASK');
  END IF;

  IF NVL(v_validationresult, 0) <> 1 THEN
    v_ErrorCode    := 199;
    v_ErrorMessage := 'Validation failed. Error: ' || v_ErrorMessage;
    GOTO cleanup;
  END IF;

  /*--
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -INSERT_ADHOC_PROC- 
     AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'INSERT_ADHOC_PROC',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => v_attachedproc,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);

  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg, issystem => 0, MESSAGE => 'Action Common event(s)', messagecode => 'CommonEvent', targetid => v_sourceid, targettype => 'TASK');
  END IF;

  IF v_position = 'append' THEN
    BEGIN
      SELECT MAX(col_taskorder) + 1
        INTO v_taskorder
        FROM tbl_task
       WHERE col_parentid = v_sourceId
         AND col_casetask = v_CaseId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskorder    := NULL;
        v_ErrorCode    := 101;
        v_ErrorMessage := 'Parent task not found';
        :ErrorCode     := v_ErrorCode;
        :ErrorMessage  := v_ErrorMessage;
        RETURN - 1;
    END;
    IF (v_taskorder IS NULL OR v_taskorder = 0) THEN
      v_taskorder := 1;
    END IF;
    v_depth := v_depth + 1;
  ELSIF v_position = 'insert_before' THEN
    BEGIN
      SELECT col_parentid,
             col_taskorder
        INTO v_parentid,
             v_taskorder
        FROM tbl_task
       WHERE col_id = v_sourceId
         AND col_casetask = v_CaseId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskorder    := NULL;
        v_ErrorCode    := 101;
        v_ErrorMessage := 'Source task not found';
        :ErrorCode     := v_ErrorCode;
        :ErrorMessage  := v_ErrorMessage;
        RETURN - 1;
    END;
  ELSIF v_position = 'insert_after' THEN
    BEGIN
      SELECT col_parentid,
             col_taskorder + 1
        INTO v_parentid,
             v_taskorder
        FROM tbl_task
       WHERE col_id = v_sourceId
         AND col_casetask = v_CaseId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskorder    := NULL;
        v_ErrorCode    := 101;
        v_ErrorMessage := 'Source task not found';
        :ErrorCode     := v_ErrorCode;
        :ErrorMessage  := v_ErrorMessage;
        RETURN - 1;
    END;
    UPDATE tbl_task
       SET col_taskorder = col_taskorder + 1
     WHERE col_parentid = (SELECT col_parentid FROM tbl_task WHERE col_id = v_sourceId)
       AND col_taskorder > v_taskorder;
  END IF;

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => NULL, ProcedureId => v_attachedproc);
  v_result       := f_DBG_createDBGTrace(CaseId   => v_CaseId,
                                         Location => 'DCM_insertAdhocProcPosFn begin',
                                         Message  => 'Adhoc procedure ' || v_attachedproccode || ' is about to be created and attached to case ' || to_char(v_CaseId),
                                         Rule     => 'DCM_insertAdhocProcPosFn',
                                         TaskId   => NULL);

  SELECT gen_tbl_task.nextval - 1 INTO v_StartTaskId FROM dual;
  SELECT SYSDATE INTO v_StartTaskDate FROM dual;

  FOR rec IN (SELECT col_id,
                     col_parentttid,
                     col_description,
                     col_name,
                     col_depth,
                     col_leaf,
                     col_icon,
                     col_iconcls,
                     col_taskorder,
                     col_tasktmpldict_tasksystype,
                     col_execmethodtasktemplate,
                     col_processorcode,
                     COL_ISHIDDEN
                FROM tbl_tasktemplate
               WHERE col_proceduretasktemplate = v_attachedproc
               ORDER BY col_parentttid,
                        col_taskorder) LOOP
    IF v_deleteroot = 1 AND lower(rec.col_name) = 'root' THEN
      CONTINUE;
    END IF;
    IF lower(rec.col_name) <> 'root' THEN
      v_name := rec.col_name;
    ELSE
      v_name := v_rootname;
    END IF;
    INSERT INTO tbl_task
      (col_createdby,
       col_createddate,
       col_modifiedby,
       col_modifieddate,
       col_owner,
       col_id2,
       col_parentid,
       col_description,
       col_name,
       col_required,
       col_depth,
       col_leaf,
       col_icon,
       col_iconcls,
       col_taskorder,
       col_casetask,
       col_enabled,
       col_hoursworked,
       col_systemtype2,
       col_DateAssigned,
       col_taskdict_tasksystype,
       col_taskdict_executionmethod,
       col_processorname,
       col_taskppl_workbasket,
       col_taskprocedure,
       col_customdata,
       COL_ISHIDDEN)
    VALUES
      (v_createdby,
       v_createddate,
       v_modifiedby,
       v_modifieddate,
       v_owner,
       rec.col_id,
       v_parentid,
       (CASE WHEN v_description IS NOT NULL THEN v_description ELSE rec.col_description END),
       v_name,
       v_required,
       rec.col_depth + v_depth,
       rec.col_leaf,
       rec.col_icon,
       rec.col_iconcls,
       rec.col_taskorder + v_taskorder - 1,
       (SELECT col_casetask FROM tbl_task WHERE col_id = v_TaskId),
       v_enabled,
       v_hoursworked,
       v_systemtype,
       v_DateAssigned,
       rec.col_tasktmpldict_tasksystype,
       rec.col_execmethodtasktemplate,
       rec.col_processorcode,
       v_workbasketid,
       v_attachedproc,
       xmltype(v_Input),
       rec.COL_ISHIDDEN);
    SELECT gen_tbl_task.currval INTO v_TaskId FROM dual;
    IF v_TransactionId IS NULL THEN
      v_TransactionId := v_TaskId;
    END IF;
    UPDATE tbl_task SET col_transactionid = v_TransactionId WHERE col_id = v_TaskId;
    --------------------------------------------------------------------------------------------------
    UPDATE tbl_task tsk3
       SET col_parentid =
           (SELECT tsk.col_id
              FROM tbl_task tsk2
             INNER JOIN tbl_tasktemplate tt2
                ON tsk2.col_id2 = tt2.col_id
             INNER JOIN tbl_tasktemplate tt
                ON tt2.col_parentttid = tt.col_id
             INNER JOIN tbl_task tsk
                ON tt.col_id = tsk.col_id2
             WHERE tsk2.col_id = v_TaskId
               AND tsk2.col_transactionid = v_TransactionId
               AND tsk.col_transactionid = v_TransactionId
               AND tsk3.col_id = tsk2.col_id)
     WHERE tsk3.col_id = v_TaskId;
    -----------------------------------------------------------------------------------------------------
    v_result := f_DCM_generateTaskId(affectedRows => v_affectedRows, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, prefix => v_prefix, recordid => v_TaskId, taskid => v_BusTaskId);
  
    UPDATE tbl_task SET col_taskid = v_BusTaskId WHERE col_id = v_TaskId;
  
    -----------------------------------------------------------------------------------------------------
    --Appends col_id to the task name--------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------
    --v_result := f_DCM_generateTaskName(TaskId => v_TaskId);
    -----------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------
  
    IF lower(rec.col_name) = 'root' THEN
      UPDATE tbl_task SET col_taskdict_tasksystype = v_adhocTaskTypeId, col_taskdict_executionmethod = v_adhocExecMehodId WHERE col_id = v_TaskId;
    END IF;
  
    BEGIN
      SELECT tst.col_stateconfigtasksystype INTO v_stateConfigId FROM tbl_task tsk INNER JOIN tbl_dict_tasksystype tst ON tsk.col_taskdict_tasksystype = tst.col_id WHERE tsk.col_id = v_TaskId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_stateConfigId := NULL;
    END;
    v_stateAssigned := f_DCM_getTaskAssignedState2(StateConfigId => v_stateConfigId);
    v_stateStarted  := f_DCM_getTaskStartedState2(StateConfigId => v_StateConfigId);
    v_stateNew      := f_DCM_getTaskNewState2(StateConfigId => v_stateConfigId);
    --CREATE ACCOMPANYING WORKITEM FOR THE TASK
    IF (lower(rec.col_name) = 'root') AND (v_workbasketid IS NOT NULL) THEN
      v_activitycode := v_stateAssigned;
    ELSIF (lower(rec.col_name) = 'root') AND (v_workbasketid IS NULL) THEN
      --v_activitycode := v_stateStarted;
      v_activitycode := v_stateInProgress; --//DCMS-327
    ELSE
      v_activitycode := v_stateNew;
    END IF;
    v_workflowcode := v_TokenDomain || '_' || v_workflow;
    v_result       := f_TSKW_createWorkitem2(ActivityCode => v_activitycode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, TaskId => v_TaskId, WorkflowCode => v_workflowcode);
  
    v_Result := f_DCM_createTaskDateEvent(NAME => 'DATE_TASK_CREATED', TaskId => v_TaskId);
    v_Result := f_DCM_createTaskDateEvent(NAME => 'DATE_TASK_MODIFIED', TaskId => v_TaskId);
  
    IF lower(rec.col_name) = 'root' THEN
      v_result := f_DCM_copyTaskStateInitTask(owner => v_owner, TaskId => v_TaskId);
    ELSE
      v_result := f_DCM_copyTaskStateInitTmpl(owner => v_owner, TaskId => v_TaskId);
    END IF;
  
    -- CREATE A TASK EXT RECORD FOR ATTACHED PROCEDURE
    BEGIN
      SELECT col_customdataprocessor INTO v_customdataprocessor FROM tbl_procedure WHERE col_id = v_attachedproc;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_customdataprocessor := NULL;
    END;
    IF v_customdataprocessor IS NULL AND v_TaskExtId IS NULL THEN
      UPDATE tbl_task SET col_draft = v_draft WHERE col_id = v_TaskId;
      :TaskId := v_TaskId;
      INSERT INTO tbl_taskext (col_taskexttask) VALUES (v_TaskId);
      SELECT gen_tbl_taskext.currval INTO v_TaskExtId FROM dual;
    ELSIF v_customdataprocessor IS NOT NULL AND v_TaskExtId IS NULL THEN
      UPDATE tbl_task SET col_draft = v_draft WHERE col_id = v_TaskId;
      :TaskId     := v_TaskId;
      v_TaskExtId := f_dcm_invokeCustomDataProc(Input => v_Input, ProcessorName => v_customdataprocessor, TaskId => v_TaskId);
      SELECT gen_tbl_task.currval INTO v_TaskIdCustom FROM dual;
    END IF;
  
    --ADD HISTORY RECORD FOR TASK
    v_result := f_DCM_createTaskHistory(IsSystem => 0, MessageCode => 'TaskCreatedInState', TaskId => v_TaskId);
    IF (nvl(v_workbasketid, 0) > 0) THEN
      v_result := f_DCM_createTaskHistory(IsSystem => 0, MessageCode => 'TaskAssigned', TaskId => v_TaskId);
    END IF;
  END LOOP;
  IF v_TaskIdCustom IS NOT NULL THEN
    UPDATE tbl_task
       SET col_taskorder =
           (SELECT MAX(col_taskorder) + 1 FROM tbl_task WHERE col_parentid = (SELECT col_parentid FROM tbl_task WHERE col_id = v_TaskIdCustom))
     WHERE col_id = v_TaskIdCustom;
  END IF;

  v_result := f_DBG_createDBGTrace(CaseId   => v_CaseId,
                                   Location => 'DCM_insertAdhocProcPosFn after tasks created',
                                   Message  => 'Adhoc procedure ' || v_attachedproccode || ' tasks are created and attached to case ' || to_char(v_CaseId),
                                   Rule     => 'DCM_insertAdhocProcPosFn',
                                   TaskId   => NULL);

  IF (v_position = 'append') THEN
    UPDATE tbl_task tsk
       SET col_parentid = v_sourceid
     WHERE col_parentid IS NULL
       AND col_transactionid = v_TransactionId;
  ELSIF v_position = 'insert_before' OR (v_position = 'insert_after') THEN
    UPDATE tbl_task tsk
       SET col_parentid =
           (SELECT col_parentid FROM tbl_task WHERE col_id = v_sourceid)
     WHERE col_parentid IS NULL
       AND col_transactionid = v_TransactionId;
  END IF;
  IF (v_position = 'insert_before') THEN
    SELECT MAX(col_taskorder)
      INTO v_count
      FROM tbl_task
     WHERE col_parentid = (SELECT col_parentid FROM tbl_task WHERE col_id = v_sourceId)
       AND col_transactionid = v_TransactionId;
    UPDATE tbl_task
       SET col_taskorder = col_taskorder + 1
     WHERE col_parentid = (SELECT col_parentid FROM tbl_task WHERE col_id = v_sourceId)
       AND nvl(col_transactionid, 0) <> v_TransactionId
       AND col_taskorder >= v_taskorder;
  ELSIF v_position = 'insert_after' THEN
    SELECT MAX(col_taskorder)
      INTO v_count
      FROM tbl_task
     WHERE col_parentid = (SELECT col_parentid FROM tbl_task WHERE col_id = v_sourceId)
       AND col_transactionid = v_TransactionId;
    UPDATE tbl_task
       SET col_taskorder = col_taskorder + 1
     WHERE col_parentid = (SELECT col_parentid FROM tbl_task WHERE col_id = v_sourceId)
       AND col_id <> v_sourceid
       AND nvl(col_transactionid, 0) <> v_TransactionId
       AND col_taskorder >= v_taskorder;
  END IF;

  v_result := f_DCM_copySlaEventAdhocProc2(Transactionid => v_TransactionId);
  v_result := f_DBG_createDBGTrace(CaseId   => v_CaseId,
                                   Location => 'DCM_insertAdhocProcPosFn after SLA events copied',
                                   Message  => 'SLA events are copied to adhoc procedure ' || v_attachedproccode,
                                   Rule     => 'DCM_insertAdhocProcPosFn',
                                   TaskId   => NULL);

  v_result := f_DCM_CopyTaskDepAdhocProc2(TransactionId => v_TransactionId);
  v_result := f_DBG_createDBGTrace(CaseId   => v_CaseId,
                                   Location => 'DCM_insertAdhocProcPosFn after task dependencies copied',
                                   Message  => 'Task dependencies are copied to adhoc procedure ' || v_attachedproccode,
                                   Rule     => 'DCM_insertAdhocProcPosFn',
                                   TaskId   => NULL);

  v_result := f_DCM_CopyTaskEventAdhocPrc2(TransactionId => v_TransactionId);
  v_result := f_DBG_createDBGTrace(CaseId   => v_CaseId,
                                   Location => 'DCM_insertAdhocProcPosFn after taskevents copied',
                                   Message  => 'Task events are copied to adhoc procedure ' || v_attachedproccode,
                                   Rule     => 'DCM_insertAdhocProcPosFn',
                                   TaskId   => NULL);

  /*
  v_result := f_DCM_CopyRuleParamAdhocPrc2(TransactionId => v_TransactionId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_insertAdhocProcPosFn after rule parameters copied',
                                   Message => 'Rule parameters are copied to adhoc procedure ' || v_attachedproccode, Rule => 'DCM_insertAdhocProcPosFn', TaskId => null);
  */

  v_parentid2 := -1;
  FOR rec IN (SELECT sys_connect_by_path(col_id, '/') AS Path,
                     col_parentid,
                     col_id,
                     col_taskorder
                FROM tbl_task
               START WITH col_parentid = v_parentid
              CONNECT BY PRIOR col_id = col_parentid
               ORDER BY col_parentid,
                        col_taskorder,
                        col_id) LOOP
    IF rec.col_parentid <> v_parentid2 THEN
      v_parentid2 := rec.col_parentid;
      v_count     := 1;
    END IF;
    UPDATE tbl_task SET col_taskorder = v_count WHERE col_id = rec.col_id;
    v_count := v_count + 1;
  END LOOP;

  --copy participants
  v_Result := f_DCM_copyParticipantCommon(CASEID        => v_caseid,
                                          CASESYSTYPEID => NULL,
                                          ERRORCODE     => v_ErrorCode,
                                          ERRORMESSAGE  => v_ErrorMessage,
                                          ID            => NULL,
                                          MILESTONEID   => NULL,
                                          PROCEDUREID   => v_attachedproc);
  IF nvl(v_ErrorCode, 0) NOT IN (0, 200) THEN
    :ErrorCode    := v_ErrorCode;
    :ErrorMessage := 'During copy of participants there were errors: ' || v_ErrorMessage;
    RETURN - 1;
  END IF;

  --ADD DOCUMENTS
  IF v_preventDocFolderCreate = 0 THEN
    V_Parentfolder_Id := f_DOC_getDefaultDocFolder(CaseId => v_CaseId, DocFolderType => v_CaseFrom);
    IF :DocumentsURLs IS NOT NULL AND :DocumentsNames IS NOT NULL THEN
      OPEN urls(:DocumentsURLs);
      OPEN file_names(:DocumentsNames);
      LOOP
        FETCH urls
          INTO v_sv_url;
        FETCH file_names
          INTO v_sv_filename;
        EXIT WHEN urls%NOTFOUND;
        BEGIN
          v_Result := f_doc_adddocfn(NAME         => v_sv_filename,
                                     Description  => NULL,
                                     Url          => v_sv_url,
                                     ScanLocation => NULL,
                                     DocId        => v_result,
                                     DocTypeId    => NULL,
                                     FolderId     => V_Parentfolder_Id,
                                     CaseId       => v_caseid,
                                     CaseTypeId   => NULL,
                                     ErrorCode    => v_ErrorCode,
                                     ErrorMessage => v_ErrorMessage);
        EXCEPTION
          WHEN OTHERS THEN
            :ErrorCode := v_ErrorCode;
            IF (v_ErrorMessage = '') THEN
              v_ErrorMessage := 'During insert of the following records there were errors: ';
            END IF;
            :ErrorMessage := v_ErrorMessage;
        END;
        :ErrorCode    := v_ErrorCode;
        :ErrorMessage := v_ErrorMessage;
        IF nvl(v_ErrorCode, 0) NOT IN (0, 200) THEN
          RETURN - 1;
        END IF;
      END LOOP;
      CLOSE urls;
      CLOSE file_names;
    END IF;
  END IF;

  v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
  v_result := f_dcm_casequeueproc5();
  v_result := f_DBG_createDBGTrace(CaseId   => v_CaseId,
                                   Location => 'DCM_insertAdhocProcPosFn after queue processing',
                                   Message  => 'Adhoc procedure ' || v_attachedproccode || ' after queue processing',
                                   Rule     => 'DCM_insertAdhocProcPosFn',
                                   TaskId   => NULL);

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => NULL, ProcedureId => v_attachedproc);
  v_result       := f_DBG_createDBGTrace(CaseId   => v_CaseId,
                                         Location => 'DCM_insertAdhocProcPosFn end',
                                         Message  => 'Adhoc procedure ' || v_attachedproccode || ' is created and attached to case',
                                         Rule     => 'DCM_insertAdhocProcPosFn',
                                         TaskId   => NULL);

  /*--
      CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -INSERT_ADHOC_PROC- AND
      EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'INSERT_ADHOC_PROC',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'AFTER',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => v_attachedproc,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);

  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg, issystem => 0, MESSAGE => 'Action Common event(s)', messagecode => 'CommonEvent', targetid => v_sourceid, targettype => 'TASK');
  END IF;

  IF NVL(v_errorcode, 0) <> 0 THEN
    GOTO cleanup;
  END IF;

  :ErrorCode    := 200;
  :ErrorMessage := 'Success';
  RETURN 0;

  <<cleanup>>
  :ErrorCode    := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  RETURN - 1;
END;
