declare
  v_CaseId Integer;
  v_SlaEventId Integer;
  v_SlaActionId Integer;
  v_lastcounter number;
begin
  v_CaseId := :CaseId;
  :ErrorCode := 0;
  :ErrorMessage := null;
  begin
  for rec in
    (select se.col_id as SlaEventId, tsk.col_id as TaskId, tsk.col_id2 as TaskTmplId, se.col_slaeventtp_slaeventtype as SlaEventType, se.col_slaeventtp_dateeventtype as DateEventType,
       se.col_intervalds as SlaEventIntervalDS, se.col_intervalym as SlaEventIntervalYM, se.col_slaeventtp_slaeventlevel as SlaEventLevel,
       se.col_maxattempts as MaxAttempts, se.col_attemptcount as AttemptCount, se.col_slaeventorder as SlaEventOrder
       from tbl_slaeventtmpl se
         inner join tbl_taskcc tsk on se.col_slaeventtptasktemplate = tsk.col_id2
         where tsk.col_casecctaskcc = v_CaseId)
  loop
    insert into tbl_slaeventcc(col_code, col_slaeventcctaskcc, col_slaeventcc_slaeventtype, col_slaeventcc_dateeventtype, col_intervalds, col_intervalym, col_slaeventcc_slaeventlevel, col_maxattempts, col_attemptcount, col_slaeventorder)
    values(sys_guid(), rec.TaskId, rec.SlaEventType, rec.DateEventType, rec.SlaEventIntervalDS, rec.SlaEventIntervalYM, rec.SlaEventLevel, rec.MaxAttempts, rec.AttemptCount, rec.SlaEventOrder);
    select gen_tbl_slaeventcc.currval into v_SlaEventId from dual;
    for rec2 in (select sa.col_id as SlaActionId, sa.col_code as SlaActionCode, sa.col_name as SlaActionName, sa.col_processorcode as SlaActionProcCode, sa.col_slaactiontp_slaeventlevel as SlaEventLevel,
                 sa.col_actionorder as SlaActionOrder
                 from tbl_slaactiontmpl sa
                 inner join tbl_slaeventtmpl se on sa.col_slaactiontpslaeventtp = se.col_id
                 inner join tbl_taskcc tsk on se.col_slaeventtptasktemplate = tsk.col_id2
                 where se.col_id = rec.SlaEventId and tsk.col_casecctaskcc = v_CaseId
                 order by sa.col_actionorder)
    loop
      insert into tbl_slaactioncc(col_code, col_name, col_processorcode, col_slaactionccslaeventcc, col_slaactioncc_slaeventlevel, col_actionorder)
      values(sys_guid(), rec2.SlaActionName, rec2.SlaActionProcCode, v_SlaEventId, rec2.SlaEventLevel, rec2.SlaActionOrder);
      select gen_tbl_slaactioncc.currval into v_SlaActionId from dual;
      for rec3 in (select arp.col_paramcode as ParamCode, col_paramvalue as ParamValue
                   from tbl_autoruleparamtmpl arp
                   inner join tbl_slaactiontmpl sa on arp.col_autorulepartpslaactiontp = sa.col_id
                   inner join tbl_slaeventtmpl se on sa.col_slaactiontpslaeventtp = se.col_id
                   inner join tbl_tasktemplate tt on se.col_slaeventtptasktemplate = tt.col_id
                   where tt.col_id = rec.TaskTmplId and sa.col_id = rec2.SlaActionId)
      loop
        insert into tbl_autoruleparamcc(col_autoruleparccslaactioncc, col_paramcode, col_paramvalue)
        values(v_SlaActionId, rec3.ParamCode, rec3.ParamValue);
        select gen_tbl_autoruleparamcc.currval into v_lastcounter from dual;
        update tbl_autoruleparamcc set col_code = sys_guid() where col_id = v_lastcounter;
      end loop;
    end loop;
  end loop;
  exception 
    when OTHERS then
     :ErrorCode := 100;
     :ErrorMessage := 'DCM_copySlaEventCC: ' || SUBSTR(SQLERRM, 1, 200);
  end;
end;