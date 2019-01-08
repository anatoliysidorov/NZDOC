declare
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  update tbl_task set col_name = col_name || '-' || to_char(col_id) where col_id = v_TaskId;
end;