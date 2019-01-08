declare
  v_input xmltype;
  v_dependencyid Integer;
  v_sourceid Integer;
  v_targetid Integer;
  v_count Integer;
  v_result nvarchar2(255);
  v_result2 nvarchar2(255);
  v_result3 nvarchar2(255);
  v_inputType nvarchar2(255);
  v_outputType nvarchar2(255);
begin
  v_input := :Input;
  v_dependencyid := :DependencyId;
  v_sourceid := :SourceId;
  v_targetid := :TargetId;
  v_count := 1;
  while (true)
  loop
    v_result := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@id');
    if v_result is null then
      exit;
    end if;
    v_result2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@type');
    if substr(v_result2, 1, 7) = 'gateway' and (v_sourceid = to_number(v_result) or v_targetid = to_number(v_result)) then
      v_result3 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@inputSubType');
      v_inputType := v_result3;
      v_result3 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@outputSubType');
      v_outputType := v_result3;
      if v_sourceid = to_number(v_result) then
        return v_outputType;
      elsif v_targetid = to_number(v_result) then
        return v_inputType;
      end if;
    end if;
    v_count := v_count + 1;
  end loop;

end;