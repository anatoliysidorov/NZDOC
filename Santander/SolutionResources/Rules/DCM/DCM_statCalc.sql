declare
  v_TaskId Integer;
  v_result number;
begin
  v_TaskId := :TaskId;
  v_result := f_dcm_statmonth (TaskId => v_TaskId);
  v_result := f_dcm_statweek (TaskId => v_TaskId);
  v_result := f_dcm_statday (TaskId => v_TaskId);
end;