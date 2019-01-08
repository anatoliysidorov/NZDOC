declare 
  v_TaskId Integer;
  v_CaseId Integer;
  v_WorkbasketId Integer;
  v_ResolutionId Integer;
  v_stateNew nvarchar2(255);
  v_stateStarted nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateInProcess nvarchar2(255);
  v_stateResolved nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_state nvarchar2(255);
  v_sysdate date;
  v_IsValid number;
  v_result number;
  v_TaskId2 Integer;
  v_TaskBsId nvarchar2(255);
  v_TaskName nvarchar2(255);
  v_TaskSysType nvarchar2(255);
  v_TaskType nvarchar2(255);
  v_TaskDateAssigned date;
  v_TaskDateClosed date;
  v_TaskDepth Integer;
  v_TaskDescription nclob;
  v_twId Integer;
  v_Message nclob;
  v_DateEventName nvarchar2(255);
  v_resolutionAssigned number;
begin
  v_TaskId := :TaskId;
  v_WorkbasketId := :WorkbasketId;
  v_ResolutionId := :ResolutionId;
  v_sysdate := sysdate;
  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  v_stateInProcess := f_dcm_getTaskInProcessState();
  v_stateResolved := f_dcm_getTaskResolvedState();
  v_stateClosed := f_dcm_getTaskClosedState();
  v_IsValid := 1;
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
  for rec in (
    --FIRST FIND RECORDS WITH INITIATION TYPE 'MANUAL_CONFIG' THAT CAN BE STARTED BY DEPENDENCY TYPES 'FS', 'FSO', 'SS'
    select  s1.TaskId as TaskId, s1.TaskBsId as TaskBsId, s1.TaskName as TaskName, s1.TaskSysType as TaskSysType, s1.TaskType as TaskType,
                          s1.TaskDateAssigned as TaskDateAssigned, s1.TaskDateClosed as TaskDateClosed,
                          s1.TaskDepth as TaskDepth,
                          s1.TaskDescription as TaskDescription, s1.twId as TWId, s1.CaseId as CaseId
                from
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
                and twi.col_activity = f_DCM_getPrevActivity(TaskActivity => v_state)
                and lower(dim.col_code) = 'manual_config'
                and dts.col_activity = v_state
                --THOSE TASKS MUST NOT CONTAIN TASKS (CHILD TASKS) THAT ARE DEPENDENT ON OTHER TASKS (PARENT TASKS) BY FINISH-TO-START DEPENDENCY TYPE (FS) THAT ARE NOT CLOSED
                --TASK IS CONSIDERED NOT CLOSED IF TASK STATE IS NOT 'root_TSK_Status_CLOSED'
                and tsk.col_id not in (select tsic.col_map_taskstateinittask
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
                                         and td.col_type = 'FS'
                                      )
                --CHECK THAT TASKS IN SELECT RESULT ITEMS ARE VALID ACCORDING TO "FSO" DEPENDENCY TYPE
                --"FSO" DEPENDENY IS FINISH-TO-START FLAVOR WITH AT LEAST ONE OF PARENT TASKS IS CLOSED
                --THIS MEANS THAT EITHER THOSE TASKS ARE NOT DEPENDENT FROM ANY OTHER TASKS (PARENT TASKS) BY "FSO" DEPENDENCY TYPE
                --OR IF THEY HAVE SUCH DEPENDENCY, AT LEAST ONE PARENT TASK IS IN 'root_TSK_Status_CLOSED' STATE
                and ((select count(*)
                        from
                          (select tsic.col_map_taskstateinittask, tskc.col_id as TaskId
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
                             --FILTER DEPENDENCY TO TYPE 'FSO' ONLY
                             and td.col_type = 'FSO') s1 where s1.TaskId = tsk.col_id) = 0
                      or
                     (select count(*)
                        from
                          (select tsic.col_map_taskstateinittask, tskc.col_id as TaskId
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
                             and twip.col_activity = dtsp.col_activity
                             --FILTER DEPENDENCY TO TYPE 'FSO' ONLY
                             and td.col_type = 'FSO') s2 where s2.TaskId = tsk.col_id) > 0)
                --THOSE TASKS MUST NOT CONTAIN TASKS (CHILD TASKS) THAT ARE DEPENDENT ON OTHER TASKS (PARENT TASKS) BY START-TO-START DEPENDENCY TYPE (SS) THAT ARE NOT STARTED
                --TASK IS CONSIDERED NOT STARTED IF EITHER TASK STATE IS 'root_TSK_Status_NEW' OR TASK DATE ASSIGNED IS NULL
                and tsk.col_id not in (select tsic.col_map_taskstateinittask
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
                                         --FILTER DEPENDENCY TO TYPE 'SS' ONLY
                                         and td.col_type = 'SS'
                                      )
      union all
      --ADD RECORDS WITH INITIATION TYPE 'MANUAL'
      select tsk.col_id as TaskId, tsk.col_taskid as TaskBsId, tsk.col_name as Taskname, dtst.col_code as TaskSysType, tsk.col_type as TaskType,
                          tsk.col_dateassigned as TaskDateAssigned, tsk.col_dateclosed as TaskDateClosed,
                          tsk.col_depth as TaskDepth, tsk.col_description as TaskDescription,
                          twi.col_id as twId, tsk.col_casetask as CaseId
                from tbl_task tsk
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id

                where tsk.col_id = v_TaskId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and twi.col_activity = f_DCM_getPrevActivity(TaskActivity => v_state)

                and lower(dim.col_code) = 'manual'
                and dts.col_activity = v_state
      union all
      --ADD RECORDS WITH INITIATION TYPE 'MANUL_RULE'
      select tsk.col_id as TaskId, tsk.col_taskid as TaskBsId, tsk.col_name as TaskName, dtst.col_code as TaskSysType, tsk.col_type as Tasktype,
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
                and twi.col_activity = f_DCM_getPrevActivity(TaskActivity => v_state)
                and lower(dim.col_code) = 'manual_rule'
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
                inner join tbl_taskdependency td on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type = 'FSC'
                inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                inner join tbl_dict_taskstate chlddts on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                inner join tbl_task chldtsk on chldmtsi.col_map_taskstateinittask = chldtsk.col_id
                inner join tbl_tw_workitem chldtwi on chldtsk.col_tw_workitemtask = chldtwi.col_id
                inner join tbl_dict_tasksystype chlddtst on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                inner join tbl_dict_initmethod chlddim on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                left  join tbl_autoruleparameter chldarp on chldmtsi.col_id = chldarp.col_ruleparam_taskstateinit
                where chldtsk.col_id = v_TaskId
                and twi.col_activity = dts.col_activity
                and chldtwi.col_activity = f_DCM_getPrevActivity(TaskActivity => v_state)
                and chlddts.col_activity = v_state
                and lower(chlddim.col_code) = 'manual_rule'
                and f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id) = 1)) s1
  )
  loop
    v_result := f_DCM_processEvent2(Message => v_Message, NextTaskId => rec.TaskId, EventState => v_state, IsValid => v_IsValid);
    if v_IsValid = 1 then
      v_resolutionAssigned := 0;
      begin
        --SET TASK rec.TaskId IN CURSOR rec TO STATE v_stateStarted
        update tbl_tw_workitem set col_activity = v_state, col_tw_workitemprevtaskstate = col_tw_workitemdict_taskstate, col_tw_workitemdict_taskstate = (select col_id from tbl_dict_taskstate where col_activity = v_state)
          where col_id = (select col_tw_workitemtask from tbl_task where col_id = rec.TaskId);
        case
          when v_state = v_stateNew then
            v_DateEventName := 'DATE_TASK_CREATED';
          when v_state = v_stateStarted then
            v_DateEventName := 'DATE_TASK_STARTED';
            update tbl_task set col_datestarted = v_sysdate where col_id = rec.TaskId;
          when v_state = v_stateAssigned then
            v_DateEventName := 'DATE_TASK_ASSIGNED';
            update tbl_task set col_taskpreviousworkbasket = col_taskppl_workbasket, col_taskppl_workbasket = v_WorkbasketId, col_dateassigned = v_sysdate where col_id = rec.TaskId;
          when v_state = v_stateInProcess then
            v_DateEventName := 'DATE_TASK_IN_PROCESS';
          when v_state = v_stateResolved then
            v_DateEventName := 'DATE_TASK_RESOLVED';
            update tbl_task set col_taskstp_resolutioncode = v_ResolutionId where col_id = rec.TaskId;
            v_resolutionAssigned := 1;
          when v_state = v_stateClosed then
            v_DateEventName := 'DATE_TASK_CLOSED';
            update tbl_task set col_dateclosed = v_sysdate where col_id = rec.TaskId;
          else v_DateEventName := 'NONE';
        end case;
        v_result := f_DCM_createTaskDateEvent (Name => v_DateEventName, TaskId => rec.TaskId);
        exception
          when NO_DATA_FOUND then
            :ErrorCode := 101;
            :ErrorMessage := 'Task start failed';
            return -1;
      end;
      v_result := f_DCM_processEvent4(Message => v_Message, NextTaskId => rec.TaskId, TaskState => v_state, IsValid => v_IsValid);
      if v_resolutionAssigned = 0 then
        v_result := f_DCM_createTaskHistory (IsSystem => 0, MessageCode => 'TaskRouted', TaskId => rec.TaskId);
      elsif v_resolutionAssigned = 1 then
        v_result := f_DCM_createTaskHistory (IsSystem => 0, MessageCode => 'TaskRoutedWithResolution', TaskId => rec.TaskId);
      end if;
      --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE
      v_result := f_dcm_invalidatecase(CaseId => rec.CaseId);
      v_result := f_dcm_casequeueproc5();
      v_result := f_dcm_registeraftereventfn(TaskId => rec.TaskId);
      return 0;
    else
      v_result := f_DCM_createTaskHistory2(IsSystem => 0, Message => v_Message, TaskId => rec.TaskId);
      :ErrorCode := 102;
      :ErrorMessage := v_Message;
      return -1;
    end if;
  end loop;
end;