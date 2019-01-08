declare
  v_output nclob;
  v_ProcessorName nvarchar2(255);
  v_functionName nvarchar2(255);
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_query varchar(2000);
  v_result number;
  v_TaskId number;
begin
  v_Output := EMPTY_CLOB();
  v_TaskId := :TaskId;
  v_ProcessorName := :ProcessorCode;
  v_errorCode := 0;
  v_errorMessage := '';
  begin
    select object_name into v_functionName from user_objects where object_type = 'FUNCTION' and object_name = upper(v_ProcessorName);
    exception
      when NO_DATA_FOUND then
        --v_functionName := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Event processor: '||NVL(v_ProcessorName,'Unknown')|| ' not found';
        goto cleanup;
  end;
 v_query := 'begin ' || ':'||'x := ' || v_ProcessorName || '(TaskId => '||':'||'y, Result => '||':'||'z); end;';
  --dbms_output.put_line(v_query);
  execute immediate v_query using out v_result,  v_TaskId, out v_output;
 
  <<cleanup>>
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  :Result := v_output;
end;
