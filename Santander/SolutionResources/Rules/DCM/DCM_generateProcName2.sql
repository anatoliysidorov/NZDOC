declare
  v_result number;
  v_proccode nvarchar2(255);
  v_name nvarchar2(255);
  v_resultname nvarchar2(255);
  v_count Integer;
  v_count2 Integer;
  v_sourceid Integer;
begin
  v_proccode := :ProcCode;
  v_sourceid := :SourceId;
  if v_proccode is not null then
    begin
      select col_code into v_name from tbl_procedure where lower(col_code) = lower(v_proccode);
      exception
      when NO_DATA_FOUND then
      v_name := null;
    end;
  end if;
  if v_name is null then
    v_name := :Name;
  end if;
  select gen_tbl_task.currval+1 into v_result from dual;
  v_resultname := v_name || '-' || to_char(v_result);
  return v_resultname;
end;