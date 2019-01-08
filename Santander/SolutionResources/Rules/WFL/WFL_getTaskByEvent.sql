declare
  v_input xmltype;
  v_eventid Integer;
  v_count Integer;
  v_count2 Integer;
  v_count3 Integer;
  v_result nvarchar2(255);
  v_result2 nvarchar2(255);
  v_result3 nvarchar2(255);
begin
  v_input := :Input;
  v_eventid := :EventId;
  v_count := 1;
  while (true)
  loop
    v_result := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@id');
    if v_result is null then
      exit;
    end if;
    v_result2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@type');
    if trim(lower(v_result2)) = 'eventconnection' then
      v_result2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@source');
      v_result3 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@target');
      if v_result2 = v_eventid then
        return to_number(v_result3);
      elsif v_result3 = v_eventid then
        return to_number(v_result2);
      end if;
    end if;
    v_count := v_count + 1;
  end loop;
  return 0;

end;