declare

v_pos Integer;
v_posNext Integer;
v_posDelimiter Integer;
v_inputStr nclob;
v_strPortion nvarchar2(255);
v_strOrder nvarchar2(255);
v_strField nvarchar2(255);
v_counter Integer;
v_strFields nclob;
v_strOrders nclob;

begin

v_inputStr := :inputStr;

v_pos := -1;
v_posNext := -1;
v_counter := 0;
v_strFields := '';
while (true)
loop
if (v_counter = 0) then
v_pos := 0;
select instr(v_inputStr, '|', 1, v_counter+1) into v_posNext from dual;
select substr(v_inputStr, v_pos + 1, v_posNext - v_pos - 1) into v_strPortion from dual;
select instr(v_strPortion, ':', 1, 1) into v_posDelimiter from dual;
select substr(v_strPortion, 1, v_posDelimiter - 1) into v_strOrder from dual;
select substr(v_strPortion, v_posDelimiter + 1, length(v_strPortion) - v_posDelimiter) into v_strField from dual;
v_strFields := v_strField;
v_strOrders := v_strOrder;
v_counter := v_counter + 1;
end if;
select instr(v_inputStr, '|', 1, v_counter) into v_pos from dual;
if (v_pos = 0) then
  exit;
end if;
select instr(v_inputStr, '|', 1, v_counter+1) into v_posNext from dual;
if (v_pos > 0 AND v_posNext = 0) then
  v_posNext := length(v_inputStr) + 1;
end if;
select substr(v_inputStr, v_pos + 1, v_posNext - v_pos - 1) into v_strPortion from dual;
select instr(v_strPortion, ':', 1, 1) into v_posDelimiter from dual;
select substr(v_strPortion, 1, v_posDelimiter - 1) into v_strOrder from dual;
select substr(v_strPortion, v_posDelimiter + 1, length(v_strPortion) - v_posDelimiter) into v_strField from dual;
if (v_strFields is null) then
v_strFields := v_strFields || v_strField;
else
v_strFields := v_strFields || ',' || v_strField;
end if;
if (v_strOrders is null) then
v_strOrders := v_strOrders || v_strOrder;
else
v_strOrders := v_strOrders || ',' || v_strOrder;
end if;
v_counter := v_counter + 1;
end loop;

:fields := v_strFields;
:orders := v_strOrders;

end;
