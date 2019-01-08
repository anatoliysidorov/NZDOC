declare
  v_TaskId Integer;
  v_Target nvarchar2(255);
  v_TargetName nvarchar2(255);
  v_stateNew nvarchar2(255);
  v_stateStarted nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateInProcess nvarchar2(255);
  v_stateResolved nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_state nvarchar2(255);
  v_sysdate date;
  v_InitMethod nvarchar2(255);
  v_result number;
  v_IsValid number;
begin
  v_TaskId := :TaskId;
  v_Target := :Target;
  v_sysdate := sysdate;
  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  v_stateInProcess := f_dcm_getTaskInProcessState();
  v_stateResolved := f_dcm_getTaskResolvedState();
  v_stateClosed := f_dcm_getTaskClosedState();
  v_IsValid := 1;
  :ErrorCode := null;
  :ErrorMessage := null;
  begin
    select twi.col_activity into v_state from tbl_task tsk inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
      where tsk.col_id = v_TaskId;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 104;
        :ErrorMessage := 'Task not found';
        return -1;
  end;
  if (v_state <> v_stateNew) and (v_state <> v_stateStarted) and (v_state <> v_stateAssigned) and (v_state <> v_stateInProcess) and (v_state <> v_stateResolved) and (v_state <> v_stateClosed) then
    :ErrorCode := 105;
    :ErrorMessage := 'Task state undefined';
    return -1;
  end if;
  begin
    select v_target into v_target from dual where v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)));
    exception
      when NO_DATA_FOUND then
        ErrorCode := 106;
        ErrorMessage := 'Task cannot be sent from state ' || v_state || ' to state ' || v_target;
        return -1;
  end;
  begin
    select col_name into v_targetname from tbl_dict_taskstate where col_activity = v_target;
    exception
      when NO_DATA_FOUND then
        ErrorCode := 112;
        ErrorMessage := 'Target state ' || v_target || ' is invalid';
        return -1;
  end;
  v_state := v_target;
  if (v_state <> v_stateNew) and (v_state <> v_stateStarted) and (v_state <> v_stateAssigned) and (v_state <> v_stateInProcess) and (v_state <> v_stateResolved) and (v_state <> v_stateClosed) then
    :ErrorCode := 107;
    :ErrorMessage := 'Task next state undefined';
    return -1;
  end if;
  begin
    select dim.col_code into v_InitMethod
      from tbl_task tsk
      inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
      inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
      inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
      inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
      inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
      where tsk.col_id = v_TaskId
      and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
      and dts.col_activity = v_state;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 108;
        :ErrorMessage := 'Task ' || v_TaskId || ' state ' || v_state || ' not found';
        return -1;
  end;
  if (v_InitMethod = 'MANUAL_CONFIG') or (v_InitMethod = 'AUTOMATIC_CONFIG') then
    :ErrorMessage := null;
    --CHECK 'FS' DEPENDENCY TYPE
    for rec in
      (select tsic.col_map_taskstateinittask as TsiChildTask, tsip.col_map_taskstateinittask as TsiParentTask,
              dtsc.col_code as ChildState, dtsp.col_code as ParentState, dtsc.col_activity as ChildActivity, dtsp.col_activity as ParentActivity
                                         --SELECT FROM TASK DEPENDENCY
                                         from tbl_taskdependency td
                                         --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                                         inner join tbl_map_taskstateinitiation tsip on td.col_tskdpndprnttskstateinit = tsip.col_id
                                         --JOIN TASK INITIATION RECORDS FOR CHILD TASK
                                         inner join tbl_map_taskstateinitiation tsic on td.col_tskdpndchldtskstateinit = tsic.col_id
                                         --JOIN PARENT TASK
                                         inner join tbl_task tskp on tsip.col_map_taskstateinittask = tskp.col_id
                                         --JOIN CHILD TASK
                                         inner join tbl_task tskc on tsic.col_map_taskstateinittask = tskc.col_id
                                         --JOIN PARENT WORKITEM
                                         inner join tbl_tw_workitem twip on tskp.col_tw_workitemtask = twip.col_id
                                         --JOIN CHILD WORKITEM
                                         inner join tbl_tw_workitem twic on tskc.col_tw_workitemtask = twic.col_id
                                         --JOIN PARENT TASK STATE
                                         inner join tbl_dict_taskstate dtsp on tsip.col_map_tskstinit_tskst = dtsp.col_id
                                         --JOIN CHILD TASK STATE
                                         inner join tbl_dict_taskstate dtsc on tsic.col_map_tskstinit_tskst = dtsc.col_id
                                         where tskc.col_id = v_TaskId
                                         --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                                         and dtsc.col_activity = v_state
                                         and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
                                         and twip.col_activity <> dtsp.col_activity
                                         --FILTER DEPENDENCY TO TYPE 'FS' ONLY
                                         and td.col_type = 'FS')
    loop
      if (:ErrorMessage is null) then
        :ErrorMessage := 'Task ' || rec.TsiChildTask || ' cannot be routed. Task state ' ||
          rec.ChildState || ' has ''FS'' dependency on task ' || rec.TsiParentTask || ' state ' || rec.ParentState;
      else
        :ErrorMessage := :ErrorMessage || ', task ' || rec.TsiParentTask || ' state ' || rec.ParentState;
      end if;
    end loop;
    if (:ErrorMessage is not null) then
      :ErrorCode := 109;
      v_IsValid := 0;
      return -1;
    end if;
    --CHECK 'SS' DEPENDENCY TYPE
    for rec in
      (select tsic.col_map_taskstateinittask as TsiChildTask, tsip.col_map_taskstateinittask as TsiParentTask,
              dtsc.col_code as ChildState, dtsp.col_code as ParentState, dtsc.col_activity as ChildActivity, dtsp.col_activity as ParentActivity
                                         --SELECT FROM TASK DEPENDENCY
                                         from tbl_taskdependency td
                                         --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                                         inner join tbl_map_taskstateinitiation tsip on td.col_tskdpndprnttskstateinit = tsip.col_id
                                         --JOIN TASK INITIATION RECORDS FOR CHILD TASK
                                         inner join tbl_map_taskstateinitiation tsic on td.col_tskdpndchldtskstateinit = tsic.col_id
                                         --JOIN PARENT TASK
                                         inner join tbl_task tskp on tsip.col_map_taskstateinittask = tskp.col_id
                                         --JOIN CHILD TASK
                                         inner join tbl_task tskc on tsic.col_map_taskstateinittask = tskc.col_id
                                         --JOIN PARENT WORKITEM
                                         inner join tbl_tw_workitem twip on tskp.col_tw_workitemtask = twip.col_id
                                         --JOIN CHILD WORKITEM
                                         inner join tbl_tw_workitem twic on tskc.col_tw_workitemtask = twic.col_id
                                         --JOIN PARENT TASK STATE
                                         inner join tbl_dict_taskstate dtsp on tsip.col_map_tskstinit_tskst = dtsp.col_id
                                         --JOIN CHILD TASK STATE
                                         inner join tbl_dict_taskstate dtsc on tsic.col_map_tskstinit_tskst = dtsc.col_id
                                         where tskc.col_id = v_TaskId
                                         --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                                         and dtsc.col_activity = v_state
                                         and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
                                         and (twip.col_activity not in (select nexttaskactivity from table(f_DCM_getNextTaskStates(StartState => dtsp.col_activity)))
                                             and twip.col_activity <> dtsp.col_activity)
                                         --FILTER DEPENDENCY TO TYPE 'SS' ONLY
                                         and td.col_type = 'SS')
    loop
      if (:ErrorMessage is null) then
        :ErrorMessage := 'Task ' || rec.TsiChildTask || ' cannot be routed. Task state ' ||
          rec.ChildState || ' has ''SS'' dependency on task ' || rec.TsiParentTask || ' state ' || rec.ParentState;
      else
        :ErrorMessage := :ErrorMessage || ', task ' || rec.TsiParentTask || ' state ' || rec.ParentState;
      end if;
    end loop;
    if (:ErrorMessage is not null) then
      :ErrorCode := 110;
      v_IsValid := 0;
      return -1;
    end if;
  end if;
  if (v_InitMethod = 'MANUAL_RULE') or (v_InitMethod = 'AUTOMATIC_RULE') then
    :ErrorMessage := null;
    --CHECK 'FSC' DEPENDENCY TYPE
    for rec in
      (select tsk.col_id as TaskId, tsk.col_taskid as TaskBsId, tsk.col_name as TaskName, dtst.col_code as TaskSysType, tsk.col_type as Tasktype,
                          tsk.col_dateassigned as TaskDateAssigned, tsk.col_dateclosed as TaskDateClosed,
                          tsk.col_depth as TaskDepth,
                          tsk.col_description as TaskDescription, twi.col_id as twId, tsk.col_casetask as CaseId
                from tbl_task tsk
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
                where tsk.col_id = v_TaskId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
                and ((lower(dim.col_code) = 'manual_rule') or (lower(dim.col_code) = 'automatic_rule'))
                and dts.col_activity = v_state
                and tsk.col_id in
                (select chldtsk.col_id
                from tbl_task tsk
                left  join tbl_stp_resolutioncode src on tsk.col_taskstp_resolutioncode = src.col_id
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
                inner join tbl_taskdependency td on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in ('FSC', 'FS')
                inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                inner join tbl_dict_taskstate chlddts on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                inner join tbl_task chldtsk on chldmtsi.col_map_taskstateinittask = chldtsk.col_id
                inner join tbl_tw_workitem chldtwi on chldtsk.col_tw_workitemtask = chldtwi.col_id
                inner join tbl_dict_tasksystype chlddtst on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                inner join tbl_dict_initmethod chlddim on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                left  join tbl_autoruleparameter chldarp on chldmtsi.col_id = chldarp.col_ruleparam_taskstateinit
                where chldtsk.col_id = v_TaskId
                and twi.col_activity <> dts.col_activity
                and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
                and chlddts.col_activity = v_state
                and ((lower(chlddim.col_code) = 'manual_rule') or (lower(chlddim.col_code) = 'automatic_rule'))
                and (case when td.col_processorcode is not null then f_DCM_invokeTaskProcessor2(td.col_processorcode, td.col_id)
                              when chldmtsi.col_processorcode is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id)
                              else 1 end) = 1))
    loop
      if (ErrorMessage is null) then
        ErrorMessage := 'Task ' || rec.TaskId || ' cannot be routed to state ' || v_targetname || ' because of ''FSC'' dependency';
      else
        ErrorMessage := ErrorMessage || ', task ' || rec.TaskId || ' state ' || v_targetname;
      end if;
    end loop;
    if (ErrorMessage is not null) then
      ErrorCode := 111;
      v_IsValid := 0;
      return -1;
    end if;
  end if;
end;