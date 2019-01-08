DECLARE
  v_result              NUMBER;
  v_TaskId              INTEGER;
  v_TaskExtId           INTEGER;
  v_CaseId              INTEGER;
  v_BusTaskId           NVARCHAR2(255);
  v_affectedRows        INTEGER;
  v_ErrorCode           NUMBER;
  v_ErrorMessage        NCLOB;
  v_sourceid            INTEGER;
  v_parentid            INTEGER;
  v_depth               INTEGER;
  v_TokenDomain         NVARCHAR2(255);
  v_workflow            NVARCHAR2(255);
  v_activitycode        NVARCHAR2(255);
  v_workflowcode        NVARCHAR2(255);
  v_stateStarted        NVARCHAR2(255);
  v_stateAssigned       NVARCHAR2(255);
  v_stateNew            NVARCHAR2(255);
  v_createdby           NVARCHAR2(255);
  v_createddate         DATE;
  v_modifiedby          NVARCHAR2(255);
  v_modifieddate        DATE;
  v_owner               NVARCHAR2(255);
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
  v_tasksystype         NVARCHAR2(255);
  v_tasksystypeid       INTEGER;
  v_stateconfigid       INTEGER;
  v_DateAssigned        DATE;
  v_prefix              NVARCHAR2(255);
  v_workbasketid        INTEGER;
  v_position            NVARCHAR2(255);
  v_adhocExecMehodId    INTEGER;
  v_customdataprocessor NVARCHAR2(255);
  v_Input               NCLOB;
  v_validationresult    NUMBER;
  v_historymsg          NCLOB;
  v_Attributes          NVARCHAR2(4000);
  v_outData CLOB;
  
