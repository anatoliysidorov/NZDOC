DECLARE 
    v_output       NCLOB; 
    v_templatecode NVARCHAR2(255); 
    v_templatename NVARCHAR2(255); 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
    v_query        VARCHAR(2000); 
    v_result       NUMBER; 
    v_taskid       NUMBER; 
BEGIN 
    v_output := Empty_clob();
    v_taskid := :TaskId; 
    v_templatecode := :TemplateCode; 
    v_errorcode := 0; 
    v_errormessage := ''; 

    BEGIN 
        SELECT col_code 
        INTO   v_templatename 
        FROM   tbl_message 
        WHERE  Lower(col_code) = Lower(v_templatecode); 
    EXCEPTION 
        WHEN no_data_found THEN 
          --v_TemplateName := null; 
          v_errorcode := 101; 
          v_errormessage := 'Template Code: ' ||Nvl(v_templatecode, 'Unknown') || ' not found'; 
          GOTO cleanup; 
    END; 

    v_output := f_HIST_genMsgFromTplFn(TargetType=>'task', TargetId=>v_TaskId, MessageCode=> v_templatecode); 

    <<cleanup>> 
    :ErrorCode := v_errorcode; 
    :ErrorMessage := v_errormessage; 
    :Result := v_output; 
END; 