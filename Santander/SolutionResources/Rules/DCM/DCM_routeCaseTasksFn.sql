--RULE FINDS ALL RELATED TO CASE TASKS THAT ARE ELIGIBLE FOR STARTING AND STARTS THEM
declare
  v_CaseId Integer;
  v_stateNew nvarchar2(255);
  v_stateStarted nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateInProcess nvarchar2(255);
  v_stateResolved nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_stateCode nvarchar2(255);
  v_sysdate date;
  v_IsValid number;
  v_result number;
  v_Message nclob;
begin
  v_CaseId := :CaseId;
  v_sysdate := sysdate;
  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  v_stateInProcess := f_dcm_getTaskInProcessState();
  v_stateResolved := f_dcm_getTaskResolvedState();
  v_stateClosed := f_dcm_getTaskClosedState();
  v_IsValid := 1;
  --SELECT ALL TASKS ELIGIBLE FOR TRANSITION FROM 'NEW' TO 'STARTED' STATE
  --RESULT INCLUDES RECORDS OF FOLLOWING TYPES THAT SATISFY RELATED CONFIGURATION
  --1. INITIATION TYPE 'AUTOMATIC_CONFIG' THAT CAN BE STARTED BY DEPENDENCY TYPES 'FS', 'FSO', 'SS'
  --2. RECORDS WITH INITIATION TYPE 'AUTOMATIC'
  --3. RECORDS WITH INITIATION TYPE 'AUTOMATIC_RULE'
  for rec in (
              --FIRST FIND RECORDS WITH INITIATION TYPE 'AUTOMATIC_CONFIG' THAT CAN BE STARTED BY DEPENDENCY TYPES 'FS', 'FSO', 'SS'
              select tsk.col_id as TaskId, tsk.col_taskid as TaskBsId, tsk.col_name as Taskname, dtst.col_code as TaskSysType, tsk.col_type as TaskType,
              tsk.col_dateassigned as TaskDateAssigned, tsk.col_dateclosed as TaskDateClosed,
              tsk.col_depth as TaskDepth,
              tsk.col_description as TaskDescription, twi.col_id as twId, twi.col_activity as twActivity, dts.col_activity as twTargetActivity,
              mtsi.col_id as TaskStateInitId, mtsi.col_processorcode as TaskStateInitProc, mtsi.col_assignprocessorcode as TaskStateInitAssignProc
              from tbl_task tsk
              inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
              inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
              inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
              inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
              inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
              inner join tbl_dict_tasktransition dtt on dtt.col_sourcetasktranstaskstate = twi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = dts.col_id
                                              and nvl(dtt.col_manualonly, 0) = 0
              where tsk.col_casetask = v_CaseId
              --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
              and twi.col_activity in (select col_activity from tbl_dict_taskstate)
              and lower(dim.col_code) = 'automatic_config'
              and dts.col_activity in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
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
                                         where tskp.col_casetask = v_CaseId
                                         --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                                         and dtsc.col_activity in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => tskc.col_id)))
                                         --FILTER OUT PARENT TASKS TO THOSE NOT IN STATE 'root_TSK_Status_CLOSED'
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
                             where tskp.col_casetask = v_CaseId
                             --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                             and dtsc.col_activity in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => tskc.col_id)))
                             --FILTER PARENT TASK INITIATION RECORDS TO STATE 'root_TSK_Status_CLOSED'
                             and twip.col_activity <> dtsp.col_activity
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
                             where tskp.col_casetask = v_CaseId
                             --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                             and dtsc.col_activity in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => tskc.col_id)))
                             --FILTER OUT PARENT TASKS TO THOSE NOT IN STATE 'root_TSK_Status_CLOSED'
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
                                         where tskp.col_casetask = v_CaseId
                                         --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                                         and dtsc.col_activity in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => tskc.col_id)))
                                         --FILTER PARENT TASKS TO THOSE IN STATE 'root_TSK_Status_NEW'
                                         and (twip.col_activity not in (select nexttaskactivity from table(f_DCM_getNextTaskStates(StartState => dtsp.col_activity)))
                                             and twip.col_activity <> dtsp.col_activity)
                                         --FILTER DEPENDENCY TO TYPE 'SS' ONLY
                                         and td.col_type = 'SS'
                                      )
union all
--ADD RECORDS WITH INITIATION TYPE 'AUTOMATIC'
select tsk.col_id as TaskId, tsk.col_taskid as TaskBsId, tsk.col_name as Taskname, dtst.col_code as TaskSysType, tsk.col_type as TaskType,
                          tsk.col_dateassigned as TaskDateAssigned, tsk.col_dateclosed as TaskDateClosed,
                          tsk.col_depth as TaskDepth, tsk.col_description as TaskDescription,
                          twi.col_id as twId, twi.col_activity as twActivity, dts.col_activity as twTargetActivity,
                          mtsi.col_id as TaskStateInitId, mtsi.col_processorcode as TaskStateInitProc, mtsi.col_assignprocessorcode as TaskStateInitAssignProc
                from tbl_task tsk
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
                inner join tbl_dict_tasktransition dtt on dtt.col_sourcetasktranstaskstate = twi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = dts.col_id
                                              and nvl(dtt.col_manualonly, 0) = 0
                where tsk.col_casetask = v_CaseId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and twi.col_activity in (select col_activity from tbl_dict_taskstate)
                and dts.col_activity in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
                and lower(dim.col_code) = 'automatic'
