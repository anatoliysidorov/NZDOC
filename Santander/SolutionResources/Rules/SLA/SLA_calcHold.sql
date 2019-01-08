declare
  v_TaskId Integer;
  v_result interval day to second;
  v_WorkInterval nvarchar2(255);
  v_CurrDate date;
  v_result2 number;
  v_Deduction interval day to second;
  v_count Integer;
begin
  v_TaskId := :TaskId;
  v_result := to_dsinterval('0 0' || ':' || '0' || ':' || '0');
  for rec in (select col_id, col_startdate, col_enddate from tbl_slahold where col_slaholdtask = v_TaskId)
  loop
    v_result := v_result + numtodsinterval(rec.col_enddate - rec.col_startdate, 'DAY') - to_dsinterval(f_SLA_calcWendsHdays(EndDate => rec.col_enddate, StartDate => rec.col_startdate));
  end loop;
  return to_char(v_result);
end;