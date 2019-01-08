declare
  v_result number;
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  select count(*) into v_result from tbl_slahold where col_slaholdtask = v_TaskId and col_startdate is not null and col_enddate is null;
  if v_result > 0 then
    update tbl_slahold set col_enddate = sysdate where col_slaholdtask = v_TaskId and col_enddate is null;
    :ErrorCode := 0;
    :ErrorMessage := 'Success';
    return -1;
  end if;
  :ErrorCode := 101;
  :ErrorMessage := 'Task is not on hold';
end;