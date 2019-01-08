declare
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  update tbl_task set col_statupdated = 0 where col_id = v_TaskId;
end;