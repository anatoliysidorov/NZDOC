declare
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  update tbl_task set col_taskppl_workbasket = col_taskpreviousworkbasket where col_id = v_TaskId;
end;