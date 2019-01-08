--RULE FINDS ALL RELATED TO CASE TASKS THAT ARE ELIGIBLE FOR STARTING AND STARTS THEM
declare
  v_CaseId Integer;
  v_TaskId Integer;
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
  v_TaskId := :TaskId;
  v_sysdate := sysdate;
  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  v_stateInProcess := f_dcm_getTaskInProcessState();
  v_stateResolved := f_dcm_getTaskResolvedState();
  v_stateClosed := f_dcm_getTaskClosedState();
  v_IsValid := 1;
  begin
    select col_casetask into v_CaseId from tbl_task where col_id = v_TaskId;
    exception
    when NO_DATA_FOUND then
      v_CaseId := null;
  end;
  --SELECT ALL TASKS ELIGIBLE FOR TRANSITION FROM 'NEW' TO 'STARTED' STATE
  --RESULT INCLUDES RECORDS OF FOLLOWING TYPES THAT SATISFY RELATED CONFIGURATION
  --1. INITIATION TYPE 'AUTOMATIC_CONFIG' THAT CAN BE STARTED BY DEPENDENCY TYPES 'FS', 'FSO', 'SS'
  --2. RECORDS WITH INITIATION TYPE 'AUTOMATIC'
  --3. RECORDS WITH INITIATION TYPE 'AUTOMATIC_RULE'
  for rec in (
                select s1.TaskId as TaskId, s1.TaskBsId as TaskBsId, s1.TaskName as TaskName, s1.TaskSysType as TaskSysType, s1.TaskType as TaskType,
                s1.TaskDateAssigned as TaskDateAssigned, s1.TaskDateClosed as TaskDateClosed,
                s1.TaskDepth as TaskDepth,
                s1.TaskDescription as TaskDescription, s1.twId as twId, s1.twActivity as twActivity, s1.twTargetActivity as twTargetActivity,
                s1.TaskStateInitId as TaskStateInitId, s1.TaskStateInitProc as TaskStateInitProc, s1.TaskStateInitAssignProc as TaskStateInitAssignProc
                from
                (select chldtsk.col_id as TaskId, chldtsk.col_taskid as TaskBsId, chldtsk.col_name as TaskName, chlddtst.col_code as TaskSysType, chldtsk.col_type as TaskType,
                chldtsk.col_dateassigned as TaskDateAssigned, chldtsk.col_dateclosed as TaskDateClosed,
                chldtsk.col_depth as TaskDepth,
                chldtsk.col_description as TaskDescription, chldtwi.col_id as twId, chldtwi.col_activity as twActivity, chlddts.col_activity as twTargetActivity,
                chldmtsi.col_id as TaskStateInitId, chldmtsi.col_processorcode as TaskStateInitProc, chldmtsi.col_assignprocessorcode as TaskStateInitAssignProc,
                chldtsk.col_id as ChildTaskId, tsk.col_id as ParentTaskId, td.col_id as TaskDependencyId,
                chlddts.col_activity as ChildTaskTargetActivity,
                mtsi.col_id as MTSIId, mtsi.col_routeddate as ParentTaskRouteddate,
                row_number() over (order by mtsi.col_routeddate desc) as RowNumber
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
                inner join tbl_dict_tasktransition dtt on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id
                                                       and nvl(dtt.col_manualonly, 0) = 1
                left  join tbl_autoruleparameter chldarp on chldmtsi.col_id = chldarp.col_ruleparam_taskstateinit
                where tsk.col_id = v_TaskId
                and mtsi.col_routeddate is not null
                and chldtwi.col_activity in (select col_activity from tbl_dict_taskstate)
                and chlddts.col_activity in (select NextActivity from table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                and ((twi.col_activity = dts.col_activity or mtsi.col_routedby is null or mtsi.col_routeddate is null)
                     /*and (case when td.col_processorcode is not null then f_DCM_invokeTaskProcessor2(td.col_processorcode, td.col_id)
                              when chldmtsi.col_processorcode is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id)
                              else 1 end) = 1*/
                     and (1 in 
                            (select 1 from dual where td.col_processorcode is null and chldmtsi.col_processorcode is null
                             union
                             select f_DCM_invokeTaskProcessor2(td.col_processorcode, td.col_id) from dual where td.col_processorcode is not null
                             union
                             select f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id) from dual where chldmtsi.col_processorcode is not null and td.col_processorcode is null))
                    )) s1
                where s1.RowNumber = 1
                order by s1.TaskId)
    --START TASKS ELIGIBLE FOR STARTING--
    --SET TASK STATE AND DATE TASK IS ASSIGNED--
    loop
      --BEFORE TASK INITIALIZATION CALL BEFORE_ASSIGN EVENT PROCESSOR
      v_result := f_DCM_processEvent(Message => v_Message, NextTaskId => rec.TaskId, EventType => 'before', EventState => rec.twTargetActivity, IsValid => v_IsValid);
      if v_IsValid = 1 then
        begin
          --SET TASK rec.TaskId IN CURSOR rec TO STATE v_stateStarted
          update tbl_tw_workitem set col_activity = rec.twTargetActivity, col_tw_workitemprevtaskstate = col_tw_workitemdict_taskstate, col_tw_workitemdict_taskstate = (select col_id from tbl_dict_taskstate where col_activity = rec.twTargetActivity)
            where col_id = (select col_tw_workitemtask from tbl_task where col_id = rec.TaskId);
          update tbl_map_taskstateinitiation set col_routedby = SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'), col_routeddate = sysdate where col_id = rec.TaskStateInitId;
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
                update tbl_task set col_taskppl_workbasket = null where col_id = rec.TaskId;
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
        v_result := f_DCM_createTaskHistory (IsSystem => 1, MessageCode => 'TaskRouted', TaskId => rec.TaskId);
        if rec.twTargetActivity = f_dcm_getTaskNewState() or rec.twTargetActivity = f_dcm_getTaskStartedState() then
          v_result := f_dcm_statClear(TaskId => rec.TaskId);
        end if;
        v_result := f_dcm_statCalc(TaskId => rec.TaskId);
        if rec.twTargetActivity = f_dcm_getTaskClosedState() then
           v_result := f_dcm_statUpdate(TaskId => rec.TaskId);
        end if;
      else
        v_result := f_DCM_createTaskHistory2(IsSystem => 1, Message => v_Message, TaskId => rec.TaskId);
      end if;
    end loop;
end;