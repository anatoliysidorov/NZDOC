declare
  v_CaseId        NUMBER;
  v_StateEventId  NUMBER;
  v_StateId       NUMBER;

  v_ProcessorName nvarchar2(255);
  v_functionName nvarchar2(255);
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_query varchar(2000);
  v_count number;
  v_first number;
  v_containsInput number;
  v_result number;
  v_validationresult number;
  v_Message nclob;
  v_input nclob;

BEGIN

  v_StateId       := :StateId;
  v_CaseId        := :CaseId;
  v_ProcessorName := :ProcessorName;
  v_input         := :Input;
  v_StateEventId  := :StEventId;
  
  v_Message := null;
  
  v_functionName := UPPER(v_ProcessorName);
  v_count := f_util_check_function(fun_invoker_name => $$plsql_unit,fun_processor => v_functionName, ErrorCode => v_ErrorCode, ErrorMessage => v_Message);
  IF v_count = -1 THEN 
    Message := v_Message;
    validationresult := 0;
    RETURN -1; 
  END IF;

  v_first := 1;
  v_containsInput := 0;
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
      if rec.argument_name = 'INPUT' then
        v_containsInput := 1;
      end if;
      v_first := 0;
    end loop;
  v_query := v_query || '); end;';
  if v_containsInput = 0 and v_count = 1 then
    execute immediate v_query using out v_result, v_CaseId;
  elsif v_containsInput = 0 and v_count = 2 then
    execute immediate v_query using out v_result, v_CaseId, out v_validationresult;
  elsif v_containsInput = 0 and v_count = 3 then
    execute immediate v_query using out v_result, out v_Message, v_CaseId, out v_validationresult;
  elsif v_containsInput = 1 and v_count = 4 then
    execute immediate v_query using out v_result, v_CaseId, v_input, out v_Message, out v_validationresult;
  end if;

  :Message := v_Message;
  :validationresult := v_validationresult;
end;