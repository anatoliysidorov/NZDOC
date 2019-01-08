declare
  v_input nclob;
  v_param nvarchar2(255);
  v_result nvarchar2(32767);
  v_result2 nvarchar2(32767);
  v_position Integer;
begin
  v_input := Input;
  v_param := Param;
  v_result := f_UTIL_getParamFromXML(v_input, v_param);
  v_position := instr(v_result, '<![CDATA[');
  if v_position > 0 then
    v_position := v_position + length('<![CDATA[');
    v_result2 := substr(v_result, v_position);
    v_position := instr(v_result2, ']]>');
    v_result2 := substr(v_result2, 1, (v_position - 1));
  else
    v_result2 := v_result;
  end if;
  return v_result2;
end;