DECLARE 
    v_functionargument     NUMBER;
    v_query                VARCHAR(2000);
    v_functionname         NVARCHAR2(255);
    v_argumentname         NVARCHAR2(255);
      v_errorcode        NUMBER;
    v_errormessage NVARCHAR2(255);
BEGIN
    v_functionname         := :Function_Name;
    v_errorcode    := 0;
    v_errormessage := '';
    
     IF v_functionname IS  NULL  THEN
        v_errorCode    := 120;
        v_errorMessage := 'Sorry, function name is empty';
        GOTO cleanup;
     END IF;

  
     BEGIN         
          SELECT UPPER(argument_name) INTO v_argumentname
          FROM user_arguments
          WHERE object_id = (SELECT object_id FROM user_objects WHERE object_type = 'FUNCTION' AND UPPER(object_name) = upper(v_functionname))
          AND in_out != 'OUT'
          AND ARGUMENT_NAME IS NOT NULL
          AND rownum = 1;
     EXCEPTION
          WHEN NO_DATA_FOUND THEN  v_argumentname := 'NONE';
     END;
     
     IF v_argumentname IN ('TASKID', 'TASK_ID') THEN
            v_functionargument := :Task_Id;
     END IF;

    IF v_argumentname IN ('CASEID','CASE_ID') THEN
        v_functionargument := :Case_Id;
    END IF;

    IF v_argumentname IN ('EXTERNALPARTY_ID','EXTERNALPARTYID') THEN
        v_functionargument := :ExternalParty_Id;
    END IF;

 
     IF v_argumentname NOT IN ('TASKID', 'TASK_ID','CASEID','CASE_ID','EXTERNALPARTY_ID','EXTERNALPARTYID')  THEN
        v_errorCode    := 120;
        v_errorMessage := 'Sorry, cannot find argument name';
        GOTO cleanup;
     END IF;
  
    v_query := 'DECLARE 
                    res NVARCHAR2(255);
                    placeholder NVARCHAR2(255);
                BEGIN
                    res := '||v_functionname||'(placeholder , '||v_argumentname||' => ' ||v_functionargument||'); 
                    :' ||'plh:= placeholder; 
                END;';

    EXECUTE IMMEDIATE v_query USING OUT  :placeholder;
    --dbms_output.put_line(v_query);
      
     <<cleanup>>
    :errorCode    := v_errorcode;
    :errorMessage := v_errormessage;
    --dbms_output.put_line(v_errorcode);
    --dbms_output.put_line(v_errormessage);

END;