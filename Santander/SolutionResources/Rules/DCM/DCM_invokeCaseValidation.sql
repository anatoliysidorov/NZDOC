DECLARE
    v_validator nvarchar2(255) ;
    v_CustomData NCLOB;
    v_functionName nvarchar2(255) ;
    v_ErrorCode NUMBER;
    v_ErrorMessage nvarchar2(255) ;
    v_query            VARCHAR(2000) ;
    v_count            NUMBER;
    v_first            NUMBER;
    v_result           NUMBER;
    v_CaseId           INTEGER;
    v_validationresult NUMBER;
BEGIN
    v_CustomData := :CustomData;
    v_validator := :Validator;
/*    BEGIN
        SELECT object_name
        INTO   v_functionName
        FROM   user_objects
        WHERE  object_type = 'FUNCTION'
               AND
               object_name = UPPER(v_validator) ;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_functionName := NULL;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Case type validator not found';
        RETURN -1;
    END;
    
    BEGIN
        SELECT COUNT(*)
        INTO   v_count
        FROM   user_arguments
        WHERE  object_id =(
               SELECT object_id
               FROM   user_objects
               WHERE  object_type = 'FUNCTION'
                      AND
                      object_name = UPPER(v_functionName)
               )
               AND NOT (argument_name IS NULL AND in_out = 'OUT' AND position = 0);
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_count := 0;
    END;*/

v_functionName := upper(v_validator);
    v_count := f_util_check_function(fun_invoker_name => $$plsql_unit,fun_processor => v_functionName, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
IF v_count = -1 THEN 
    RETURN -1;
END IF;	
    
    v_first := 1;
    v_query := 'begin ' || ':' || 'v_result := ' || v_functionName || '(';
    FOR rec IN(
    SELECT   object_name,
             object_id,
             argument_name,
             position,
             sequence,
             data_type,
             defaulted,
             default_value,
             default_length,
             in_out,
             data_length,
             pls_type,
             char_used
    FROM     user_arguments
    WHERE    object_id =(
             SELECT object_id
             FROM   user_objects
             WHERE  object_type = 'FUNCTION'
                    AND
                    object_name = UPPER(v_functionName)
             )
             AND NOT (argument_name IS NULL AND in_out = 'OUT' AND position = 0)
    ORDER BY position
    )
    LOOP
        IF v_first = 0 THEN
            v_query := v_query || ',';
        END IF;
        v_query := v_query || rec.argument_name || ' => ' || ':' || 'v_' || rec.argument_name;
        v_first := 0;
    END LOOP;
    v_query := v_query || '); end;';
    EXECUTE immediate v_query USING OUT v_result,OUT v_CaseId,v_CustomData,OUT v_validationresult;
    :CaseId := v_CaseId;
    RETURN v_validationresult;
END;