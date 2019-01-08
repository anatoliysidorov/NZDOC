  declare
  v_counter Integer;
  v_minOrder Integer;
  v_maxOrder Integer;
  v_prevPos Integer;
  v_nextPos Integer;
  v_strOrders nclob;
  v_value nvarchar2(255);
  v_ivalue number;
  begin
  v_strOrders := :strOrders;
  v_counter := 0;
  v_minOrder := 1000000;
  v_maxOrder := -1000000;
  while (true)
  loop
  if (v_counter = 0) then
  v_prevPos := 0;
  select instr(v_strOrders, ',', 1, v_counter+1) into v_nextPos from dual;
  select substr(v_strOrders, v_prevPos + 1, v_nextPos - v_prevPos - 1) into v_value from dual;
  -- dbms_output.put_line('Prev Pos: ' || v_prevPos || ' Next Pos: ' || v_nextPos || ' Value: ' || v_value);
  begin
  select to_number(v_value) into v_ivalue from dual where regexp_like(v_value,'^[['||':'||'digit'||':'||']]+$');
  exception
  when others then
  v_ivalue := null;
  end;
  if (v_ivalue < v_minOrder) then
    v_minOrder := v_ivalue;
  end if;
  if (v_ivalue > v_maxOrder) then
    v_maxOrder := v_ivalue;
  end if;
  -- dbms_output.put_line('Min Order: ' || v_minOrder || ' Max Order: ' || v_maxOrder);
  v_counter := v_counter + 1;
  end if;
  select instr(v_strOrders, ',', 1, v_counter) into v_prevPos from dual;
  select instr(v_strOrders, ',', 1, v_counter + 1) into v_nextPos from dual;
  if (v_prevPos <> 0 AND v_nextPos = 0) then
  v_nextPos := length(v_strOrders) + 1;
  end if;
  select substr(v_strOrders, v_prevPos + 1, v_nextPos - v_prevPos - 1) into v_value from dual;
  -- dbms_output.put_line('Prev Pos: ' || v_prevPos || ' Next Pos: ' || v_nextPos || ' Value: ' || v_value);
  begin
  select to_number(v_value) into v_ivalue from dual where regexp_like(v_value,'^[['||':'||'digit'||':'||']]+$');
  exception
  when others then
  v_ivalue := null;
  end;
  if (v_ivalue < v_minOrder) then
    v_minOrder := v_ivalue;
  end if;
  if (v_ivalue > v_maxOrder) then
    v_maxOrder := v_ivalue;
  end if;
  -- dbms_output.put_line('Min Order: ' || v_minOrder || ' Max Order: ' || v_maxOrder);
  if(v_prevPos = 0) then
    exit;
  end if;
  v_counter := v_counter + 1;
  end loop;
  :minOrder := v_minOrder;
  :maxOrder := v_maxOrder;
  end;
  