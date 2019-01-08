declare
  v_TaskId Integer;
  v_Target nvarchar2(255);
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
  if (f_DCM_getNextActivity(TaskActivity => v_state) <> v_target) then
    :ErrorCode := 111;
    :ErrorMessage := 'Task cannot be sent from state ' || v_state || ' to state ' || v_target;
    return -1;
  end if;
  begin
    select f_DCM_getNextActivity(TaskActivity => v_state) into v_state from dual;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 106;
        :ErrorMessage := 'Task next state undefined';
        return -1;
  end;
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
      and twi.col_activity = f_DCM_getPrevActivity(TaskActivity => v_state)
      and dts.col_activity = v_state;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 108;
        :ErrorMessage := 'Task ' || v_TaskId || ' state ' || v_state || ' not found';
        return -1;
  end;
  if v_InitMethod = 'MANUAL_CONFIG' then
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
                                         and twic.col_activity = f_DCM_getPrevActivity(TaskActivity => dtsc.col_activity)
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
                                         and twic.col_activity = f_DCM_getPrevActivity(TaskActivity => dtsc.col_activity)
                                         and (twip.col_activity not in (select nexttaskactivity from table(f_DCM_getNextTaskStates(StartState => dtsp.col_activity)))
                                             and twip.col_activity <> dtsp.col_activity)
                                         --FILTER DEPENDENCY TO TYPE 'FS' ONLY
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
end;
