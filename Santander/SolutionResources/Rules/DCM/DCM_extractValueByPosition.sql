declare
v_counter Integer;
v_prevPos Integer;
v_nextPos Integer;
v_strFields nclob;
v_valueStr nclob;
v_value nvarchar2(255);
v_value2 nvarchar2(255);
begin
v_counter := :counter;
v_strFields := :strFields;
v_valueStr := :valueStr;

if (v_counter = 1) then
  v_prevPos := 0;
  else
  select instr(v_strFields, ',', 1, v_counter - 1) into v_prevPos from dual;
  end if;
  select instr(v_strFields, ',', 1, v_counter) into v_nextPos from dual;
  if (v_prevPos <> 0 AND v_nextPos = 0) then
  v_nextPos := length(v_strFields) + 1;
  end if;
  select substr(v_strFields, v_prevPos + 1, v_nextPos - v_prevPos - 1) into v_value from dual;
  -- dbms_output.put_line(v_value);
  if (v_counter = 1) then
  v_prevPos := 0;
  else
  select instr(v_valueStr, ',', 1, v_counter - 1) into v_prevPos from dual;
  end if;
  select instr(v_valueStr, ',', 1, v_counter) into v_nextPos from dual;
  if (v_prevPos <> 0 AND v_nextPos = 0) then
  v_nextPos := length(v_valueStr) + 1;
  end if;
  select substr(v_valueStr, v_prevPos + 1, v_nextPos - v_prevPos - 1) into v_value2 from dual;
  :fieldName := v_value;
  :fieldValue := v_value2;
end;

