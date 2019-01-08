declare
  v_result        number;
  v_TaskId        Integer;
  v_StartTaskId   Integer;
  v_CaseId        Integer;
  v_BusTaskId     nvarchar2(255);
  v_affectedRows  integer;
  v_ErrorCode     number;
  v_ErrorMessage  nvarchar2(255);
  v_sourceid      Integer;
  v_parentid      Integer;
  v_parentid2     Integer;
  v_depth         Integer;
  v_TokenDomain   nvarchar2(255);
  v_workflow      nvarchar2(255);
  v_activitycode  nvarchar2(255);
  v_workflowcode  nvarchar2(255);
  v_stateClosed   nvarchar2(255);
  v_stateNew      nvarchar2(255);
  v_stateStarted  nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_createdby     nvarchar2(255);
  v_createddate   date;
  v_modifiedby    nvarchar2(255);
  v_modifieddate  date;
  v_owner         nvarchar2(255);
  v_name          nvarchar2(255);
  v_description   nclob;
  v_required      number;
  v_leaf          Integer;
  v_icon          nvarchar2(255);
  v_iconcls       nvarchar2(255);
  v_taskorder     Integer;
  v_enabled       number;
  v_hoursworked   number;
  v_systemtype    nvarchar2(255);
  v_tasksystypeid Integer;
  v_DateAssigned  date;
  v_prefix        nvarchar2(255);
  v_workbasketid  Integer;
  v_position      nvarchar2(255);
  v_attachedproc  Integer;
  v_count         Integer;
  v_adhocTaskTypeId Integer;
  v_adhocExecMehodId Integer;

