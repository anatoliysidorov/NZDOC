DECLARE
  v_dummy INTEGER; 
  
BEGIN 
    SELECT NULL INTO v_dummy 
    FROM   TBL_CSCASE 
    WHERE  col_id = :CaseId; 

    RETURN 1; 
EXCEPTION 
    WHEN OTHERS THEN 
      RETURN 0; 
END; 