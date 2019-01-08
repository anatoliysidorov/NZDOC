declare
  v_CaseStateInitId Integer;
  v_ProcessorName nvarchar2(255);
  v_functionName nvarchar2(255);
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_query varchar(2000);
  v_first number;
  v_result number;
  v_caseresult number;
  v_count NUMBER;
begin
  v_CaseStateInitId := :CaseStateinitId;
  v_ProcessorName := :ProcessorName;
/*  begin
    select object_name into v_functionName from user_objects where object_type = 'FUNCTION' and object_name = upper(v_ProcessorName);
	exception
	  when NO_DATA_FOUND then
	    v_functionName := null;
		v_ErrorCode := 101;
		v_ErrorMessage := 'Event processor not found';
		return -1;
  end; */

v_functionName := upper(v_ProcessorName);
    v_count := f_util_check_function(fun_invoker_name => $$plsql_unit,fun_processor => v_functionName, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
IF v_count = -1 THEN 
    RETURN -1;
END IF;

  v_first := 1;
  v_query := 'begin ' || ':' || 'v_result := ' || v_functionName || '(';
  for rec in (select object_name, object_id, argument_name, position, sequence, data_type, defaulted, default_value, default_length, in_out, data_length, pls_type, char_used
                  from user_arguments where object_id = (select object_id from user_objects where object_type = 'FUNCTION' and object_name = upper(v_functionName))
                    and not(argument_name is null and in_out = 'OUT' and position = 0)
                    order by position)
    loop
      if v_first = 0 then
        v_query := v_query || ',';
      end if;
      v_query := v_query || rec.argument_name || ' => ' || ':' || 'v_' || rec.argument_name;
      v_first := 0;
    end loop;
  v_query := v_query || '); end;';
  execute immediate v_query using out v_result, out v_caseresult,  v_CaseStateInitId;
  return v_caseresult;
end;