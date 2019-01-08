DECLARE 
    v_taskid INTEGER; 
BEGIN 
    SELECT col_id 
    INTO   v_taskid 
    FROM   tbl_task
    WHERE  col_casetask = :CaseId 
           AND Nvl(col_parentid, 0) = 0; 

    RETURN v_taskid; 
EXCEPTION 
    WHEN no_data_found THEN 
      RETURN NULL; 
END; 