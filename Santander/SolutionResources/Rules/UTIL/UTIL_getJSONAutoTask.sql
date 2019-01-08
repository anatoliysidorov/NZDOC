declare
  v_TaskId Integer;
  v_data nclob :='[';
begin
  v_TaskId := :TaskId;
  for rec in (
    select col_ParamCode, col_ParamValue
      from tbl_AutoRuleParameter
      where col_autoruleparametertask = v_TaskId
  )
  loop
    if (upper(rec.col_ParamCode) != 'TASKID') then
      v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';
    end if;
  end loop;
  v_data := v_data || '{"name": "TaskId", "value": ' || v_TaskId || '} ] ';
  return v_data;
end;