BEGIN
  v_CaseId           := :CaseId;
  v_createdby        := SYS_CONTEXT('CLIENTCONTEXT', 'AccessSubject');
  v_createddate      := SYSDATE;
  v_modifiedby       := v_createdby;
  v_modifieddate     := v_createddate;
  v_owner            := v_createdby;
  v_sourceid         := :sourceid;
  v_name             := :NAME;
  v_tasksystype      := :TaskSysType;
  v_description      := :Description;
  v_required         := 0;
  v_leaf             := 1;
  v_icon             := :Icon;
  v_iconcls          := v_icon;
  v_enabled          := 1;
  v_hoursworked      := NULL;
  v_systemtype       := NULL;
  v_DateAssigned     := v_createddate;
  v_prefix           := 'TASK';
  v_workbasketid     := :WorkbasketId;
  v_position         := :Position;
  v_Input            := :Input;
  v_validationresult := NULL;
  v_historymsg       := NULL;
  v_outData      := NULL;
  
  IF v_Input IS NULL THEN
    v_Input := '<CustomData><Attributes></Attributes></CustomData>';
  END IF;
  v_TokenDomain := f_UTIL_getDomainFn();
  v_workflow    := f_DCM_getTaskWorkflowCodeFn();
  --FIND TASKSYSTYPE AND STATECONFIGID FOR TASK TYPE
  IF v_tasksystype IS NOT NULL THEN
    BEGIN
      SELECT col_id INTO v_tasksystypeid FROM tbl_dict_tasksystype WHERE lower(col_code) = lower(v_tasksystype);
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        IF :TaskSysTypeId IS NOT NULL THEN
          v_tasksystypeid := :TaskSysTypeId;
        ELSE
          v_tasksystypeid := NULL;
        END IF;
    END;
  ELSIF :TaskSysTypeId IS NOT NULL THEN
    v_tasksystypeid := :TaskSysTypeId;
  ELSE
    v_tasksystypeid := NULL;
  END IF;
  IF v_name IS NULL AND v_tasksystypeid IS NOT NULL THEN
    BEGIN
      SELECT col_code INTO v_name FROM tbl_dict_tasksystype WHERE col_id = v_tasksystypeid;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_name := NULL;
    END;
  END IF;
  BEGIN
    SELECT col_stateconfigtasksystype INTO v_stateconfigid FROM tbl_dict_tasksystype WHERE col_id = v_tasksystypeid;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_stateconfigid := NULL;
  END;
  --v_stateStarted := f_dcm_getTaskStartedState2(v_stateconfigid);//DCMS-324
  v_stateAssigned := f_dcm_getTaskAssignedState2(v_stateconfigid);
  v_stateNew      := f_DCM_getTaskNewState2(v_stateconfigid);
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
        GOTO cleanup;
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
      GOTO cleanup;
  END;
  BEGIN
    SELECT col_id INTO v_adhocExecMehodId FROM tbl_dict_executionmethod WHERE lower(col_code) = 'manual';
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_adhocExecMehodId := NULL;
      v_ErrorCode        := 101;
      v_ErrorMessage     := 'Adhoc execution method not found';
      GOTO cleanup;
  END;
  IF v_position IS NULL THEN
    v_position := 'append';
  END IF;
  v_Attributes := '<SourceTaskId>' || TO_CHAR(v_sourceid) || '</SourceTaskId>' || '<Position>' || TO_CHAR(v_position) || '</Position>' || '<ParentId>' || TO_CHAR(v_parentid) || '</ParentId>' ||
                  '<TaskWorkflow>' || TO_CHAR(v_workflow) || '</TaskWorkflow>';

  /*--
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -INSERT_ADHOC_TASK-
     AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;
  v_result           := f_DCM_processCommonEvent(InData           => NULL,
                                                 OutData          => v_outData,   
                                                 Attributes       => v_Attributes,
                                                 code             => NULL,
                                                 caseid           => v_caseid,
                                                 casetypeid       => NULL,
                                                 commoneventtype  => 'INSERT_ADHOC_TASK',
                                                 errorcode        => v_errorcode,
                                                 errormessage     => v_errormessage,
                                                 eventmoment      => 'BEFORE',
                                                 eventtype        => 'VALIDATION',
                                                 historymessage   => v_historymsg,
                                                 procedureid      => NULL,
                                                 taskid           => NULL,
                                                 tasktypeid       => v_tasksystypeid,
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
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -INSERT_ADHOC_TASK-
     AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;
  v_result           := f_DCM_processCommonEvent(InData           => NULL,
                                                 OutData          => v_outData,   
                                                 Attributes       => v_Attributes,
                                                 code             => NULL,
                                                 caseid           => v_caseid,
                                                 casetypeid       => NULL,
                                                 commoneventtype  => 'INSERT_ADHOC_TASK',
                                                 errorcode        => v_errorcode,
                                                 errormessage     => v_errormessage,
                                                 eventmoment      => 'BEFORE',
                                                 eventtype        => 'ACTION',
                                                 historymessage   => v_historymsg,
                                                 procedureid      => NULL,
                                                 taskid           => NULL,
                                                 tasktypeid       => v_tasksystypeid,
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
        GOTO cleanup;
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
        GOTO cleanup;
    END;
    UPDATE tbl_task
       SET col_taskorder = col_taskorder + 1
     WHERE col_parentid = (SELECT col_parentid FROM tbl_task WHERE col_id = v_sourceId)
       AND col_taskorder >= v_taskorder;
  
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
        GOTO cleanup;
    END;
    UPDATE tbl_task
       SET col_taskorder = col_taskorder + 1
     WHERE col_parentid = (SELECT col_parentid FROM tbl_task WHERE col_id = v_sourceId)
       AND col_taskorder >= v_taskorder;
  
  END IF;
  INSERT INTO tbl_task
    (col_createdby,
     col_createddate,
     col_modifiedby,
     col_modifieddate,
     col_owner,
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
     col_taskppl_workbasket,
     col_isadhoc)
  VALUES
    (v_createdby,
     v_createddate,
     v_modifiedby,
     v_modifieddate,
     v_owner,
     v_parentid,
     v_description,
     v_name,
     v_required,
     v_depth,
     v_leaf,
     v_icon,
     v_iconcls,
     v_taskorder,
     (SELECT col_casetask FROM tbl_task WHERE col_id = v_TaskId),
     v_enabled,
     v_hoursworked,
     v_systemtype,
     v_DateAssigned,
     v_tasksystypeid,
     v_adhocExecMehodId,
     v_workbasketid,
     1);

  SELECT gen_tbl_task.currval INTO v_TaskId FROM dual;

  --according to DCM-6231 
  --v_result := f_DCM_generateTaskName(TaskId => v_TaskId);
  v_result := f_DCM_generateTaskId(affectedRows => v_affectedRows, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, prefix => v_prefix, recordid => v_TaskId, taskid => v_BusTaskId);
  UPDATE tbl_task SET col_taskid = v_BusTaskId, col_id2 = v_TaskId WHERE col_id = v_TaskId;

  -- CREATE A TASK EXT RECORD FOR EACH TASK
  BEGIN
    SELECT col_customdataprocessor INTO v_customdataprocessor FROM tbl_dict_tasksystype WHERE col_id = v_tasksystypeid;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_customdataprocessor := NULL;
  END;
  IF v_customdataprocessor IS NULL THEN
    INSERT INTO tbl_taskext (col_taskexttask) VALUES (v_TaskId);
  
    SELECT gen_tbl_taskext.currval INTO v_TaskExtId FROM dual;
  
  ELSE
    v_TaskExtId := f_dcm_invokeCustomDataProc(Input => v_Input, ProcessorName => v_customdataprocessor, TaskId => v_TaskId);
  END IF;
  --CREATE ACCOMPANYING WORKITEM FOR THE TASK
  v_activitycode := v_stateNew;
  v_workflowcode := v_TokenDomain || '_' || v_workflow;
  v_result       := f_TSKW_createWorkitem2(ActivityCode => v_activitycode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, TaskId => v_TaskId, WorkflowCode => v_workflowcode);
  :TaskId        := v_TaskId;
  :TaskExtId     := v_TaskExtId;
  :TaskName      := v_BusTaskId;
  --v_Result := f_DCM_addTaskDateEventList(TaskId => v_TaskId, state => v_activitycode);
  v_result := f_DCM_CopyTaskStateInitTask(owner => v_owner, TaskId => v_TaskId);
  v_result := f_DCM_CopyTaskEventAdhocTsk(TaskId => v_TaskId);
  v_result := f_DCM_CopyRuleParameterTask(TaskId => v_TaskId);
  --ADD HISTORY RECORD FOR TASK
  v_result := f_DCM_createTaskHistory(IsSystem => 0, MessageCode => 'TaskCreatedInState', TaskId => v_TaskId);
  IF (nvl(v_workbasketid, 0) > 0) THEN
    v_result := f_DCM_createTaskHistory(IsSystem => 0, MessageCode => 'TaskAssigned', TaskId => v_TaskId);
  END IF;
  v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
  v_result := f_dcm_casequeueproc5();

  /*--
      CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -INSERT_ADHOC_TASK- AND
      EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,   
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'INSERT_ADHOC_TASK',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'AFTER',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => v_taskid,
                                       tasktypeid       => v_tasksystypeid,
                                       validationresult => v_validationresult);

  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg, issystem => 0, MESSAGE => 'Action Common event(s)', messagecode => 'CommonEvent', targetid => v_sourceid, targettype => 'TASK');
  END IF;
  IF NVL(v_errorcode, 0) <> 0 THEN
    GOTO cleanup;
  END IF;
  v_ErrorCode    := NULL;
  v_ErrorMessage := NULL;
  ErrorCode      := v_ErrorCode;
  ErrorMessage   := v_ErrorMessage;
  RETURN 0;
  <<cleanup>>
  ErrorCode    := v_ErrorCode;
  ErrorMessage := v_ErrorMessage;
  RETURN - 1;
END;
