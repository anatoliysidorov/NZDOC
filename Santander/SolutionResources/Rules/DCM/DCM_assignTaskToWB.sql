declare
  v_TaskId Integer;
  v_WorkbasketId Integer;
begin
  v_TaskId := :TaskId;
  v_WorkbasketId := :WorkbasketId;
  update tbl_task set col_taskppl_workbasket = v_WorkbasketId where col_id = v_TaskId;
end;