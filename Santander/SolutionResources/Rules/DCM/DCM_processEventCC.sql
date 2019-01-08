--EVENTS BEFORE_ASSIGN ARE PROCESSED AND IsValid PROPERTY IS RETURNED
--IF EVENT PROCESSOR RETURNS TRUE, NEXT TASK CAN BE INITIALIZED
--THIS FUNCTION WILL BE CALLED BY RULE DCM_setTaskStateDpndncy
--ALSO CALLED FROM DCM_closeTaskProc
declare
  v_NextTaskId Integer;
  v_CaseId Integer;
  v_result number;
  v_isValid number;
  v_EventType nvarchar2(255);
  v_EventState nvarchar2(255);
  v_Message nclob;
  v_DebugSession nvarchar2(255);
  v_input nvarchar2(32767);
begin
  v_NextTaskId := :NextTaskId;
  v_EventType := :EventType;
  v_EventState := :EventState;
  v_isValid := 1;
  begin
    select col_casecctaskcc into v_CaseId from tbl_taskcc where col_id = v_NextTaskId;
    exception
    when NO_DATA_FOUND then
    return v_isValid;
  end;
  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => f_dcm_getcasetypeforcase(CaseId => v_CaseId), ProcedureId => null);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEvent before validation begins',
                                   Message => 'Task ' || to_char(v_NextTaskId) || ' before validation event processing', Rule => 'DCM_processEvent', TaskId => v_NextTaskId);
  --FIND LIST OF EVENTS FOR THE CURRENT TASK
  --FIND LIST OF EVENT PROCESSORS (RULES DEPLOYED AS FUNCTIONS) ASSOCIATED WITH CURRENT TASK
  for rec in (select tsk.col_id as col_id, te.col_id as TaskEventId, te.col_processorcode as col_processorcode,                                
                CASE 
                  WHEN lower(substr(te.col_processorcode, 1, instr(te.col_processorcode, '_', 1, 1))) = 'f_' then 1 
                  ELSE 0 
                END as IsFunction ,
                tsi.col_map_taskstateinitcctaskcc as taskId,
                tsi.col_map_tskstinitcc_initmtd as initmethod_id, tsi.col_map_tskstinitcc_tskst as taskstate_id,
                tst.col_code as tasktype,
                dte.col_code as taskevent, 
                timt.col_code as taskeventinitmethodtype,  ts.col_code as taskinitstate
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
                where tsk.col_id = v_nextTaskId
                AND tsk.col_taskcctask IS NULL
                and lower(dte.col_code) = v_EventType
                and lower(ts.col_activity) = lower(v_EventState)
                and lower(timt.col_code) = 'validation'
                ORDER BY te.col_taskeventorder ASC)
  loop
    --CALL PROCESSOR FUNCTION HERE AND GET RETURN VALUE
    v_isValid := 1;
    if rec.col_processorcode is not null then
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEventCC before invocation of event',
                                       Message => 'Task ' || to_char(v_NextTaskId) || ' before invocation of event ' || to_char(rec.TaskEventId) || ' with processor ' || rec.col_processorcode,
                                       Rule => 'DCM_processEventCC', TaskId => v_NextTaskId);
      v_input := '<CustomData><Attributes>';      
      for rec2 in (SELECT col_paramcode as ParamCode, col_paramvalue as ParamValue 
                   FROM tbl_autoruleparamcc 
                   WHERE col_taskeventccautoruleparmcc = 
                   (SELECT col_id FROM tbl_taskeventcc WHERE col_id = rec.TaskEventId))
      loop
        v_input := v_input || '<' || rec2.ParamCode || '>' || rec2.ParamValue || '</' || rec2.ParamCode || '>';
      end loop;
      v_input := v_input || '</Attributes></CustomData>';
      v_result := f_DCM_invokeEventProcessor(Input => v_input, Message => v_Message, ProcessorName => rec.col_processorcode,TaskId => rec.col_id,validationresult => v_isValid);
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEventCC after invocation of event',
                    Message => 'Task ' || to_char(v_NextTaskId) || ' after invocation of event ' || to_char(rec.TaskEventId) || ' with processor ' || rec.col_processorcode || ' Validation Result: ' || to_char(v_isValid),
                    Rule => 'DCM_processEventCC', TaskId => v_NextTaskId);
    end if;
    if v_isValid = 0 then
      exit;
    end if;
  end loop;
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_processEvent after validation',
                                   Message => 'Task ' || to_char(v_NextTaskId) || ' after validation event processing', Rule => 'DCM_processEvent', TaskId => v_NextTaskId);
  :IsValid := v_isValid;
  :Message := v_Message;
end;
