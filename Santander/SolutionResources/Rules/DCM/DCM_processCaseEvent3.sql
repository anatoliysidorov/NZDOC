--EVENTS AFTER_ASSIGN ARE PROCESSED AND IsValid PROPERTY IS RETURNED
--IF EVENT PROCESSOR RETURNS TRUE, NEXT TASK CAN BE INITIALIZED
declare
  v_CaseId Integer;
  v_result number;
  v_isValid number;
  v_EventMoment nvarchar2(255);
  v_EventState nvarchar2(255);
begin
  v_CaseId := :CaseId;
  v_EventMoment := 'after';
  v_EventState := :EventState;
  v_isValid := 1;
  --FIND LIST OF EVENTS FOR THE CURRENT TASK
  --for rec in (select col_id, col_processorname from tbl_task where col_parentid = v_nextTaskId and lower(col_systemtype) = 'event' and lower(col_type) = v_EventType)
  --FIND LIST OF EVENT PROCESSORS (RULES DEPLOYED AS FUNCTIONS) ASSOCIATED WITH CURRENT TASK
  for rec in (select cs.col_id as col_id, ce.col_processorcode as col_processorcode,
       substr(ce.col_processorcode, instr(ce.col_processorcode, '_', 1, 1) + 1, length(ce.col_processorcode) - instr(ce.col_processorcode, '_', 1, 1)) as LocalCode,
       --f_util_isrulefunction(substr(ce.col_processorcode, instr(ce.col_processorcode, '_', 1, 1) + 1, length(ce.col_processorcode) - instr(ce.col_processorcode, '_', 1, 1))) as IsFunction,
       case when lower(substr(ce.col_processorcode, 1, instr(ce.col_processorcode, '_', 1, 1))) = 'f_' then 1 else 0 end as IsFunction,
       csi.col_map_casestateinitcase as caseId,
       csi.col_casestateinit_initmethod as initmethod_id, csi.col_map_csstinit_csst as casestate_id,
       cst.col_code as casetype,
       dte.col_code as caseevent, timt.col_code as caseeventinitmethodtype, im.col_code as caseinitmethod, csst.col_code as caseinitstate
                --CURRENT CASE
                from tbl_case cs
                --JOIN CASE TO CASE SYSTEM TYPE, FOR EXAMPLE, "LEAKAGE"
                inner join tbl_dict_casesystype cst on cs.col_casedict_casesystype = cst.col_id
                --JOIN TO CASE INSTANTIATION
                inner join tbl_map_casestateinitiation csi on cs.col_id = csi.col_map_casestateinitcase
                --JOIN TO CASE EVENT
                inner join tbl_caseevent ce on csi.col_id = ce.col_caseeventcasestateinit
                --JOIN TO CASE STATE DICTIONARY (EXAMPLE: "ASSIGNED")
                inner join tbl_dict_casestate csst on csi.col_map_csstinit_csst = csst.col_id
                --JOIN TO TASK/CASE EVENT TYPE DICTIONARY (EXAMPLE: "VALIDATION")
                inner join tbl_dict_taskeventtype timt on ce.col_taskeventtypecaseevent = timt.col_id
                --JOIN TO TASK/CASE EVENT MOMENT DICTIONARY (EXAMPLE: "BEFORE_ASSIGNED")
                inner join tbl_dict_taskeventmoment dte on ce.col_taskeventmomentcaseevent = dte.col_id
                --JOIN INIT METHOD DICTIONARY (EXAMPLE: "AUTOMATIC")
                inner join tbl_dict_initmethod im on csi.col_casestateinit_initmethod = im.col_id
                where cs.col_id = v_CaseId
                and lower(dte.col_code) = v_EventMoment
                and lower(csst.col_activity) = lower(v_EventState)
                and lower(timt.col_code) = 'action')
  loop
    --CALL PROCESSOR FUNCTION HERE AND GET RETURN VALUE
    v_isValid := 1;
    if rec.IsFunction = 1 then
      v_result := f_DCM_invokeCaseEventProc(CaseId => rec.col_id,ProcessorName => rec.col_processorcode,validationresult => v_isValid);
    end if;
  end loop;
  :IsValid := v_isValid;
  return v_isValid;
end;
