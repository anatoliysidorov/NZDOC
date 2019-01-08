declare
  v_result number;
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  v_result := 1;
  :ValidationResult := v_result;
end;