begin
  v_createdby := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  v_owner := v_createdby;
  v_sourceid := :sourceid;
  v_name := :RootName;
  v_tasksystypeid := null;
  v_description := null;
  v_required := 0;
  v_leaf := 1;
  v_icon := null;
  v_iconcls := v_icon;
  v_enabled := 1;
  v_hoursworked := null;
  v_systemtype := null;
  v_DateAssigned := v_createddate;
  v_prefix := 'TASK-';
  v_workbasketid := :WorkbasketId;
  v_position := :Position;
  v_attachedproc := :AttachedProcedure;
  :ErrorCode := 0;
  :ErrorMessage := null;

  v_TokenDomain := f_UTIL_getDomainFn();
  v_workflow := f_DCM_getTaskWorkflowCodeFn();

  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  v_stateClosed := f_dcm_getTaskClosedState();

  begin
    select col_id, col_casetask, col_depth, col_id
      into v_TaskId, v_CaseId, v_depth, v_parentid
      from tbl_task
      where col_id = v_sourceId;
    exception
      when NO_DATA_FOUND then
        v_TaskId := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Source task not found';
        :ErrorCode := v_ErrorCode;
        :ErrorMessage := v_ErrorMessage;
        return -1;
  end;

  begin
    select col_id into v_adhocTaskTypeId from tbl_dict_tasksystype where lower(col_code) = 'adhoc';
    exception
      when NO_DATA_FOUND then
        v_adhocTaskTypeId := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Adhoc task type not found';
        :ErrorCode := v_ErrorCode;
        :ErrorMessage := v_ErrorMessage;
        return -1;
  end;
  
  begin
    select col_id into v_adhocExecMehodId from tbl_dict_executionmethod where lower(col_code) = 'manual';
    exception
      when NO_DATA_FOUND then
        v_adhocExecMehodId := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Adhoc execution method not found';
        :ErrorCode := v_ErrorCode;
        :ErrorMessage := v_ErrorMessage;
        return -1;
  end;

  if v_position is null then
    v_position := 'append';
  end if;

  if v_position = 'append' then
    begin
      select max(col_taskorder) + 1
        into v_taskorder
        from tbl_task
        where col_parentid = v_sourceId
        and col_casetask = v_CaseId;
      exception
        when NO_DATA_FOUND then
          v_taskorder := null;
          v_ErrorCode := 101;
          v_ErrorMessage := 'Parent task not found';
          :ErrorCode := v_ErrorCode;
          :ErrorMessage := v_ErrorMessage;
          return -1;
    end;
    if (v_taskorder is null or v_taskorder = 0) then
      v_taskorder := 1;
    end if;
    v_depth := v_depth + 1;
  elsif v_position = 'insert_before' then
    begin
      select col_parentid, col_taskorder
        into v_parentid, v_taskorder
        from tbl_task
        where col_id = v_sourceId
        and col_casetask = v_CaseId;
      exception
        when NO_DATA_FOUND then
          v_taskorder := null;
          v_ErrorCode := 101;
          v_ErrorMessage := 'Source task not found';
          :ErrorCode := v_ErrorCode;
          :ErrorMessage := v_ErrorMessage;
          return -1;
    end;
  elsif v_position = 'insert_after' then
    begin
      select col_parentid, col_taskorder + 1
        into v_parentid, v_taskorder
        from tbl_task
        where col_id = v_sourceId
        and col_casetask = v_CaseId;
      exception
        when NO_DATA_FOUND then
          v_taskorder := null;
          v_ErrorCode := 101;
          v_ErrorMessage := 'Source task not found';
          :ErrorCode := v_ErrorCode;
          :ErrorMessage := v_ErrorMessage;
          return -1;
    end;
    update tbl_task set col_taskorder = col_taskorder + 1 where col_parentid = (select col_parentid from tbl_task where col_id = v_sourceId) and col_taskorder > v_taskorder;
  end if;

  select gen_tbl_task.nextval - 1 into v_StartTaskId from dual;
  for rec in (select col_id, col_parentttid,
            col_description, col_name, col_depth, col_leaf, col_icon, col_iconcls, col_taskorder,
            col_tasktmpldict_tasksystype, col_execmethodtasktemplate, col_processorcode
            from tbl_tasktemplate
            where col_proceduretasktemplate = v_attachedproc)
  loop
    if rec.col_name <> 'root' then
      v_name := rec.col_name;
    end if;
    insert into tbl_task
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
                 col_taskppl_workbasket)
    values
                 (v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner, rec.col_id, v_parentid,
                  rec.col_description, v_name, v_required, rec.col_depth + v_depth, rec.col_leaf, rec.col_icon, rec.col_iconcls, rec.col_taskorder + v_taskorder - 1,
                  (select col_casetask from tbl_task where col_id = v_TaskId),
                  v_enabled, v_hoursworked, v_systemtype, v_DateAssigned,
                  rec.col_tasktmpldict_tasksystype, rec.col_execmethodtasktemplate, rec.col_processorcode, v_workbasketid);
    select gen_tbl_task.currval into v_TaskId from dual;
    v_result := f_DCM_generateTaskId(affectedRows => v_affectedRows, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                     prefix => v_prefix, recordid => v_TaskId, taskid => v_BusTaskId);
  
    update tbl_task set col_taskid = v_BusTaskId where col_id = v_TaskId;

    if rec.col_name = 'root' then
      update tbl_task set col_taskdict_tasksystype = v_adhocTaskTypeId, col_taskdict_executionmethod = v_adhocExecMehodId where col_id = v_TaskId;
    end if;

    -- CREATE A TASK EXT RECORD FOR EACH TASK
    insert into tbl_taskext
                (col_taskexttask)
    values      (v_TaskId);

    --CREATE ACCOMPANYING WORKITEM FOR THE TASK
    if (rec.col_name = 'root') and (v_workbasketid is not null) then
      v_activitycode := v_stateAssigned;
    elsif (rec.col_name = 'root') and (v_workbasketid is null) then
      v_activitycode := v_stateStarted;
    else
      v_activitycode := v_stateNew;
    end if;
    v_workflowcode := v_TokenDomain || '_' || v_workflow;
    v_result := f_TSKW_createWorkitem(AccessSubjectCode => v_createdby, ActivityCode => v_activitycode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                       Owner => v_owner, TaskId => v_TaskId, TOKEN_USERACCESSSUBJECT => v_createdby, WorkflowCode => v_workflowcode);
    :TaskId := v_TaskId;

    v_Result := f_DCM_createTaskDateEvent(Name => 'DATE_TASK_CREATED', TaskId => v_TaskId);
    v_Result := f_DCM_createTaskDateEvent(Name => 'DATE_TASK_MODIFIED', TaskId => v_TaskId);

    if rec.col_name = 'root' then
      v_result := f_DCM_copyTaskStateInitTask(owner => v_owner, TaskId => v_TaskId);
    else
      v_result := f_DCM_copyTaskStateInitTmpl(owner => v_owner, TaskId => v_TaskId);
    end if;

    --ADD HISTORY RECORD FOR TASK
    v_result := f_DCM_addTaskHistory(Status => 1, TaskId => v_TaskId);
  end loop;
  
  update tbl_task tsk3
    set col_parentid =
    (select tsk.col_id
      from tbl_task tsk2
      inner join tbl_tasktemplate tt2 on tsk2.col_id2 = tt2.col_id
      inner join tbl_tasktemplate tt on tt2.col_parentttid = tt.col_id
      inner join tbl_task tsk on tt.col_id = tsk.col_id2
      where tsk2.col_id > v_StartTaskId and tsk.col_id > v_StartTaskId and tsk3.col_id = tsk2.col_id)
      where tsk3.col_id > v_StartTaskId;
  if (v_position = 'append') then
    update tbl_task tsk
      set col_parentid = v_sourceid where col_parentid is null and col_id > v_StartTaskId;
  elsif v_position = 'insert_before' or (v_position = 'insert_after') then
    update tbl_task tsk
      set col_parentid = (select col_parentid from tbl_task where col_id = v_sourceid) where col_parentid is null and col_id > v_StartTaskId;
  end if;
  if (v_position = 'insert_before') then
    select max(col_taskorder) into v_count from tbl_task
      where col_parentid = (select col_parentid from tbl_task where col_id = v_sourceId) and col_id > v_StartTaskId;
    update tbl_task set col_taskorder = col_taskorder + 1
      where col_parentid = (select col_parentid from tbl_task where col_id = v_sourceId) and col_id <= v_StartTaskId and col_taskorder >= v_taskorder;
  elsif v_position = 'insert_after' then
    select max(col_taskorder) into v_count from tbl_task
      where col_parentid = (select col_parentid from tbl_task where col_id = v_sourceId) and col_id > v_StartTaskId;
    update tbl_task set col_taskorder = col_taskorder + 1
      where col_parentid = (select col_parentid from tbl_task where col_id = v_sourceId) and col_id <> v_sourceid and col_id <= v_StartTaskId and col_taskorder >= v_taskorder;
  end if;

  v_result := f_DCM_copySlaEventAdhocProc(StartTaskid => v_StartTaskId);

  v_result := f_DCM_CopyTaskDepAdhocProc(StartTaskId => v_StartTaskId);

  v_result := f_DCM_CopyTaskEventAdhocPrc(StartTaskId => v_StartTaskId);
  
  v_result := f_DCM_CopyRuleParamAdhocPrc(StartTaskId => v_StartTaskId);

  v_parentid2 := -1;
  for rec in (select sys_connect_by_path(col_id, '/') as Path, col_parentid, col_id, col_taskorder
                from tbl_task
                start with col_parentid = v_parentid
                connect by prior col_id =  col_parentid
                order by col_parentid, col_taskorder, col_id)
  loop
    if rec.col_parentid <> v_parentid2 then
      v_parentid2 := rec.col_parentid;
      v_count := 1;
    end if;
    update tbl_task set col_taskorder = v_count where col_id = rec.col_id;
    v_count := v_count + 1;
  end loop;

  v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
  v_result := f_dcm_casequeueproc5();

end;