DECLARE
  v_dummy INTEGER;
  
BEGIN 
    SELECT NULL INTO v_dummy 
    FROM   TBL_CSTASK 
    WHERE  col_id = :TaskId; 

    RETURN 1; 
EXCEPTION 
    WHEN OTHERS THEN 
      RETURN 0; 
END;