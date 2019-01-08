declare
  v_TaskId Integer;
  v_TaskEventMoment nvarchar2(255);
  v_TaskEventType nvarchar2(255);
  v_TaskState nvarchar2(255);
  v_StateId Integer;
  v_result     nclob;

begin
  v_TaskId := :TaskId;
  v_TaskEventMoment := lower(:TaskEventMoment);
  v_TaskEventType := lower(:TaskEventType);
  v_TaskState := :TaskState;

  v_result := '<Parameters></Parameters>';

  for rec in (select tsk.col_id as TaskId, tsi.col_id as TaskStateInitId, te.col_id as TaskEventId, te.col_processorcode as EventProcessor,
          arp.col_id as AutoRuleParamId, arp.col_paramcode as AutoRuleParamCode, arp.col_paramvalue as AutoRuleParamValue,
          twi.col_activity as TaskActivityCode, twi.col_tw_workitemdict_taskstate as TaskStateId,
          tem.col_code as TaskEventMoment,
          tet.col_code as TaskEventType
   from tbl_task tsk
   inner join tbl_map_taskstateinitiation tsi on tsk.col_id = tsi.col_map_taskstateinittask
   inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
   inner join tbl_dict_taskstate ts on tsi.col_map_tskstinit_tskst = ts.col_id and ts.col_activity = v_TaskState
   inner join tbl_taskevent te on tsi.col_id = te.col_taskeventtaskstateinit
   inner join tbl_dict_taskeventmoment tem on te.col_taskeventmomenttaskevent = tem.col_id
   inner join tbl_dict_taskeventtype tet on te.col_taskeventtypetaskevent = tet.col_id
   inner join tbl_autoruleparameter arp on te.col_id = arp.col_taskeventautoruleparam
   where tsk.col_id = v_TaskId
   and lower(tem.col_code) = v_TaskEventMoment
   and lower(tet.col_code) = v_TaskEventType
   /*and twi.col_activity = v_TaskState*/)
  loop
    v_result := f_form_appendParameter(EventId => rec.TaskEventId, EventProc => rec.EventProcessor, Input => v_result, ParamName => rec.AutoRuleParamCode, ParamValue => rec.AutoRuleParamValue, StateId => rec.TaskStateId);
  end loop;
  begin
    select col_tw_workitemdict_taskstate into v_StateId from tbl_tw_workitem twi inner join tbl_task tsk on twi.col_id = tsk.col_tw_workitemtask where tsk.col_id = v_TaskId;
    exception
    when NO_DATA_FOUND then
    v_StateId := null;
  end;
  v_result := f_form_appendParameter(EventId => null, EventProc => null, Input => v_result, ParamName => 'TaskId', ParamValue => to_char(v_TaskId), StateId => v_StateId);

  return v_result;

end;