declare
  v_TaskId Integer;
  v_SlaEventId Integer;
  v_stateClosed nvarchar2(255);
  v_result number;
begin
  v_TaskId := :TaskId;
  v_SlaEventId := 0;
  v_stateClosed := f_dcm_getTaskClosedState();
  for rec in (select se.col_id as SlaEventId, tsk.col_id as TaskId, tsk.col_name as TaskName, tsk.col_taskid as TaskTitle, tsk.col_casetask as CaseId,
                tsk.col_parentid as TaskParentId, tsk.col_tw_workitemtask as TaskWorkitemId, 
                setp.col_id as SlaEventTypeId, setp.col_code as SlaEventTypeCode, setp.col_name as SlaEventTypeName,
                setp.col_intervalds as SlaEventTypeIntervalDS, setp.col_intervalym as SlaEventTypeIntervalYM,
                sel.col_id as SlaEventLevelId, sel.col_code as SlaEventLevelCode, sel.col_name as SlaEventCodeName,
                det.col_id as DateEventTypeId, det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName,
                de.col_id as DateEventId, de.col_datename as DateEventName, de.col_datevalue as DateEventValue, de.col_performedby as DateEventPerformedBy,
                cast (de.col_datevalue as timestamp) as DateTimeEventValue,
                sa.col_id as SlaActionId, sa.col_code as SlaActionCode, sa.col_name as SlaActionName, sa.col_processorcode as SlaActionProcessor
                from tbl_slaevent se
                inner join tbl_task tsk on se.col_slaeventtask = tsk.col_id
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id
                inner join tbl_dict_slaeventlevel sel on se.col_slaevent_slaeventlevel = sel.col_id
                inner join tbl_dict_dateeventtype det on se.col_slaevent_dateeventtype = det.col_id
                inner join tbl_dateevent de on tsk.col_id = de.col_dateeventtask and se.col_slaevent_dateeventtype = de.col_dateevent_dateeventtype
                inner join tbl_slaaction sa on se.col_id = sa.col_slaactionslaevent
                where tsk.col_id = v_TaskId
                and de.col_datevalue + 
                (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se.col_attemptcount + 1) + 
                (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) * (se.col_attemptcount + 1) <=
                --(case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se.col_attemptcount + 1) + 
                --(case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else to_yminterval('0-0') end) * (se.col_attemptcount + 1) <=
                sysdate
                and se.col_maxattempts > se.col_attemptcount
                and twi.col_activity not in (v_stateClosed))
  loop
    v_result := f_DCM_invokeslaprocessor(ProcessorName => rec.SlaActionProcessor, SlaActionId => rec.SlaActionId);
    if v_SlaEventId <> rec.SlaEventId then
      update tbl_slaevent set col_attemptcount = col_attemptcount + 1 where col_id = rec.SlaEventId;
      v_SlaEventId := rec.SlaEventId;
    end if;
  end loop;
end;