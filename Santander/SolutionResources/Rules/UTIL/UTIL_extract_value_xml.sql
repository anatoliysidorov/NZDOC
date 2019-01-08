declare
  v_input    xmltype;
  v_path     varchar2(255);
  v_result   varchar2(32000);
  v_result2 nvarchar2(32000);
  v_position Integer;
begin
  --EXTRACTING CASE TYPE
  v_input := :Input;
  v_path := :Path;
  BEGIN
    IF  v_input.existsnode(v_path) = 1 THEN
      v_result := substr(v_input.extract(v_path).getStringval(), 1, 32000);

      v_position := instr(v_result, '<![CDATA[');
      if v_position > 0 then
        v_position := v_position + length('<![CDATA[');
        v_result2 := substr(v_result, v_position);
        v_position := instr(v_result2, ']]>');
        v_result := substr(v_result2, 1, (v_position - 1));
      end if;

      v_result := REPLACE(v_result, '''', '''''');
    ELSE
      v_result := NULL;
    END IF;

  end;
  return v_result;

end;