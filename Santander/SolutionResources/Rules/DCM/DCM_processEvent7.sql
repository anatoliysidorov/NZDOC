declare
  v_NextTaskId Integer;
  v_CaseId Integer;
  v_result number;
  v_isValid number;
  v_EventMoment nvarchar2(255);
  v_EventState nvarchar2(255);
  v_Message nclob;
  v_UserAccessSubject nvarchar2(255);
  v_Domain nvarchar2(255);
  v_queueParams nclob;
  v_DebugSession nvarchar2(255);
begin
  v_NextTaskId := :NextTaskId;
  v_EventMoment := 'after';
  v_EventState := :EventState;
  v_isValid := 1;
  begin
    select col_casetask into v_CaseId from tbl_task where col_id = v_NextTaskId;
    exception
    when NO_DATA_FOUND then
    return v_isValid;
  end;
  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => f_dcm_getcasetypeforcase(CaseId => v_CaseId), ProcedureId => null);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEvent7 before validation begins',
                                   Message => 'Task ' || to_char(v_NextTaskId) || ' before validation event processing', Rule => 'DCM_processEvent7', TaskId => v_NextTaskId);
  begin
    select sys_context('CLIENTCONTEXT', 'AccessSubject') into v_UserAccessSubject from dual;
      exception
	    when NO_DATA_FOUND then
	      v_UserAccessSubject := null;
  end;
  --READ DOMAIN FROM CONFIGURATION
  v_Domain := f_UTIL_getDomainFn();
  --FIND LIST OF EVENTS FOR THE CURRENT TASK
  --for rec in (select col_id, col_processorname from tbl_task where col_parentid = v_nextTaskId and lower(col_systemtype) = 'event' and lower(col_type) = v_EventType)
  --FIND LIST OF EVENT PROCESSORS (RULES DEPLOYED AS FUNCTIONS) ASSOCIATED WITH CURRENT TASK
  for rec in (select tsk.col_id as col_id, te.col_id as taskeventid, te.col_processorcode as col_processorcode,
                substr(te.col_processorcode, instr(te.col_processorcode, '_', 1, 1) + 1, length(te.col_processorcode) - instr(te.col_processorcode, '_', 1, 1)) as LocalCode,
                --f_util_isrulefunction(substr(te.col_processorcode, instr(te.col_processorcode, '_', 1, 1) + 1, length(te.col_processorcode) - instr(te.col_processorcode, '_', 1, 1))) as IsFunction,
                case when lower(substr(te.col_processorcode, 1, instr(te.col_processorcode, '_', 1, 1))) = 'f_' then 1 else 0 end as IsFunction,
                tsi.col_map_taskstateinittask as taskId,
                tsi.col_map_tskstinit_initmtd as initmethod_id, tsi.col_map_tskstinit_tskst as taskstate_id,
                tst.col_code as tasktype,
                dte.col_code as taskevent, timt.col_code as taskeventinitmethodtype, im.col_code as taskinitmethod, ts.col_code as taskinitstate
                --CURRENT TASK
                from tbl_task tsk
                --JOIN TASK TO TASK SYSTEM TYPE, FOR EXAMPLE, "REVIEW"
                inner join tbl_dict_tasksystype tst on tsk.col_taskdict_tasksystype = tst.col_id
                --JOIN TO TASK INSTANTIATION
                inner join tbl_map_taskstateinitiation tsi on tsk.col_id = tsi.col_map_taskstateinittask
                --JOIN TO TASK EVENT
                inner join tbl_taskevent te on tsi.col_id = te.col_taskeventtaskstateinit
                --JOIN TO TASK STATE DICTIONARY (EXAMPLE: "ASSIGNED")
                inner join tbl_dict_taskstate ts on tsi.col_map_tskstinit_tskst = ts.col_id
                --JOIN TO TASK EVENT TYPE DICTIONARY (EXAMPLE: "VALIDATION")
                inner join tbl_dict_taskeventtype timt on te.col_taskeventtypetaskevent = timt.col_id
                --JOIN TO TASK EVENT MOMENT DICTIONARY (EXAMPLE: "BEFORE_ASSIGNED")
                inner join tbl_dict_taskeventmoment dte on te.col_taskeventmomenttaskevent = dte.col_id
                --JOIN INIT METHOD DICTIONARY (EXAMPLE: "AUTOMATIC")
                inner join tbl_dict_initmethod im on tsi.col_map_tskstinit_initmtd = im.col_id
                where tsk.col_id = v_nextTaskId
                and lower(dte.col_code) = v_EventMoment
                and lower(ts.col_activity) = lower(v_EventState)
                and lower(timt.col_code) = 'action')
  loop
    --CALL PROCESSOR FUNCTION HERE AND GET RETURN VALUE
    v_isValid := 1;
    if nvl(rec.IsFunction, 0) = 0 then
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEvent7 before invocation of validation processor',
                                       Message => 'Task ' || to_char(v_NextTaskId) || ' before invocation of validation event ' || to_char(rec.TaskEventId) || ' with processor ' || rec.col_processorcode,
                                       Rule => 'DCM_processEvent7', TaskId => v_NextTaskId);
      v_queueParams := f_util_getJSONfromAutoRulePrm(rec.taskeventid);
      v_result := f_UTIL_addToQueueFn(RuleCode => rec.col_processorcode, Parameters => v_queueParams);
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEvent7 after invocation of validation processor',
                    Message => 'Task ' || to_char(v_NextTaskId) || ' after invocation of validation event ' || to_char(rec.TaskEventId) || ' with processor ' || rec.col_processorcode || ' Validation Result: ' || to_char(v_isValid),
                    Rule => 'DCM_processEvent7', TaskId => v_NextTaskId);
    end if;
  end loop;
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEvent7 after validation',
                                   Message => 'Task ' || to_char(v_NextTaskId) || ' after validation event processing', Rule => 'DCM_processEvent7', TaskId => v_NextTaskId);
  :Message := v_Message;
  :IsValid := v_isValid;
  return v_isValid;
end;