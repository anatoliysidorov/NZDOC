declare
  v_input xmltype;
  v_gatewayid Integer;
  v_count Integer;
  v_count2 Integer;
  v_count3 Integer;
  v_result nvarchar2(255);
  v_result2 nvarchar2(255);
  v_result3 nvarchar2(255);
  v_inputType nvarchar2(255);
  v_outputType nvarchar2(255);
begin
  v_input := :Input;
  v_gatewayid := :GatewayId;
  v_count := 1;
  while (true)
  loop
    v_result := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@id');
    if v_result is null then
      exit;
    end if;
    v_result2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@type');
    if substr(v_result2, 1, 7) = 'gateway' and v_gatewayid = to_number(v_result) then
      v_count3 := 0;
      v_count2 := 1;
      loop
        v_result := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count2) || ']/@id');
        if v_result is null then
          exit;
        end if;
        v_result2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count2) || ']/@type');
        if substr(v_result2, 1, 10) = 'connection' and v_gatewayid = to_number(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count2) || ']/@target')) then
          v_count3 := v_count3 + 1;
        end if;
        v_count2 := v_count2 + 1;
      end loop;
      return v_count3;
    end if;
    v_count := v_count + 1;
  end loop;
  return 0;

end;