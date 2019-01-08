/*
We expect that the SQL function has one of the following signatures
* f_someFunction(CaseId, Result);
* f_someFunction(TaskId, Result);
* f_someFunction(ExternalPartyId, Result);
* f_someFunction(SLAEventId, Result);
* f_someFunction(TargetId, TargetType, Result); <- TargetType = case, task, or external party
* f_someFunction(CaseId, PlaceholderResult);
* f_someFunction(TaskId, PlaceholderResult);
* f_someFunction(ExternalPartyId, PlaceholderResult);
* f_someFunction(CaseId);
* f_someFunction(TaskId);
* f_someFunction(ExternalPartyId);
* f_someFunction(SLAEventId);
* f_someFunction(TargetId, TargetType);
It is better to write all new functions in the TargetId - TargetType format so that it's easier to maintain
*/
DECLARE
    --input params
    v_targetid INTEGER;
    v_targettype NVARCHAR2(40);
    v_processorname NVARCHAR2(255);
    --calculate inputs
    v_TaskId INTEGER;
    v_CaseId INTEGER;
    v_ExternalPartyId INTEGER;
    v_SLAEventId INTEGER;
    v_STATESLAEVENTID INTEGER;
    --internal
    v_functionname NVARCHAR2(255);
    v_errorcode NUMBER;
    v_errormessage NVARCHAR2(255);
    v_query VARCHAR(2000);
    v_first NUMBER;
    v_result NCLOB;
    v_temp INTEGER;
    v_passTargetType INTEGER;
    v_isScalarFn INTEGER;
    v_paramName NVARCHAR2(40);
    v_resultName NVARCHAR2(20); --either RESULT or PLACEHOLDERRESULT
BEGIN
    --bind variables
    v_targetid := :TargetId;
    v_targettype := Lower(:TargetType);
    v_processorname := Upper(:ProcessorName);
    v_passTargetType := 0;
    IF v_targettype = 'task' or v_targettype = 'taskid' THEN
        v_TaskId := v_targetid;
    ELSIF v_targettype = 'case' or v_targettype = 'caseid' THEN
        v_CaseId := v_targetid;
    ELSIF v_targettype = 'externalparty' or v_targettype = 'externalpartyid' THEN
        v_ExternalPartyId := v_targetid;
    ELSIF v_targettype = 'slaevent' or v_targettype = 'slaeventid' THEN
        v_SLAEventId := v_targetid;
    ELSIF v_targettype = 'slamsevent' or v_targettype = 'slamseventid' THEN
        v_STATESLAEVENTID := v_targetid;
    END IF;
    --get information about the function to be executed
    BEGIN
        SELECT object_name
        INTO   v_functionname
        FROM   user_objects
        WHERE  object_type = 'FUNCTION'
               AND object_name = v_processorname;
    
    EXCEPTION
    WHEN no_data_found THEN
        v_functionname := NULL;
        v_errorcode := 101;
        v_errormessage := 'SQL function not found';
        RETURN NULL;
    END;
    --determine whether it's an SQL Scalar function, which means the result is returned and doesn't require an output param
    BEGIN
        SELECT 1
        INTO   v_isScalarFn
        FROM   VW_UTIL_DeployedRule
        WHERE  RuleType = 3
               AND ISNEEDDEPLOYFUNCTION = 1
               AND UPPER(NAME) = UPPER(SUBSTR(v_functionname,3)); --to remove the f_ portion;
    EXCEPTION
    WHEN no_data_found THEN
        v_isScalarFn := 0;
    END;
    --build first part of dynamic query
    v_first := 1;
    v_query := 'begin ' || ':' || 'v_temp := ' || v_functionname || '(';
    --set input/output parameters for the dynamic  function
    FOR rec IN(SELECT  object_name,
             object_id,
             argument_name,
             position,
             in_out
    FROM     user_arguments
    WHERE    object_id =(SELECT object_id
             FROM    user_objects
             WHERE   object_type = 'FUNCTION'
                     AND object_name = Upper(v_functionname))
             AND NOT(argument_name IS NULL
             AND in_out = 'OUT'
             AND position = 0)
    ORDER BY position)
    LOOP
        v_paramName := UPPER(rec.argument_name);
        IF NOT(v_paramName = 'RESULT' OR v_paramName = 'PLACEHOLDERRESULT') THEN
            IF v_first = 0 THEN
                v_query := v_query || ',';
            END IF;
            v_query := v_query || v_paramName || ' => ' || ':' || 'v_' || v_paramName;
            v_first := 0;
            IF v_paramName = 'TARGETTYPE' THEN
                v_passTargetType := 1;
            END IF;
        ELSE
            -- don't add RESULT or PLACEOLDERRESULT yet, do it at the end
            v_resultName := v_paramName;
        END IF;
    END LOOP;
    --add the "result" output parameter to the end if it's an SQL NonQuery Fn
    IF v_isScalarFn = 0 THEN
        IF v_first = 0 THEN
            v_query := v_query || ',';
        END IF;
        v_query := v_query || v_resultName || ' => :' || 'v_result';
    END IF;
    --close the dynamic SQL code
    v_query := v_query || '); end;';
    --DBMS_OUTPUT.PUT_LINE(v_query);
    --execute the dynamic query based on the number of arguments
    IF v_isScalarFn = 1 THEN
        IF v_passTargetType = 0 THEN
            EXECUTE IMMEDIATE v_query USING OUT v_result,v_targetid;
        ELSE
            EXECUTE IMMEDIATE v_query USING OUT v_result,v_targetid,v_targettype;
        END IF;
    ELSE
        IF v_passTargetType = 0 THEN
            EXECUTE IMMEDIATE v_query USING OUT v_temp,v_targetid,OUT v_result;
        ELSE
            EXECUTE IMMEDIATE v_query USING OUT v_temp,v_targetid,v_targettype,OUT v_result;
        END IF;
    END IF;
    --return results
    RETURN v_result;
END;