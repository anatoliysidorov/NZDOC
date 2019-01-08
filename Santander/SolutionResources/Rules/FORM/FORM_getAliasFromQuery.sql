declare
  v_query nclob;
  v_table nvarchar2(255);
  v_position Integer;
  v_temp nclob;
  v_alias nvarchar2(255);
begin
  v_query := :Query;
  v_table := :TableName;
  if instr(v_query, v_table, 1) = 0 then
    return null;
  end if;
  v_position := instr(v_query, v_table, 1) + length(v_table);
  v_temp := trim(substr(v_query, v_position, length(v_query) - v_position + 1));
  v_position := instr(v_temp, ' ', 1);
  if v_position > 0 then
   v_alias := trim(substr(v_temp, 1, v_position));
  else
    v_alias := v_temp;
  end if;
  return v_alias;
end;