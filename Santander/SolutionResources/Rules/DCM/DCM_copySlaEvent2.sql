declare
  v_CaseId Integer;
  v_SlaEventId Integer;
  v_counter Integer;
  v_lastcounter Integer;
begin
  v_CaseId := :CaseId;
  for rec in
    (select se.col_id as SlaEventId, tsk.col_id as TaskId, se.col_slaeventdict_slaeventtype as SlaEventType, se.col_slaevent_dateeventtype as DateEventType,
       se.col_intervalds as SlaEventIntervalDS, se.col_intervalym as SlaEventIntervalYM, se.col_slaevent_slaeventlevel as SlaEventLevel,
       se.col_maxattempts as MaxAttempts, se.col_attemptcount as AttemptCount, se.col_slaeventorder as SlaEventOrder
       from tbl_slaevent se
         inner join tbl_task tsk on se.col_slaeventtasktemplate = tsk.col_id2
         where tsk.col_casetask = v_CaseId)
  loop
    insert into tbl_slaevent(col_code, col_slaeventtask, col_slaeventdict_slaeventtype, col_slaevent_dateeventtype, col_intervalds, col_intervalym, col_slaevent_slaeventlevel, col_maxattempts, col_attemptcount, col_slaeventorder)
    values(sys_guid(), rec.TaskId, rec.SlaEventType, rec.DateEventType, rec.SlaEventIntervalDS, rec.SlaEventIntervalYM, rec.SlaEventLevel, rec.MaxAttempts, rec.AttemptCount, rec.SlaEventOrder);
    select gen_tbl_slaevent.currval into v_SlaEventId from dual;
    select gen_tbl_slaaction.nextval into v_counter from dual;
    begin
      insert into tbl_slaaction(col_code, col_name, col_processorcode, col_slaactionslaevent, col_slaaction_slaeventlevel, col_actionorder)
      (select null, sa.col_name, sa.col_processorcode, v_SlaEventId, sa.col_slaaction_slaeventlevel, sa.col_actionorder
         from tbl_slaaction sa
           inner join tbl_slaevent se on sa.col_slaactionslaevent = se.col_id
           inner join tbl_task tsk on se.col_slaeventtasktemplate = tsk.col_id2
           where se.col_id = rec.SlaEventId and tsk.col_casetask = v_CaseId);
       exception
         when DUP_VAL_ON_INDEX then
           return -1;
         when OTHERS then
           return -1;
    end;
    select gen_tbl_slaaction.currval into v_lastcounter from dual;
    for rec in (select col_id from tbl_slaaction where col_id between v_counter and v_lastcounter)
    loop
      update tbl_slaaction set col_code = sys_guid() where col_id = rec.col_id;
    end loop;
  end loop;
  /*
  begin
    insert into tbl_slaevent(col_slaeventtask, col_slaeventdict_slaeventtype, col_slaevent_dateeventtype, col_intervalds, col_intervalym, col_slaevent_slaeventlevel, col_maxattempts, col_attemptcount)
    (select tsk.col_id, se.col_slaeventdict_slaeventtype, se.col_slaevent_dateeventtype, se.col_intervalds, se.col_intervalym, se.col_slaevent_slaeventlevel, se.col_maxattempts, se.col_attemptcount
       from tbl_slaevent se
         inner join tbl_task tsk on se.col_slaeventtasktemplate = tsk.col_id2
         where tsk.col_casetask = v_CaseId);
     exception
       when DUP_VAL_ON_INDEX then
         return -1;
       when OTHERS then
         return -1;
  end;
  begin
    insert into tbl_slaaction(col_code, col_name, col_processorcode, col_slaactionslaevent, col_slaaction_slaeventlevel, col_actionorder)
    (select sa.col_code, sa.col_name, sa.col_processorcode, se2.col_id, sa.col_slaaction_slaeventlevel, sa.col_actionorder
       from tbl_slaevent se
         inner join tbl_task tsk on se.col_slaeventtasktemplate = tsk.col_id2
         inner join tbl_slaevent se2 on tsk.col_id = se2.col_slaeventtask
         inner join tbl_slaaction sa on se.col_id = sa.col_slaactionslaevent
         where tsk.col_casetask = v_CaseId);
     exception
       when DUP_VAL_ON_INDEX then
         return -1;
       when OTHERS then
         return -1;
  end;
  */
end;