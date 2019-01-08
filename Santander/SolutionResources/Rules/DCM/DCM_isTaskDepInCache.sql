DECLARE
  v_dummy INTEGER;
  
BEGIN 
    SELECT NULL INTO v_dummy 
    FROM   tbl_taskdependencycc 
    WHERE  col_id = :TaskDependencyId; 

    RETURN 1; 
EXCEPTION 
    WHEN OTHERS THEN 
      RETURN 0; 
END;