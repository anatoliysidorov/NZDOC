declare
			  v_input    xmltype;
			  v_path     varchar2(255);
			  v_result   NCLOB := EMPTY_CLOB();
			begin
			  --EXTRACTING CASE TYPE
			  v_input := xmltype(Input);
			  v_path := Path;
			  begin
				v_result := v_input.extract(v_path).getClobval();
				EXCEPTION
				WHEN SELF_IS_NULL  THEN   
			 /*   when others then*/
				v_result := null;
			  end;
			  return v_result;
end;