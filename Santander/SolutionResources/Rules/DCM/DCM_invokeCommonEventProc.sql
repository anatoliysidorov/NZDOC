DECLARE
  v_Input         NCLOB;
  v_Message       NCLOB;
  v_ProcessorName NVARCHAR2(255);
  v_functionName  NVARCHAR2(255);
  v_ErrorCode     NUMBER;
  v_ErrorMessage  NVARCHAR2(255);
  v_query         VARCHAR(2000);
  v_count         NUMBER;
  v_first         NUMBER;
  v_result        NUMBER;
  v_validationresult NUMBER;
  v_TaskId            NUMBER;
  v_ProcedureId       NUMBER;
  v_CaseId            NUMBER;
  v_containsInput     NUMBER;
  v_BC                NUMBER;

begin
  v_Input         := :Input;
  v_ProcessorName := :ProcessorName;

  v_TaskId      := f_form_getparambyname(v_Input,'TaskId');
  v_CaseId      := f_form_getparambyname(v_Input,'CaseId');
  v_ProcedureId := f_form_getparambyname(v_Input,'ProcedureId');
  v_BC := f_form_getparambyname(v_Input,'SYS_BackwardCompatibility'); --add a backward compatibility
                                                                      --must be 1 or NULL
  v_ErrorCode     :=NULL;
  v_ErrorMessage  :=NULL;
  v_Message       := NULL;

  IF f_DBG_findDebugSession(CaseId => f_form_getparambyname(v_Input,'CaseId')) IS NOT NULL THEN
    v_result := f_DBG_addDebugTrace(CaseId => f_form_getparambyname(v_Input,'CaseId'), Location => 'Before invocation of event processor', Message => 'Before invocation of common event processor ' ||
                                    ' with processor ' || v_ProcessorName, Rule => 'DCM_invokeCommonEventProc', TaskId => f_form_getparambyname(v_Input,'TaskId'));
  END IF;


  begin
    select object_name into v_functionName from user_objects where object_type = 'FUNCTION' and object_name = upper(v_ProcessorName);
    exception
      when NO_DATA_FOUND then
        v_functionName := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Event processor not found';
        return -1;
  end;

  begin
    select count(*) into v_count
      from user_arguments
        where object_id = (select object_id from user_objects where object_type = 'FUNCTION' and object_name = upper(v_functionName))
        and not(argument_name is null and in_out = 'OUT' and position = 0);
    exception
      when NO_DATA_FOUND then
        v_count := 0;
  end;

/*
  v_functionName := UPPER(v_ProcessorName);
  v_count := f_util_check_function(FUN_INVOKER_NAME => $$plsql_unit,
                                   FUN_PROCESSOR    => v_functionName, 
                                   ERRORCODE        => v_ErrorCode, 
                                   ERRORMESSAGE     => v_ErrorMessage);
*/                                   
  IF v_count = -1 THEN     
    validationresult := 0;
    GOTO cleanup; 
  END IF;

  --backward compatibility
  IF NVL(v_BC,0)=1 THEN
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
  
    if v_count = 1 then
      execute immediate v_query using out v_result, v_TaskId;
    elsif v_count = 2 then
      execute immediate v_query using out v_result, v_TaskId, out v_validationresult;
    elsif v_count = 4 then
      execute immediate v_query using out v_result, out v_ErrorCode, out v_ErrorMessage, v_Input, out v_validationresult;
    end if;

    v_Message := v_ErrorMessage;
  END IF;

  --new executor
  IF NVL(v_BC,0)=0 THEN   
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

    IF v_containsInput = 0 THEN
      IF v_count = 1 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_CaseId; 
      END IF;
      IF v_count = 2 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_CaseId, OUT v_validationresult; 
      END IF;
      IF v_count = 3 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_CaseId, OUT v_Message,  OUT v_validationresult; 
      END IF;
      IF v_count = 4 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_CaseId, OUT v_Message, v_TaskId, OUT v_validationresult; 
      END IF;
      IF v_count = 5 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_CaseId, OUT v_Message, v_ProcedureId, v_TaskId, OUT v_validationresult; 
      END IF;
      IF v_count = 6 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_CaseId, OUT v_ErrorCode, OUT v_ErrorMessage, v_ProcedureId, v_TaskId, OUT v_validationresult; 
        v_Message :=v_ErrorMessage;
      END IF;
    END IF;

    IF v_containsInput = 1 THEN
      IF v_count = 1 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_Input; 
      END IF;
      IF v_count = 2 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_Input, OUT v_validationresult; 
      END IF;
      IF v_count = 3 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_Input, OUT v_Message, OUT v_validationresult; 
      END IF;
      IF v_count = 4 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_CaseId, v_Input, OUT v_Message,   OUT v_validationresult; 
      END IF;
      IF v_count = 5 THEN 
        EXECUTE IMMEDIATE v_query USING OUT v_result, v_CaseId, OUT v_ErrorCode, OUT v_ErrorMessage, v_Input, OUT v_validationresult; 
        v_Message :=v_ErrorMessage;
      END IF;
    END IF;      
  END IF;

  IF f_DBG_findDebugSession(CaseId => f_form_getparambyname(v_Input,'CaseId')) is not null then
    v_result := f_DBG_addDebugTrace(CaseId => f_form_getparambyname(v_Input,'CaseId'), Location => 'After invocation of event processor', Message => 'After invocation of common event processor ' ||
                                    ' with processor ' || v_ProcessorName || ' Validation Result: ' || to_char(v_validationresult), Rule => 'DCM_invokeCommonEventProc', TaskId => f_form_getparambyname(v_Input,'TaskId'));
  END IF;
  
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_Message;
  :validationresult := v_validationresult;
  RETURN 0;

  <<cleanup>>
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  :validationresult := v_validationresult;
  RETURN -1;
END;