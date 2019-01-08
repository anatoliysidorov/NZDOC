DECLARE 
    v_result INTEGER; 
BEGIN 
    SELECT col_id
    INTO   v_result 
    FROM   TBL_DICT_TASKSTATE
    WHERE  COL_CODE = :p_code; 

    RETURN v_result; 
END; 