declare
  v_TransactionId Integer;
  v_SlaActionId Integer;
  v_counter Integer;
  v_lastcounter Integer;
begin
  v_TransactionId := :TransactionId;
  select gen_tbl_slaevent.nextval into v_counter from dual;
  begin
    insert into tbl_slaevent(col_slaeventtask, col_slaeventdict_slaeventtype, col_slaevent_dateeventtype, col_intervalds, col_intervalym, col_slaevent_slaeventlevel, col_maxattempts, col_attemptcount, col_slaeventorder)
    (select tsk.col_id, se.col_slaeventdict_slaeventtype, se.col_slaevent_dateeventtype, se.col_intervalds, se.col_intervalym, se.col_slaevent_slaeventlevel, se.col_maxattempts, se.col_attemptcount, se.col_slaeventorder
       from tbl_slaevent se
         inner join tbl_task tsk on se.col_slaeventtasktemplate = tsk.col_id2
         where tsk.col_transactionid = v_TransactionId);
    select gen_tbl_slaevent.currval into v_lastcounter from dual;
    for rec2 in (select tsk.col_id2 as TaskTmplId, se2.col_id as SlaEventId, sa.col_id as SlaActionId, sa.col_code as SlaActionCode, sa.col_name as SlaActionName,
                 sa.col_processorcode as SlaActionProcCode, sa.col_slaaction_slaeventlevel as SlaEventLevel,
                 sa.col_actionorder as SlaActionOrder
                 from tbl_slaaction sa
                 inner join tbl_slaevent se on sa.col_slaactionslaevent = se.col_id
                 inner join tbl_task tsk on se.col_slaeventtasktemplate = tsk.col_id2
                 inner join tbl_slaevent se2 on tsk.col_id = se2.col_slaeventtask and se.col_slaeventorder = se2.col_slaeventorder
                 where se.col_id in (select se.col_id
                                     from tbl_slaevent se
                                     inner join tbl_task tsk on se.col_slaeventtasktemplate = tsk.col_id2
                                     where tsk.col_transactionid = v_TransactionId)
                 and tsk.col_transactionid = v_TransactionId
                 order by sa.col_actionorder)
    loop
      insert into tbl_slaaction(col_code, col_name, col_processorcode, col_slaactionslaevent, col_slaaction_slaeventlevel, col_actionorder)
      values(sys_guid(), rec2.SlaActionName, rec2.SlaActionProcCode, rec2.SlaEventId, rec2.SlaEventLevel, rec2.SlaActionOrder);
      select gen_tbl_slaaction.currval into v_SlaActionId from dual;
      for rec3 in (select arp.col_paramcode as ParamCode, col_paramvalue as ParamValue
                   from tbl_autoruleparameter arp
                   inner join tbl_slaaction sa on arp.col_autoruleparamslaaction = sa.col_id
                   inner join tbl_slaevent se on sa.col_slaactionslaevent = se.col_id
                   inner join tbl_tasktemplate tt on se.col_slaeventtasktemplate = tt.col_id
                   where tt.col_id = rec2.TaskTmplId and sa.col_id = rec2.SlaActionId)
      loop
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_SlaActionId, rec3.ParamCode, rec3.ParamValue);
      end loop;
    end loop;
     exception
       when DUP_VAL_ON_INDEX then
         return -1;
       when OTHERS then
         return -1;
  end;
  select gen_tbl_slaevent.currval into v_lastcounter from dual;
  for rec in (select col_id from tbl_slaevent where col_id between v_counter and v_lastcounter)
  loop
    update tbl_slaevent set col_code = sys_guid() where col_id = rec.col_id;
  end loop;

end;