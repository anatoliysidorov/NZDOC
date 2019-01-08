declare
  v_result number;
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  begin
    select col_casetask into v_result from tbl_task where col_id = v_TaskId;
    exception
    when NO_DATA_FOUND then
    v_result := 0;
    return v_result;
  end;
  return v_result;
end;