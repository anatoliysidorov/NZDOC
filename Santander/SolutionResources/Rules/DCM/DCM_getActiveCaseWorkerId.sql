DECLARE 
    v_result NUMBER; 
BEGIN 
    BEGIN 
       SELECT id 
       INTO v_result
       FROM vw_PPL_ActiveCaseWorkersUsers 
       WHERE  accode = Sys_context('CLIENTCONTEXT', 'AccessSubject') ;
    EXCEPTION 
        WHEN no_data_found THEN 
          v_result := 0; 
    END; 

    :ID := v_result; 
END;