union all
--ADD RECORDS WITH INITIATION TYPE 'AUTOMATIC_RULE'
select tsk.col_id as TaskId, tsk.col_taskid as TaskBsId, tsk.col_name as Taskname, dtst.col_code as TaskSysType, tsk.col_type as TaskType,
       tsk.col_dateassigned as TaskDateAssigned, tsk.col_dateclosed as TaskDateClosed,
       tsk.col_depth as TaskDepth,
       tsk.col_description as TaskDescription, twi.col_id as twId, twi.col_activity as twActivity, dts.col_activity as twTargetActivity,
       mtsi.col_id as TaskStateInitId, mtsi.col_processorcode as TaskStateInitProc, mtsi.col_assignprocessorcode as TaskStateInitAssignProc
                from tbl_task tsk
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
                inner join tbl_dict_tasktransition dtt on twi.col_tw_workitemdict_taskstate = dtt.col_sourcetasktranstaskstate and dts.col_id = dtt.col_targettasktranstaskstate
                                                       and nvl(dtt.col_manualonly, 0) = 0
                where tsk.col_casetask = v_CaseId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and twi.col_activity in (select col_activity from tbl_dict_taskstate)
                and lower(dim.col_code) = 'automatic_rule'
                and dts.col_activity in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
                and tsk.col_id not in
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
                inner join tbl_dict_tasktransition dtt on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id
                                                       and nvl(dtt.col_manualonly, 0) = 0
                left  join tbl_autoruleparameter chldarp on chldmtsi.col_id = chldarp.col_ruleparam_taskstateinit
                where tsk.col_casetask = v_CaseId
                and chldtwi.col_activity in (select col_activity from tbl_dict_taskstate)
                and chlddts.col_activity in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                and lower(chlddim.col_code) = 'automatic_rule'
                and (twi.col_activity <> dts.col_activity
                     or (case when td.col_processorcode is not null then f_DCM_invokeTaskProcessor2(td.col_processorcode, td.col_id)
                              when chldmtsi.col_processorcode is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id)
                              else 1 end) <> 1))
                -- and f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id) = 1)
                order by TaskId)
    --START TASKS ELIGIBLE FOR STARTING
    --SET TASK STATE AND DATE TASK IS ASSIGNED
    loop
      --BEFORE TASK INITIALIZATION CALL BEFORE_ASSIGN EVENT PROCESSOR
      v_result := f_DCM_processEvent(Message => v_Message, NextTaskId => rec.TaskId, EventType => 'before', EventState => rec.twTargetActivity, IsValid => v_IsValid);
      if v_IsValid = 1 then
        begin
          --SET TASK rec.TaskId IN CURSOR rec TO STATE v_stateStarted
          update tbl_tw_workitem set col_activity = rec.twTargetActivity, col_tw_workitemprevtaskstate = col_tw_workitemdict_taskstate, col_tw_workitemdict_taskstate = (select col_id from tbl_dict_taskstate where col_activity = rec.twTargetActivity)
            where col_id = (select col_tw_workitemtask from tbl_task where col_id = rec.TaskId);
          v_result := f_DCM_resetSlaEventCounter(TaskId => rec.TaskId);
          for rec2 in
          (select ts.col_id as TaskStateId, ts.col_code as TaskStateCode, ts.col_name as TaskStateName, ts.col_activity as TaskStateActivity,
                  tst.col_id as TaskStateSetupId, tst.col_name as TaskStateSetupName, tst.col_code as TaskStateSetupCode,
                  tst.col_forcednull as ForcedNull, tst.col_forcedoverwrite as ForcedOverwrite, tst.col_notnulloverwrite as NotNullOverwrite, tst.col_nulloverwrite as NullOverwrite
           from tbl_dict_taskstate ts
           inner join tbl_dict_taskstatesetup tst on ts.col_id = tst.col_taskstatesetuptaskstate
           where ts.col_activity = rec.twTargetActivity)
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
                update tbl_task set col_taskppl_workbasket = col_taskppl_workbasket where col_id = rec.TaskId;
              end if;
            elsif rec2.taskstatesetupcode = 'RESOLUTION' then
              update tbl_task set col_taskstp_resolutioncode = col_taskstp_resolutioncode where col_id = rec.TaskId;
            end if;
          end loop;
          if rec.twTargetActivity = v_stateAssigned then
            v_result := f_DCM_invokeTaskAssignProc(ProcessorName => rec.TaskStateInitAssignProc, TaskId => rec.TaskId);
          end if;
          v_result := f_DCM_addTaskDateEventList(TaskId => rec.TaskId, state => rec.twTargetActivity);
          exception
            when NO_DATA_FOUND then
              exit;
        end;
        begin
          select col_code into v_stateCode from tbl_dict_taskstate where col_activity = rec.twTargetActivity;
          exception
          when NO_DATA_FOUND then
            return -1;
        end;
        --CREATE NOTIFICATION
        v_result := f_DCM_createNotification(CaseId => null, NotificationTypeCode => 'TASK_MOVED', TaskId => rec.TaskId);
        --AFTER TRANSITION EVENTS
        v_result := f_DCM_processEvent4(Message => v_Message, NextTaskId => rec.TaskId, TaskState => v_stateCode, IsValid => v_IsValid);
        v_result := f_DCM_createTaskHistory (IsSystem => 1, MessageCode => 'TaskMoved', TaskId => rec.TaskId);
        --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE
        v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
        v_result := f_dcm_statCalc(TaskId => rec.TaskId);
        if rec.twTargetActivity = f_dcm_getTaskClosedState() then
           v_result := f_dcm_statUpdate(TaskId => rec.TaskId);
        end if;
      else
        v_result := f_DCM_createTaskHistory2(IsSystem => 1, Message => v_Message, TaskId => rec.TaskId);
      end if;
    end loop;
end;