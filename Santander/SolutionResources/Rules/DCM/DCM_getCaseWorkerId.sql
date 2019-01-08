DECLARE 
    v_result NUMBER; 
BEGIN 
    BEGIN 
       SELECT id 
       INTO v_result
       FROM vw_ppl_caseworkersusers 
       WHERE  accode = Sys_context('CLIENTCONTEXT', 'AccessSubject') ;
    EXCEPTION 
        WHEN no_data_found THEN 
          v_result := NULL; 
    END; 

    RETURN v_result; 
END; 