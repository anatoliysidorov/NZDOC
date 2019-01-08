declare
  v_result        number;
  v_TaskId        Integer;
  v_TaskExtId	  Integer;
  v_CaseId        Integer;
  v_BusTaskId     nvarchar2(255);
  v_affectedRows  integer;
  v_ErrorCode     number;
  v_ErrorMessage  nvarchar2(255);
  v_sourceid      Integer;
  v_parentid      Integer;
  v_depth         Integer;
  v_TokenDomain   nvarchar2(255);
  v_workflow      nvarchar2(255);
  v_activitycode  nvarchar2(255);
  v_workflowcode  nvarchar2(255);
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
  v_tasksystype   nvarchar2(255);
  v_tasksystypeid Integer;
  v_stateconfigid Integer;
  v_DateAssigned  date;
  v_prefix        nvarchar2(255);
  v_workbasketid  Integer;
  v_position      nvarchar2(255);
  v_adhocExecMehodId Integer;
  v_customdataprocessor nvarchar2(255);
  v_Input nclob;

begin
  v_CaseId := :CaseId;
  v_createdby := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  v_owner := v_createdby;
  v_sourceid := :sourceid;
  v_name := :name;
  v_tasksystype := :TaskSysType;
  v_description := :Description;
  v_required := 0;
  v_leaf := 1;
  v_icon := :Icon;
  v_iconcls := v_icon;
  v_enabled := 1;
  v_hoursworked := null;
  v_systemtype := null;
  v_DateAssigned := v_createddate;
  v_prefix := 'TASK-';
  v_workbasketid := :WorkbasketId;
  v_position := :Position;
  v_Input := :Input;
  if v_Input is null then
    v_Input := '<CustomData><Attributes></Attributes></CustomData>';
  end if;

  v_TokenDomain := f_UTIL_getDomainFn();
  v_workflow := f_DCM_getTaskWorkflowCodeFn();

  --FIND TASKSYSTYPE AND STATECONFIGID FOR TASK TYPE
  if v_tasksystype is not null then
    begin
      select col_id into v_tasksystypeid from tbl_dict_tasksystype where lower(col_code) = lower(v_tasksystype);
      exception
      when NO_DATA_FOUND then
      if :TaskSysTypeId is not null then
        v_tasksystypeid := :TaskSysTypeId;
      else
        v_tasksystypeid := null;
      end if;
    end;
  elsif :TaskSysTypeId is not null then
    v_tasksystypeid := :TaskSysTypeId;
  else
    v_tasksystypeid := null;
  end if;
  begin
    select col_stateconfigtasksystype into v_stateconfigid from tbl_dict_tasksystype where col_id = v_tasksystypeid;
    exception
    when NO_DATA_FOUND then
      v_stateconfigid := null;
  end;

  v_stateStarted := f_dcm_getTaskStartedState2(v_stateconfigid);
  v_stateAssigned := f_dcm_getTaskAssignedState2(v_stateconfigid);

  --IF SOURCE TASK IS NOT DEFINED APPEND ADHOC TASK TO CASE ROOT TASK
  if v_sourceid is null then
    v_position := 'append';
  end if;

  --FIND SOURCE TASK IF NOT DEFINED
  if v_sourceid is null then
    begin
      select col_id into v_sourceid from tbl_task where col_casetask = v_CaseId and nvl(col_parentid,0) = 0;
      exception
      when NO_DATA_FOUND then
        v_sourceid := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Source task not found';
        return;
    end;
  end if;

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
        return;
  end;

  begin
    select col_id into v_adhocExecMehodId from tbl_dict_executionmethod where lower(col_code) = 'manual';
    exception
      when NO_DATA_FOUND then
        v_adhocExecMehodId := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Adhoc execution method not found';
        return;
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
          return;
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
          return;
    end;
    update tbl_task set col_taskorder = col_taskorder + 1 where col_parentid = (select col_parentid from tbl_task where col_id = v_sourceId) and col_taskorder >= v_taskorder;
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
          return;
    end;
    update tbl_task set col_taskorder = col_taskorder + 1 where col_parentid = (select col_parentid from tbl_task where col_id = v_sourceId) and col_taskorder >= v_taskorder;
  end if;

  insert into tbl_task
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
               col_taskppl_workbasket)
    values    (v_createdby,
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
               (select col_casetask from tbl_task where col_id = v_TaskId),
               v_enabled,
               v_hoursworked,
               v_systemtype,
               v_DateAssigned,
               v_tasksystypeid,
               v_adhocExecMehodId,
               v_workbasketid);

  select gen_tbl_task.currval into v_TaskId from dual;

  v_result := f_DCM_generateTaskId (affectedRows => v_affectedRows, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                    prefix => v_prefix, recordid => v_TaskId, taskid => v_BusTaskId);
  
  update tbl_task set col_taskid = v_BusTaskId, col_id2 = v_TaskId where col_id = v_TaskId;
  
  -- CREATE A TASK EXT RECORD FOR EACH TASK
  begin
    select col_customdataprocessor into v_customdataprocessor from tbl_dict_tasksystype where col_id = v_tasksystypeid;
    exception
    when NO_DATA_FOUND then
    v_customdataprocessor := null;
  end;
  if v_customdataprocessor is null then
    insert into tbl_taskext (col_taskexttask) values (v_TaskId);
    select gen_tbl_taskext.currval into v_TaskExtId from dual;	
  else
    v_TaskExtId := f_dcm_invokeCustomDataProc(Input => v_Input, ProcessorName => v_customdataprocessor, TaskId => v_TaskId);
  end if;

  --CREATE ACCOMPANYING WORKITEM FOR THE TASK
  if (v_workbasketid is not null) then
    v_activitycode := v_stateAssigned;
  else
    v_activitycode := v_stateStarted;
  end if;
  v_workflowcode := v_TokenDomain || '_' || v_workflow;
  v_result := f_TSKW_createWorkitem2 (ActivityCode => v_activitycode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                     TaskId => v_TaskId,  WorkflowCode => v_workflowcode);
  :TaskId := v_TaskId;
  :TaskExtId := v_TaskExtId;
  :TaskName := v_BusTaskId;

  v_Result := f_DCM_addTaskDateEventList(TaskId => v_TaskId, state => v_activitycode);

  v_result := f_DCM_CopyTaskStateInitTask(owner => v_owner, TaskId => v_TaskId);
  
  v_result := f_DCM_CopyRuleParameterTask(TaskId => v_TaskId);

  --ADD HISTORY RECORD FOR TASK
  v_result := f_DCM_addTaskHistory(Status => 1, TaskId => v_TaskId);

  v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
  v_result := f_dcm_casequeueproc5();

  :ErrorCode := 200;
  :ErrorMessage := 'Success';

end;