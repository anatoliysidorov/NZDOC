DECLARE 
    v_taskid        INTEGER; 
    v_processorname NVARCHAR2(255); 
    v_functionname  NVARCHAR2(255); 
    v_errorcode     NUMBER; 
    v_errormessage  NVARCHAR2(255); 
    v_query         VARCHAR(2000); 
    v_first         NUMBER; 
    v_result        NUMBER; 
    v_msgphresult   NVARCHAR2(255); 
BEGIN 
    v_taskid := :TaskId; 
    v_processorname := :ProcessorName; 

    BEGIN 
        SELECT object_name 
        INTO   v_functionname 
        FROM   user_objects 
        WHERE  object_type = 'FUNCTION' AND object_name = Upper(v_processorname); 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_functionname := NULL; 
          v_errorcode := 101; 
          v_errormessage := 'Event processor not found'; 
          RETURN -1; 
    END; 

    v_first := 1; 
    v_query := 'begin ' || ':' || 'v_result := ' || v_functionname || '('; 

    FOR rec IN (SELECT object_name, 
                       object_id, 
                       argument_name, 
                       position, 
                       SEQUENCE, 
                       data_type, 
                       defaulted, 
                       default_value, 
                       default_length, 
                       in_out, 
                       data_length, 
                       pls_type, 
                       char_used 
                FROM   user_arguments 
                WHERE  object_id = (SELECT object_id 
                                    FROM   user_objects 
                                    WHERE  object_type = 'FUNCTION' AND object_name = Upper( v_functionname)
									) 
                       AND NOT( argument_name IS NULL AND in_out = 'OUT' AND position = 0 ) 
                ORDER  BY position) LOOP 
        IF v_first = 0 THEN 
          v_query := v_query || ','; 
        END IF; 

        v_query := v_query || rec.argument_name || ' => ' || ':' || 'v_' || rec.argument_name; 
        v_first := 0; 
    END LOOP; 

    v_query := v_query || '); end;'; 

    EXECUTE IMMEDIATE v_query 
    USING OUT v_result, OUT v_msgphresult, v_taskid; 
    RETURN v_msgphresult; 
END; 