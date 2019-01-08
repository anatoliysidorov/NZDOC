declare
    v_sysdate date;
    v_DebugSession nvarchar2(255);
    v_CaseId Integer;
    v_twTargetActivity nvarchar2(255);
    v_TaskId Integer;
    v_Message nclob;
    v_IsValid number;
    v_TaskStateInitId Integer;
    v_stateCode nvarchar2(255);
    v_state nvarchar2(255);
    v_TaskStateInitAssignProc nvarchar2(255);
    v_TaskProcessor nvarchar2(255);
    v_result number;
    v_CaseInvalid number;
    v_stateAssigned nvarchar2(255);
    v_resolutionAssigned number;
    v_Domain nvarchar2(255);
    v_queueParams nclob;
begin
    v_CaseId := :CaseId;
    v_twTargetActivity := :TwTargetActivity;
    v_TaskId := :TaskId;
    v_TaskStateInitId := :TaskStateInitId;
    v_TaskStateInitAssignProc := :TaskStateInitAssignProc;
    v_sysdate := sysdate;
    v_CaseInvalid := 0;
    v_stateAssigned := f_dcm_getTaskAssignedState();
    v_Domain := f_UTIL_getDomainFn();
    v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId,
                                             CaseTypeId => f_dcm_getcasetypeforcase(CaseId => v_CaseId),
                                             ProcedureId => null);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId,
                                     Location => 'DCM_routeCaseCCTaskCCFn before validation',
                                     Message => 'Task ' || to_char(v_TaskId) || ' before validation events processing ' || v_twTargetActivity,
                                     Rule => 'DCM_routeCaseCCTaskCCFn',
                                     TaskId => v_TaskId);
    --BEFORE TASK INITIALIZATION CALL BEFORE_ASSIGN EVENT PROCESSOR
    v_result := f_DCM_processEventCC(Message => v_Message,
                                     NextTaskId => v_TaskId,
                                     EventType => 'before',
                                     EventState => v_twTargetActivity,
                                     IsValid => v_IsValid);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId,
                                     Location => 'DCM_routeCaseCCTaskCCFn after validation with validation Result: ' || to_char(v_IsValid),
                                     Message => 'Task ' || to_char(v_TaskId) || ' after validation events processing ' || v_twTargetActivity,
                                     Rule => 'DCM_routeCaseCCTaskCCFn',
                                     TaskId => v_TaskId);
    if v_IsValid = 1 then
        v_resolutionAssigned := 0;
        v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId,
                                                 CaseTypeId => f_dcm_getcasetypeforcase(CaseId => v_CaseId),
                                                 ProcedureId => null);
        v_result := f_DBG_createDBGTrace(CaseId => v_CaseId,
                                         Location => 'DCM_routeCaseCCTaskCCFn after validation, before task routing',
                                         Message => 'Task ' || to_char(v_TaskId) || ' is routed to state ' || v_twTargetActivity,
                                         Rule => 'DCM_routeCaseCCTaskCCFn',
                                         TaskId => v_TaskId);
        begin
            --SET TASK v_TaskId IN CURSOR rec TO STATE v_stateStarted
            update tbl_tw_workitemcc
            set    col_activity = v_twTargetActivity,
                   col_tw_workitemccprevtaskst = col_tw_workitemccdict_taskst,
                   col_tw_workitemccdict_taskst =(select col_id
                   from    tbl_dict_taskstate
                   where   col_activity = v_twTargetActivity)
            where  col_id =(select col_tw_workitemcctaskcc
                   from    tbl_taskcc
                   where   col_id = v_TaskId);
            
            update tbl_taskcc
            set    col_prevtaskccdict_taskstate = col_taskccdict_taskstate,
                   col_taskccdict_taskstate =(select col_id
                   from    tbl_dict_taskstate
                   where   col_activity = v_twTargetActivity)
            where  col_id = v_TaskId;
            
            update tbl_map_taskstateinitcc
            set    col_routedby = SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'),
                   col_routeddate = sysdate
            where  col_id = v_TaskStateInitId;
            
            v_result := f_DCM_resetSlaEventCounter(TaskId => v_TaskId);
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                             Location => 'After task ' || to_char(v_TaskId) || ' routing',
                                             Message => 'Task ' || to_char(v_TaskId) || ' after being routed to activity ' || v_twTargetActivity,
                                             Rule => 'DCM_routeCaseCCTaskCCFn',
                                             TaskId => v_TaskId);
            for rec2 in(select    ts.col_id as TaskStateId,
                       ts.col_code as TaskStateCode,
                       ts.col_name as TaskStateName,
                       ts.col_activity as TaskStateActivity,
                       tst.col_id as TaskStateSetupId,
                       tst.col_name as TaskStateSetupName,
                       tst.col_code as TaskStateSetupCode,
                       tst.col_forcednull as ForcedNull,
                       tst.col_forcedoverwrite as ForcedOverwrite,
                       tst.col_notnulloverwrite as NotNullOverwrite,
                       tst.col_nulloverwrite as NullOverwrite
            from       tbl_dict_taskstate ts
            inner join tbl_dict_taskstatesetup tst on ts.col_id = tst.col_taskstatesetuptaskstate
            where      ts.col_activity = v_twTargetActivity)
            loop
                if rec2.taskstatesetupcode = 'DATESTARTED' then
                    update tbl_taskcc
                    set    col_datestarted = v_sysdate
                    where  col_id = v_TaskId;
                
                elsif rec2.taskstatesetupcode = 'DATEASSIGNED' then
                    if rec2.ForcedNull = 1 then
                        update tbl_taskcc
                        set    col_dateassigned = null
                        where  col_id = v_TaskId;
                    
                    elsif rec2.ForcedOverwrite = 1 then
                        update tbl_taskcc
                        set    col_dateassigned = v_sysdate
                        where  col_id = v_TaskId;
                    
                    end if;
                elsif rec2.taskstatesetupcode = 'DATECLOSED' then
                    update tbl_taskcc
                    set    col_dateclosed = v_sysdate
                    where  col_id = v_TaskId;
                
                elsif rec2.taskstatesetupcode = 'WORKBASKET' then
                    if rec2.ForcedNull = 1 then
                        update tbl_taskcc
                        set    col_taskccpreviousworkbasket = col_taskccppl_workbasket,
                               col_taskccppl_workbasket = null
                        where  col_id = v_TaskId;
                    
                    elsif rec2.ForcedOverwrite = 1 then
                        update tbl_taskcc
                        set    col_taskccppl_workbasket = col_taskccppl_workbasket
                        where  col_id = v_TaskId;
                    
                    end if;
                elsif rec2.taskstatesetupcode = 'RESOLUTION' then
                    update tbl_taskcc
                    set    col_taskccstp_resolutioncode = col_taskccstp_resolutioncode
                    where  col_id = v_TaskId;
                    
                    v_resolutionAssigned := 1;
                end if;
            end loop;
            begin
                select col_processorname
                into
                       v_TaskProcessor
                from   tbl_taskcc
                where  col_id = v_TaskId;
            
            exception
            when NO_DATA_FOUND then
                v_TaskProcessor := null;
            end;
            select count(*)
            into
                   v_result
            from   table(f_DCM_getTaskInprStateList(TaskId => v_TaskId))
            where  Activity = v_twTargetActivity;
            
            if v_result > 0 and v_TaskProcessor is not null then
                v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                                 Location => 'Before automatic task processing',
                                                 Message => 'Task ' || to_char(v_TaskId) || ' before automatic task processing',
                                                 Rule => 'DCM_routeCaseCCTaskCCFn',
                                                 TaskId => v_TaskId);
                v_queueParams := f_UTIL_getJSONAutoTask(v_TaskId);
                v_result := f_UTIL_addToQueueFn(RuleCode => v_TaskProcessor,
                                                Parameters => v_queueParams);
                v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                                 Location => 'After automatic task processing',
                                                 Message => 'Task ' || to_char(v_TaskId) || ' after automatic task processing',
                                                 Rule => 'DCM_routeCaseCCTaskCCFn',
                                                 TaskId => v_TaskId);
            end if;
            select count(*)
            into
                   v_result
            from   table(f_DCM_getTaskAsgnStateList(TaskId => v_TaskId))
            where  Activity = v_twTargetActivity;
            
            if v_result > 0 then
                v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                                 Location => 'Before assignment',
                                                 Message => 'Task ' || to_char(v_TaskId) || ' before assignment',
                                                 Rule => 'DCM_routeCaseCCTaskCCFn',
                                                 TaskId => v_TaskId);
                v_result := f_DCM_invokeTaskAssignProc(ProcessorName => v_TaskStateInitAssignProc,
                                                       TaskId => v_TaskId);
                v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                                 Location => 'After assignment',
                                                 Message => 'Task ' || to_char(v_TaskId) || ' after assignment',
                                                 Rule => 'DCM_routeCaseCCTaskCCFn',
                                                 TaskId => v_TaskId);
            end if;
            v_result := f_DCM_addTaskDateEventCCList(TaskId => v_TaskId,
                                                     state => v_twTargetActivity);
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                             Location => 'After setting date events',
                                             Message => 'Task ' || to_char(v_TaskId) || ' after setting date events',
                                             Rule => 'DCM_routeCaseCCTaskCCFn',
                                             TaskId => v_TaskId);
        exception
        when NO_DATA_FOUND then
            return -2;
        end;
        v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                         Location => 'After setting ot task properties',
                                         Message => 'Task ' || to_char(v_TaskId) || ' after setting task properties DATESTARTED, DATECLOSED, WORKBASKET, RESOLUTION',
                                         Rule => 'DCM_routeCaseCCTaskCCFn',
                                         TaskId => v_TaskId);
        begin
            select col_code,
                   col_activity
            into
                   v_stateCode,
                   v_state
            from   tbl_dict_taskstate
            where  col_activity = v_twTargetActivity;
        
        exception
        when NO_DATA_FOUND then
            return -1;
        end;
        --CREATE NOTIFICATION
        v_result := f_DCM_createNotification(CaseId => null,
                                             NotificationTypeCode => 'TASK_MOVED',
                                             TaskId => v_TaskId);
        v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                         Location => 'Before processing of --after task routing action-- synchronous events',
                                         Message => 'Task ' || to_char(v_TaskId) || ' before processing of --after task routing action-- synchronous events' || v_twTargetActivity,
                                         Rule => 'DCM_routeCaseCCTaskCCFn',
                                         TaskId => v_TaskId);
        --AFTER TRANSITION EVENTS
        v_result := f_DCM_processEventCC4(Message => v_Message,
                                          NextTaskId => v_TaskId,
                                          TaskState => v_stateCode,
                                          IsValid => v_IsValid);
        v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                         Location => 'After processing of --after task routing action-- synchronous events',
                                         Message => 'Task ' || to_char(v_TaskId) || ' after processing of --after task routing action-- synchronous events' || v_twTargetActivity,
                                         Rule => 'DCM_routeCaseCCTaskCCFn',
                                         TaskId => v_TaskId);
        if v_resolutionAssigned = 0 then
			v_result := F_hist_createhistoryfn(
				additionalinfo => null,
				issystem       => 1,
				MESSAGE        => null,
				messagecode    => 'TaskRouted',
				targetid       => v_TaskId,
				targettype     => 'TASK'
		   );
        elsif v_resolutionAssigned = 1 then												  
			v_result := F_hist_createhistoryfn(
				additionalinfo => null,
				issystem       => 1,
				MESSAGE        => null,
				messagecode    => 'TaskRoutedWithResolution',
				targetid       => v_TaskId,
				targettype     => 'TASK'
		   );
        end if;
        --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE
        v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
        --AFTER TRANSITION ACTION ASYNCHRONOUS EVENTS
        v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                         Location => 'Before processing of --after task routing action-- asynchronous events',
                                         Message => 'Task ' || to_char(v_TaskId) || ' before processing of --after task routing action-- asynchronous events' || v_twTargetActivity,
                                         Rule => 'DCM_routeCaseCCTaskCCFn',
                                         TaskId => v_TaskId);
        v_result := f_DCM_processEventCC7(Message => v_Message,
                                          NextTaskId => v_TaskId,
                                          EventState => v_state,
                                          IsValid => v_IsValid);
        v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                         Location => 'After processing of --after task routing action-- asynchronous events',
                                         Message => 'Task ' || to_char(v_TaskId) || ' after processing of --after task routing action-- asynchronous events' || v_twTargetActivity,
                                         Rule => 'DCM_routeCaseCCTaskCCFn',
                                         TaskId => v_TaskId);
        v_CaseInvalid := 1;
        if v_twTargetActivity = f_dcm_getTaskNewState() or v_twTargetActivity = f_dcm_getTaskStartedState() then
            v_result := f_dcm_statClear(TaskId => v_TaskId);
        end if;
        v_result := f_dcm_statCalc(TaskId => v_TaskId);
        if v_twTargetActivity = f_dcm_getTaskClosedState() then
            v_result := f_dcm_statUpdate(TaskId => v_TaskId);
        end if;
    else
        v_result := f_DCM_createTaskHistoryCC2(IsSystem => 1,
                                 Message => v_Message,
                                 TaskId => v_TaskId);
    end if;
    return v_CaseInvalid;
end;