DECLARE 
    v_caseid INTEGER; 
BEGIN 
    SELECT col_casetask 
    INTO   v_caseid 
    FROM   tbl_task 
    WHERE  col_id = :TaskId; 

    RETURN v_caseid; 
EXCEPTION 
    WHEN no_data_found THEN 
      RETURN NULL; 
END; 