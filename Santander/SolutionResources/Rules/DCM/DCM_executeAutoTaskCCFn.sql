declare
  v_CaseId Integer;
  v_stateClosed nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateNew nvarchar2(255);
  v_stateStarted nvarchar2(255);
  v_stateInProcess nvarchar2(255);
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
  v_result number;
  v_RuleCode nvarchar2(255);
  v_ExecMethod nvarchar2(255);
  v_queueParams nclob;
  v_Domain nvarchar2(255);
  v_UserAccessSubject nvarchar2(255);
begin
  v_CaseId := :CaseId;
  v_ExecMethod := 'automatic';
  v_RuleCode := '';
  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  v_stateInProcess := f_dcm_getTaskInProcessState();
  v_stateClosed := f_dcm_getTaskClosedState();
  begin
  select sys_context('CLIENTCONTEXT', 'AccessSubject') into v_UserAccessSubject from dual;
    exception
	  when NO_DATA_FOUND then
	    v_UserAccessSubject := null;
  end;
  v_owner := v_UserAccessSubject;
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  --READ DOMAIN FROM CONFIGURATION
  v_Domain := f_UTIL_getDomainFn();
  begin
    for rec in
      (select tsk.col_id as TaskId, tsk.col_id2, tsk.col_parentidcc, tsk.col_taskorder,
         tsk.col_casecctaskcc,tsk.col_tw_workitemcctaskcc, tsk.col_name as TaskName,
         tsk.col_processorname as ProcessorCode,
         dem.col_code as TaskExecMethod, dtt.col_code as TaskSysType,
         tsk.col_depth, tsk.col_leaf, tsk.col_taskid, tsk.col_datestarted, tsk.col_dateassigned, tsk.col_dateclosed,
         twi.col_activity
         from tbl_taskcc tsk
         inner join tbl_dict_executionmethod dem on tsk.col_taskccdict_executionmtd = dem.col_id
         inner join tbl_dict_tasksystype dtt on tsk.col_taskccdict_tasksystype = dtt.col_id
         inner join tbl_tw_workitemcc twi on tsk.col_tw_workitemcctaskcc = twi.col_id
         where col_casecctaskcc = v_CaseId
         and lower(dem.col_code) = 'automatic'
         and twi.col_activity = v_stateStarted)
    loop
      --SET TASK rec.TaskId IN CURSOR rec TO STATE v_stateInProcess
      update tbl_tw_workitemcc set col_activity = v_stateInProcess, col_tw_workitemccprevtaskst = col_tw_workitemccdict_taskst, col_tw_workitemccdict_taskst = (select col_id from tbl_dict_taskstate where col_activity = v_stateInProcess)
        where col_id = (select col_tw_workitemcctaskcc from tbl_taskcc where col_id = rec.TaskId);
      --SET TASK DATE EVENT
      v_result := f_DCM_createTaskDateEventCC (Name => 'DATE_TASK_IN_PROCESS', TaskId => rec.TaskId);
      --ADD TASK PROCESSOR TO EVENT QUEUE
      v_queueParams := f_UTIL_getJSONAutoTaskCC(rec.TaskId);
      v_result := f_UTIL_addToQueueFn(RuleCode => rec.ProcessorCode, Parameters => v_queueParams);
      --SAVE QUEUE EVENT ID AND TASK ID TO MONITOR AND PROCESS QUEUE EVENT EXECUTION RESULT
      insert into tbl_taskeventqueue(col_queueeventid,col_taskeventqueuetask) values(v_result,rec.TaskId);
      --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE
      v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
    end loop;
  end;
end;