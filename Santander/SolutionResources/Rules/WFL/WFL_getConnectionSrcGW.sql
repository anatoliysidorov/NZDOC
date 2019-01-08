declare
  v_input xmltype;
  v_connectionid Integer;
  v_gatewayid Integer;
  v_count Integer;
  v_count2 Integer;
  v_count3 Integer;
  v_result nvarchar2(255);
  v_result2 nvarchar2(255);
  v_result3 nvarchar2(255);
  v_result4 Integer;
  v_sourceid Integer;
  v_sourceid2 Integer;
  v_targetid Integer;
begin
  v_input := :Input;
  v_connectionid := :ConnectionId;
  v_count := 1;
  while (true)
  loop
    v_result := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@id');
    if v_result is null then
      exit;
    end if;
    v_result2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@type');
    if substr(v_result2, 1, 10) = 'connection' and v_connectionid = to_number(v_result) then
      v_sourceid := to_number(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@source'));
      v_targetid := to_number(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@target'));
      v_result4 := f_WFL_getGWInConnCount(GatewayId => v_sourceid, Input => v_input);
      --v_result4 = 1 or v_result4 > 1 means that the source task is the gateway
      --in such case we need to find source task for incoming connection to the gateway
      --first find source gateway for the current connection
      v_count2 := 1;
      loop
        v_result := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count2) || ']/@id');
        if v_result is null then
          exit;
        end if;
        v_gatewayid := to_number(v_result);
        v_result2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count2) || ']/@type');
        if v_result4 = 1 and substr(v_result2, 1, 7) = 'gateway' and v_sourceid = to_number(v_result) then
          --find incoming connection to the gateway
          v_count3 := 1;
          loop
            v_result := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count3) || ']/@id');
            if v_result is null then
              exit;
            end if;
            v_result2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count3) || ']/@type');
            if substr(v_result2, 1, 10) = 'connection' and v_gatewayid = to_number(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count3) || ']/@target')) then
              v_sourceid2 := to_number(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count3) || ']/@source'));
              return v_sourceid2;
            end if;
            v_count3 := v_count3 + 1;
          end loop;
        end if;
        v_count2 := v_count2 + 1;
      end loop;
      return 0;
    end if;
    v_count := v_count + 1;
  end loop;


end;