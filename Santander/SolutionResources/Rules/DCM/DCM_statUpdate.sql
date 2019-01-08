declare
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  update tbl_task set col_statupdated = 1 where col_id = v_TaskId;
end;