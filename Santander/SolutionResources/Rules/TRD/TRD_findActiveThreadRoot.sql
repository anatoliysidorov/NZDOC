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
    where col_threadsourcetask = v_SrcTaskId and col_threadtargettask = v_TrgTaskId and col_parentmessageid = 0 and lower(col_status) = 'active') s1
    where s1.RowNumber = 1;
    exception
    when NO_DATA_FOUND then
    v_result := 0;
    return 0;
  end;
  if v_result > 0 then
    return v_result;
  else
    return 0;
  end if;
end;