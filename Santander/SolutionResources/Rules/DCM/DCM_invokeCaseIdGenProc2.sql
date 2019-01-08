DECLARE 
    v_caseid        INTEGER; 
    v_processorname NVARCHAR2(255); 
    v_functionname  NVARCHAR2(255); 
    v_query         VARCHAR(2000); 
    v_count         NUMBER; 
    v_first         NUMBER; 
    v_result        NUMBER; 
    v_casetitle     NVARCHAR2(255); 
BEGIN 
    v_caseid := :CaseId; 

    v_processorname := NULL; 

    BEGIN 
        SELECT col_processorcode 
        INTO   v_processorname 
        FROM   tbl_dict_casesystype 
        WHERE  col_id = (SELECT col_casedict_casesystype 
                         FROM   tbl_case 
                         WHERE  col_id = v_caseid); 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_processorname := NULL; 
    END; 

    IF v_processorname IS NULL THEN 
      v_casetitle := NULL; 

      RETURN v_casetitle; 
    END IF; 

    BEGIN 
        SELECT object_name 
        INTO   v_functionname 
        FROM   user_objects 
        WHERE  object_type = 'FUNCTION' 
               AND object_name = Upper(v_processorname); 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_functionname := NULL; 

          RETURN -1; 
    END; 

    BEGIN 
        SELECT Count(*) 
        INTO   v_count 
        FROM   user_arguments 
        WHERE  object_id = (SELECT object_id 
                            FROM   user_objects 
                            WHERE  object_type = 'FUNCTION' 
                                   AND object_name = Upper(v_functionname)) 
               AND NOT( argument_name IS NULL 
                        AND in_out = 'OUT' 
                        AND position = 0 ); 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_count := 0; 
    END; 

    v_first := 1; 

    v_query := 'begin ' 
               || ':' 
               || 'v_result := ' 
               || v_functionname 
               || '('; 

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
                                    WHERE  object_type = 'FUNCTION' 
                                           AND object_name = Upper( 
                                               v_functionname)) 
                       AND NOT( argument_name IS NULL 
                                AND in_out = 'OUT' 
                                AND position = 0 ) 
                ORDER  BY position) LOOP 
        IF v_first = 0 THEN 
          v_query := v_query 
                     || ','; 
        END IF; 

        v_query := v_query 
                   || rec.argument_name 
                   || ' => ' 
                   || ':' 
                   || 'v_' 
                   || rec.argument_name; 

        v_first := 0; 
    END LOOP; 

    v_query := v_query 
               || '); end;'; 

    IF v_count = 1 THEN 
      EXECUTE IMMEDIATE v_query 
      USING OUT v_result, v_caseid; 
    ELSIF v_count = 2 THEN 
      EXECUTE IMMEDIATE v_query 
      USING OUT v_result, v_caseid, OUT v_casetitle; 
    END IF; 

    RETURN v_casetitle; 
END; 