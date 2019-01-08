declare
  v_result number;
  v_SrcTaskId Integer;
  v_TrgTaskId Integer;
begin
  v_SrcTaskId := :SourceTaskId;
  v_TrgTaskId := :TargetTaskId;
  begin
    select s1.ThreadId into v_result
    from
    (select col_id as ThreadId, row_number() over (order by col_id desc) as RowNumber from tbl_thread
    where col_threadsourcetask = v_SrcTaskId and col_threadtargettask = v_TrgTaskId and lower(col_status) = 'closed') s1
    where s1.RowNumber = 1;
    exception
    when NO_DATA_FOUND then
    v_result := 0;
  end;
  if v_result > 0 then
    update tbl_thread set col_status = 'ACTIVE', col_datereopen = sysdate where col_threadsourcetask = v_SrcTaskId and col_threadtargettask = v_TrgTaskId;
  end if;
  return v_result;
end;