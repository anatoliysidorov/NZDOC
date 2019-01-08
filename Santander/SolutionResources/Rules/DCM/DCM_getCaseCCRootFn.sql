DECLARE 
    v_taskccid INTEGER; 
BEGIN 
    SELECT col_id 
    INTO   v_taskccid 
    FROM   tbl_taskcc 
    WHERE  col_casecctaskcc = :CaseId 
           AND Nvl(col_parentidcc, 0) = 0; 

    RETURN v_taskccid; 
EXCEPTION 
    WHEN no_data_found THEN 
      RETURN NULL; 
END; 