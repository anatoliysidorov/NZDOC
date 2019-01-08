declare
  v_TaskId Integer;
  v_WorkbasketId Integer;
  v_ResolutionId Integer;
  v_target nvarchar2(255);
  v_state nvarchar2(255);
  v_sysdate date;
  v_IsValid number;
  v_result number;
  v_result2 nvarchar2(255);
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
  v_DebugSession nvarchar2(255);
  v_resolutionAssigned number;
begin
  v_TaskId := :TaskId;
  v_WorkbasketId := :WorkbasketId;
  v_ResolutionId := :ResolutionId;
  v_target := :Target;
  v_sysdate := sysdate;
  v_IsValid := 1;
  v_DebugSession := f_DBG_createDBGSession(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId), CaseTypeId => f_dcm_getcasetypeforcase(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId)), ProcedureId => null);
  v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId), Location => 'DCM_taskRouteManualFn5 begin', Message => 'Before routing task ' || to_char(v_TaskId), Rule => 'DCM_taskRouteManualFn5', TaskId => v_TaskId);
  begin
    select twi.col_activity into v_state from tbl_task tsk inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
      where tsk.col_id = v_TaskId;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 104;
        :ErrorMessage := 'Task not found';
        return -1;
  end;
  begin
    select col_activity into v_result2 from tbl_dict_taskstate where col_activity = v_state
      and nvl(col_stateconfigtaskstate,0) =
        (select nvl(col_stateconfigtasksystype,0) from tbl_dict_tasksystype where col_id =
          (select col_taskdict_tasksystype from tbl_task where col_id = v_TaskId));
      exception
        when NO_DATA_FOUND then
          :ErrorCode := 105;
          :ErrorMessage := 'Task state undefined';
          return -1;
  end;
  begin
    select v_target into v_target from dual where v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)));
    exception
      when NO_DATA_FOUND then
        ErrorCode := 111;
        ErrorMessage := 'Task cannot be sent from state ' || v_state || ' to state ' || v_target;
        return -1;
  end;
  v_state := v_target;
  begin
    select col_activity into v_result2 from tbl_dict_taskstate where col_activity = v_state
      and nvl(col_stateconfigtaskstate,0) =
        (select nvl(col_stateconfigtasksystype,0) from tbl_dict_tasksystype where col_id =
          (select col_taskdict_tasksystype from tbl_task where col_id = v_TaskId));
      exception
        when NO_DATA_FOUND then
         :ErrorCode := 107;
         :ErrorMessage := 'Task next state undefined';
         return -1;
  end;
  for rec in (
    --FIRST FIND RECORDS WITH INITIATION TYPE 'MANUAL_CONFIG' THAT CAN BE STARTED BY DEPENDENCY TYPES 'FS', 'FSO', 'SS'
    select  s1.TaskId as TaskId, s1.TaskBsId as TaskBsId, s1.TaskName as TaskName, s1.TaskSysType as TaskSysType, s1.TaskType as TaskType,
                          s1.TaskDateAssigned as TaskDateAssigned, s1.TaskDateClosed as TaskDateClosed,
                          s1.TaskDepth as TaskDepth,
                          s1.TaskDescription as TaskDescription, s1.twId as TWId, s1.CaseId as CaseId, s1.TaskStateId as TaskStateId, s1.AssignProcessorCode as AssignProcessorCode
                from
      (select tsk.col_id as TaskId, tsk.col_taskid as TaskBsId, tsk.col_name as TaskName, dtst.col_code as TaskSysType, tsk.col_type as Tasktype,
                          tsk.col_dateassigned as TaskDateAssigned, tsk.col_dateclosed as TaskDateClosed,
                          tsk.col_depth as TaskDepth,
                          tsk.col_description as TaskDescription, twi.col_id as twId, tsk.col_casetask as CaseId, mtsi.col_id as TaskStateId, mtsi.col_assignprocessorcode as AssignProcessorCode
                from tbl_task tsk
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
                where tsk.col_id = v_TaskId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
                and ((lower(dim.col_code) = 'manual_config') or (lower(dim.col_code) = 'automatic_config'))
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
                                         and v_target in (select NextActivity from table (f_DCM_getNextActivityList2(TaskId => v_TaskId)))
                                         and (twip.col_activity <> dtsp.col_activity and tsip.col_routedby is null and tsip.col_routeddate is null)
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
                                         and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
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
                          twi.col_id as twId, tsk.col_casetask as CaseId, mtsi.col_id as TaskStateId, mtsi.col_assignprocessorcode as AssignProcessorCode
                from tbl_task tsk
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id

                where tsk.col_id = v_TaskId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
                and lower(dim.col_code) in ('manual', 'automatic')
                and dts.col_activity = v_state
      union all
      --ADD RECORDS WITH INITIATION TYPE 'MANUL_RULE'
      select tsk.col_id as TaskId, tsk.col_taskid as TaskBsId, tsk.col_name as TaskName, dtst.col_code as TaskSysType, tsk.col_type as Tasktype,
                          tsk.col_dateassigned as TaskDateAssigned, tsk.col_dateclosed as TaskDateClosed,
                          tsk.col_depth as TaskDepth,
                          tsk.col_description as TaskDescription, twi.col_id as twId, tsk.col_casetask as CaseId, mtsi.col_id as TaskStateId, mtsi.col_assignprocessorcode as AssignProcessorCode
                from tbl_task tsk
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
                where tsk.col_id = v_TaskId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
                and lower(dim.col_code) in ('manual_rule', 'automatic_rule')
                and dts.col_activity = v_state
                and tsk.col_id not in
                (select chldtsk.col_id
                from tbl_task tsk
                left  join tbl_stp_resolutioncode src on tsk.col_taskstp_resolutioncode = src.col_id
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
                inner join tbl_taskdependency td on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in ('FSC', 'FS', 'FSCLR')
                inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                inner join tbl_dict_taskstate chlddts on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                inner join tbl_task chldtsk on chldmtsi.col_map_taskstateinittask = chldtsk.col_id
                inner join tbl_tw_workitem chldtwi on chldtsk.col_tw_workitemtask = chldtwi.col_id
                inner join tbl_dict_tasksystype chlddtst on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                inner join tbl_dict_initmethod chlddim on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                left  join tbl_autoruleparameter chldarp on chldmtsi.col_id = chldarp.col_ruleparam_taskstateinit
                where chldtsk.col_id = v_TaskId
                and v_target in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => v_TaskId)))
                and chlddts.col_activity = v_state
                and lower(chlddim.col_code) in ('manual_rule', 'automatic_rule')
                and ((twi.col_activity <> dts.col_activity and mtsi.col_routedby is null and mtsi.col_routeddate is null)
                     or (case when td.col_processorcode is not null then f_DCM_invokeTaskProcessor2(td.col_processorcode, td.col_id)
                              when chldmtsi.col_processorcode is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id)
                              else 1 end) <> 1))
                -- and f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id) = 1)
                ) s1
  )
  loop
    --SAVE RULE PARAMETERS RESOLUTION AND WORKBASKET FOR PROCESSING BY VALIDATION EVENTS
    update tbl_task set col_taskworkbasket_param = v_WorkbasketId, col_taskresolutioncode_param = v_ResolutionId where col_id = rec.TaskId;
    --BEFORE TRANSITION VALIDATION EVENTS
    v_DebugSession := f_DBG_createDBGSession(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), CaseTypeId => f_dcm_getcasetypeforcase(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId)), ProcedureId => null);
    v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'Before processing of before routing validation events',
                                     Message => 'Task ' || to_char(rec.TaskId) || ' before processing of before routing to ' || v_state || ' validation events', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
    v_result := f_DCM_processEvent2(Message => v_Message, NextTaskId => rec.TaskId, EventState => v_state, IsValid => v_IsValid);
    v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'After processing of before routing validation events',
                                     Message => 'Task ' || to_char(rec.TaskId) || ' after processing of before routing to ' || v_state || ' validation events', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
    if nvl(v_IsValid,0) = 0 then
      :ErrorCode := 112;
      :ErrorMessage := v_Message;
      return -1;
    end if;
    if v_IsValid = 1 then
      v_resolutionAssigned := 0;
      --BEFORE TRANSITION ACTION EVENTS
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'Before processing of before routing action events',
                                       Message => 'Task ' || to_char(rec.TaskId) || ' before processing of before routing to ' || v_state || ' action events', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      v_result := f_DCM_processEvent5(Message => v_Message, NextTaskId => rec.TaskId, EventState => v_state, IsValid => v_IsValid);
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'After processing of before routing action events',
                                       Message => 'Task ' || to_char(rec.TaskId) || ' after processing of before routing to ' || v_state || ' action events', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      begin
        for rec2 in
        (select ts.col_id as TaskStateId, ts.col_code as TaskStateCode, ts.col_name as TaskStateName, ts.col_activity as TaskStateActivity,
                tst.col_id as TaskStateSetupId, tst.col_name as TaskStateSetupName, tst.col_code as TaskStateSetupCode,
                tst.col_forcednull as ForcedNull, tst.col_forcedoverwrite as ForcedOverwrite, tst.col_notnulloverwrite as NotNullOverwrite, tst.col_nulloverwrite as NullOverwrite
         from tbl_dict_taskstate ts
         inner join tbl_dict_taskstatesetup tst on ts.col_id = tst.col_taskstatesetuptaskstate
         where ts.col_activity = v_state)
        loop
          if rec2.taskstatesetupcode = 'DATESTARTED' then
            update tbl_task set col_datestarted = v_sysdate where col_id = rec.TaskId;
          elsif rec2.taskstatesetupcode = 'DATEASSIGNED' then
            if rec2.ForcedNull = 1 then
              update tbl_task set col_dateassigned = null where col_id = rec.TaskId;
            elsif rec2.ForcedOverwrite = 1 then
              update tbl_task set col_dateassigned = v_sysdate where col_id = rec.TaskId;
            end if;
          elsif rec2.taskstatesetupcode = 'DATECLOSED' then
            update tbl_task set col_dateclosed = v_sysdate where col_id = rec.TaskId;
          elsif rec2.taskstatesetupcode = 'WORKBASKET' then
            if rec2.ForcedNull = 1 then
              update tbl_task set col_taskpreviousworkbasket = col_taskppl_workbasket, col_taskppl_workbasket = null where col_id = rec.TaskId;
            elsif rec2.ForcedOverwrite = 1 then
              update tbl_task set col_taskpreviousworkbasket = col_taskppl_workbasket, col_taskppl_workbasket = v_WorkbasketId where col_id = rec.TaskId;
            end if;
          elsif rec2.taskstatesetupcode = 'RESOLUTION' then
            update tbl_task set col_taskstp_resolutioncode = v_ResolutionId where col_id = rec.TaskId;
            v_resolutionAssigned := 1;
          end if;
        end loop;
        if (rec.AssignProcessorCode is not null) and (v_WorkbasketId is null) then
          v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'Before assigment',
                                           Message => 'Task ' || to_char(rec.TaskId) || ' before assignment by ' || rec.AssignProcessorCode, Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
          v_result := f_DCM_invokeTaskAssignProc2(ProcessorName => rec.AssignProcessorCode, State => v_state, TaskId => rec.TaskId);
          v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'After assigment',
                                           Message => 'Task ' || to_char(rec.TaskId) || ' after assignment by ' || rec.AssignProcessorCode, Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
        end if;
        --SET TASK rec.TaskId IN CURSOR rec TO STATE v_state
        v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'Before task ' || to_char(rec.TaskId) || ' routing',
                                         Message => 'Task ' || to_char(rec.TaskId) || ' before being routed to activity ' || v_state, Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
        update tbl_tw_workitem set col_activity = v_state, col_tw_workitemprevtaskstate = col_tw_workitemdict_taskstate, col_tw_workitemdict_taskstate = (select col_id from tbl_dict_taskstate where col_activity = v_state
                                                                                            and nvl(col_stateconfigtaskstate,0) =
        (select nvl(col_stateconfigtasksystype,0) from tbl_dict_tasksystype where col_id =
          (select col_taskdict_tasksystype from tbl_task where col_id = rec.TaskId)))
          where col_id = (select col_tw_workitemtask from tbl_task where col_id = rec.TaskId);
        update tbl_map_taskstateinitiation set col_routedby = SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'), col_routeddate = sysdate where col_id = rec.TaskStateId;
        v_result := f_DCM_resetSlaEventCounter(TaskId => rec.TaskId);
        v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'After task ' || to_char(rec.TaskId) || ' routing',
                                         Message => 'Task ' || to_char(rec.TaskId) || ' after being routed to activity ' || v_state, Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
        v_Result := f_DCM_addTaskDateEventList(TaskId => rec.TaskId, state => v_state);
        exception
          when NO_DATA_FOUND then
            :ErrorCode := 101;
            :ErrorMessage := 'Task start failed';
            return -1;
      end;
      --CREATE NOTIFICATION
      v_result := f_DCM_createNotification(CaseId => null, NotificationTypeCode => 'TASK_MOVED', TaskId => rec.TaskId);
      --AFTER TRANSITION ACTION SYNCHRONOUS EVENTS
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'Before processing of --after task routing action-- synchronous events',
                                       Message => 'Task ' || to_char(rec.TaskId) || ' before processing of --after task routing action-- synchronous events' || v_state, Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      v_result := f_DCM_processEvent6(Message => v_Message, NextTaskId => rec.TaskId, EventState => v_state, IsValid => v_IsValid);
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'After processing of --after task routing action-- synchronous events',
                                       Message => 'Task ' || to_char(rec.TaskId) || ' after processing of --after task routing action-- synchronous events' || v_state, Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      if v_resolutionAssigned = 0 then
        v_result := f_DCM_createTaskHistory (IsSystem => 0, MessageCode => 'TaskRouted', TaskId => rec.TaskId);
      elsif v_resolutionAssigned = 1 then
        v_result := f_DCM_createTaskHistory (IsSystem => 0, MessageCode => 'TaskRoutedWithResolution', TaskId => rec.TaskId);
      end if;
      --TRY TO RETURN CLOSED CASE TASKS TO STARTED WHEN CONDITION VALIDATION SUCCEEDS (DEPENDENCY TYPE 'FSCLR')
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'Before call to DCM_routeallcasetasksfn',
                                       Message => 'Before call to DCM_routeallcasetasksfn', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      v_result := f_DCM_routeallcasetasksfn(TaskId => rec.TaskId);
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'After call to DCM_routeallcasetasksfn',
                                       Message => 'After call to DCM_routeallcasetasksfn', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE
      v_result := f_dcm_invalidatecase(CaseId => rec.CaseId);
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'Before call to dcm_casequeueproc5',
                                       Message => 'Before call to dcm_casequeueproc5', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      v_result := f_dcm_casequeueproc5();
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'After call to dcm_casequeueproc5',
                                       Message => 'After call to dcm_casequeueproc5', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      --AFTER TRANSITION ACTION ASYNCHRONOUS EVENTS
      --v_result := f_dcm_registeraftereventfn(TaskId => rec.TaskId);
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'Before processing of --after task routing action-- asynchronous events',
                                       Message => 'Task ' || to_char(rec.TaskId) || ' before processing of --after task routing action-- asynchronous events' || v_state, Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      v_result := f_DCM_processEvent7(Message => v_Message, NextTaskId => rec.TaskId, EventState => v_state, IsValid => v_IsValid);
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'After processing of --after task routing action-- asynchronous events',
                                       Message => 'Task ' || to_char(rec.TaskId) || ' after processing of --after task routing action-- asynchronous events' || v_state, Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      if v_target = f_dcm_getTaskNewState() or v_target = f_dcm_getTaskStartedState() then
        v_result := f_dcm_statClear(TaskId => rec.TaskId);
      end if;
      v_result := f_dcm_statCalc(TaskId => rec.TaskId);
      if v_target = f_dcm_getTaskClosedState() then
        v_result := f_dcm_statUpdate(TaskId => rec.TaskId);
      end if;
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'DCM_taskRouteManualFn5 end',
                                       Message => 'After task ' || to_char(rec.TaskId) || ' routing succeeded', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      return 0;
    else
      v_result := f_DCM_createTaskHistory2(IsSystem => 0, Message => v_Message, TaskId => rec.TaskId);
      :ErrorCode := 102;
      :ErrorMessage := v_Message;
      v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId), Location => 'DCM_taskRouteManualFn5 end',
                                       Message => 'After task ' || to_char(rec.TaskId) || ' routing failed', Rule => 'DCM_taskRouteManualFn5', TaskId => rec.TaskId);
      return -1;
    end if;
  end loop;
end;