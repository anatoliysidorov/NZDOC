--EVENTS BEFORE_ASSIGN ARE PROCESSED AND IsValid PROPERTY IS RETURNED
--IF EVENT PROCESSOR RETURNS TRUE, NEXT TASK CAN BE INITIALIZED
--THIS FUNCTION WILL BE CALLED BY RULE DCM_setTaskStateDpndncy
--ALSO CALLED FROM DCM_closeTaskProc
declare
  v_NextTaskId Integer;
  v_CaseId Integer;
  v_result number;
  v_isValid number;
  v_EventMoment nvarchar2(255);
  v_EventState nvarchar2(255);
  v_Message nclob;
  v_DebugSession nvarchar2(255);
  v_input nvarchar2(32767);
begin
  v_NextTaskId := :NextTaskId;
  v_EventMoment := 'after';
  v_EventState := :EventState;
  v_isValid := 1;
  begin
    select col_casecctaskcc into v_CaseId from tbl_taskcc where col_id = v_NextTaskId;
    exception
    when NO_DATA_FOUND then
    return v_isValid;
  end;
  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => f_dcm_getcasetypeforcase(CaseId => v_CaseId), ProcedureId => null);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEvent6 before validation begins',
                                   Message => 'Task ' || to_char(v_NextTaskId) || ' before validation event processing', Rule => 'DCM_processEventCC6', TaskId => v_NextTaskId);
  --FIND LIST OF EVENTS FOR THE CURRENT TASK
  --for rec in (select col_id, col_processorname from tbl_task where col_parentid = v_nextTaskId and lower(col_systemtype) = 'event' and lower(col_type) = v_EventType)
  --FIND LIST OF EVENT PROCESSORS (RULES DEPLOYED AS FUNCTIONS) ASSOCIATED WITH CURRENT TASK
  for rec in (select tsk.col_id as col_id, te.col_id as TaskEventId, te.col_processorcode as col_processorcode,
                substr(te.col_processorcode, instr(te.col_processorcode, '_', 1, 1) + 1, length(te.col_processorcode) - instr(te.col_processorcode, '_', 1, 1)) as LocalCode,
                --f_util_isrulefunction(substr(te.col_processorcode, instr(te.col_processorcode, '_', 1, 1) + 1, length(te.col_processorcode) - instr(te.col_processorcode, '_', 1, 1))) as IsFunction,
                case when lower(substr(te.col_processorcode, 1, instr(te.col_processorcode, '_', 1, 1))) = 'f_' then 1 else 0 end as IsFunction,
                tsi.col_map_taskstateinitcctaskcc as taskId,
                tsi.col_map_tskstinitcc_initmtd as initmethod_id, tsi.col_map_tskstinitcc_tskst as taskstate_id,
                tst.col_code as tasktype,
                dte.col_code as taskevent, timt.col_code as taskeventinitmethodtype, im.col_code as taskinitmethod, ts.col_code as taskinitstate
                --CURRENT TASK
                from tbl_taskcc tsk
                --JOIN TASK TO TASK SYSTEM TYPE, FOR EXAMPLE, "REVIEW"
                inner join tbl_dict_tasksystype tst on tsk.col_taskccdict_tasksystype = tst.col_id
                --JOIN TO TASK INSTANTIATION
                inner join tbl_map_taskstateinitcc tsi on tsk.col_id = tsi.col_map_taskstateinitcctaskcc
                --JOIN TO TASK EVENT
                inner join tbl_taskeventcc te on tsi.col_id = te.col_taskeventcctaskstinitcc
                --JOIN TO TASK STATE DICTIONARY (EXAMPLE: "ASSIGNED")
                inner join tbl_dict_taskstate ts on tsi.col_map_tskstinitcc_tskst = ts.col_id
                --JOIN TO TASK EVENT TYPE DICTIONARY (EXAMPLE: "VALIDATION")
                inner join tbl_dict_taskeventtype timt on te.col_taskeventtypetaskeventcc = timt.col_id
                --JOIN TO TASK EVENT MOMENT DICTIONARY (EXAMPLE: "BEFORE_ASSIGNED")
                inner join tbl_dict_taskeventmoment dte on te.col_taskeventmomnttaskeventcc = dte.col_id
                --JOIN INIT METHOD DICTIONARY (EXAMPLE: "AUTOMATIC")
                inner join tbl_dict_initmethod im on tsi.col_map_tskstinitcc_initmtd = im.col_id
                where tsk.col_id = v_nextTaskId
                and lower(dte.col_code) = v_EventMoment
                and lower(ts.col_activity) = lower(v_EventState)
                and lower(timt.col_code) = 'action')
  loop
    --CALL PROCESSOR FUNCTION HERE AND GET RETURN VALUE
    v_isValid := 1;
    if rec.IsFunction = 1 then
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEventCC6 before invocation of validation processor',
                                       Message => 'Task ' || to_char(v_NextTaskId) || ' before invocation of validation event ' || to_char(rec.TaskEventId) || ' with processor ' || rec.col_processorcode,
                                       Rule => 'DCM_processEventCC6', TaskId => v_NextTaskId);
      v_input := '<CustomData><Attributes>';
      --for rec2 in (select col_paramcode as ParamCode, col_paramvalue as ParamValue from tbl_autoruleparameter where col_ruleparam_taskstateinit = (select col_taskeventtaskstateinit from tbl_taskevent where col_id = rec.TaskEventId))
      for rec2 in (select col_paramcode as ParamCode, col_paramvalue as ParamValue from tbl_autoruleparameter where col_taskeventautoruleparam = (select col_id from tbl_taskevent where col_id = rec.TaskEventId))
      loop
        v_input := v_input || '<' || rec2.ParamCode || '>' || rec2.ParamValue || '</' || rec2.ParamCode || '>';
      end loop;
      v_input := v_input || '</Attributes></CustomData>';
      v_result := f_DCM_invokeEventProcessor(Input => v_input, Message => v_Message, ProcessorName => rec.col_processorcode, TaskId => rec.col_id, validationresult => v_isValid);
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEventCC6 after invocation of validation processor',
                    Message => 'Task ' || to_char(v_NextTaskId) || ' after invocation of validation event ' || to_char(rec.TaskEventId) || ' with processor ' || rec.col_processorcode || ' Validation Result: ' || to_char(v_isValid),
                    Rule => 'DCM_processEventCC6', TaskId => v_NextTaskId);
    end if;
  end loop;
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEvent6 after validation',
                                   Message => 'Task ' || to_char(v_NextTaskId) || ' after validation event processing', Rule => 'DCM_processEvent6', TaskId => v_NextTaskId);
  :Message := v_Message;
  :IsValid := v_isValid;
  return v_isValid;
end;