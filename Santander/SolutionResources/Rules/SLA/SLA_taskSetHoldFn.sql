declare
  v_result number;
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  select count(*) into v_result from tbl_slahold where col_slaholdtask = v_TaskId and col_startdate is not null and col_enddate is null;
  if v_result > 0 then
    :ErrorCode := 101;
    :ErrorMessage := 'Task is already on hold';
    return -1;
  end if;
  insert into tbl_slahold(col_slaholdtask, col_startdate) values(v_TaskId, sysdate);
  :ErrorCode := 0;
  :ErrorMessage := 'Success';
end;