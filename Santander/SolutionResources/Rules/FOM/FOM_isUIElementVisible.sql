DECLARE
  v_functionname NVARCHAR2(255);
  v_objectid     NUMBER;
  v_argumentname NVARCHAR2(255);
  v_query        VARCHAR(2000);
  v_entityid     NUMBER;
  v_result       NUMBER;
BEGIN

  v_result := 1;

  IF (:Function_Name IS NOT NULL AND :Entity_Id IS NOT NULL) THEN
    
    v_functionname := 'f_' || :Function_Name;
    v_entityid     := :Entity_Id;
    
    BEGIN
      SELECT object_id
        INTO v_objectid
        FROM user_objects
       WHERE object_type = 'FUNCTION'
         AND object_name = upper(v_functionname);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 1;
    END;
  
    BEGIN
      SELECT UPPER(argument_name)
        INTO v_argumentname
        FROM user_arguments
       WHERE object_id = v_objectid
         AND NOT (argument_name IS NULL AND in_out = 'OUT' AND position = 0)
         AND rownum = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 1;
    END;
  
    IF v_argumentname NOT IN ('CASE_ID', 'TASK_ID', 'EXTERNALPARTY_ID') THEN
      RETURN 1;
    END IF;
  
    v_query := 'begin ' || ':' || 'v_result := ' || v_functionname || '(' || v_argumentname || ' => ' || ':' || 'Entity_Id' || '); end;';
  
    EXECUTE IMMEDIATE v_query USING OUT v_result, v_entityid;
  END IF;
  
  RETURN v_result;
END;