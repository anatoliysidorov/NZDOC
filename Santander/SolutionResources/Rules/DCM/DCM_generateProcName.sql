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
  begin
    select count(*) into v_count from tbl_task where col_parentid = v_sourceid and lower(col_name) like lower('%' || v_name || '%');
    exception
    when NO_DATA_FOUND then
    v_count := 0;
  end;
  if v_count > 0 then
    v_resultname := v_name || to_char(v_count);
  end if;
  while (true)
  loop
    begin
      select count(*) into v_count2 from tbl_task where col_parentid = v_sourceid and lower(col_name) = lower(v_resultname);
      exception
      when NO_DATA_FOUND then
        v_count2 := 0;
    end;
    if v_count2 > 0 then
      v_count := v_count + 1;
      v_resultname := v_name || to_char(v_count);
    else
      exit;
    end if;
  end loop;
  return v_resultname;
end;