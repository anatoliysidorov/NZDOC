DECLARE 
    v_result NUMBER; 
BEGIN 
    BEGIN 
        SELECT sw.id 
        INTO   v_result 
        FROM   vw_ppl_simpleworkbasket sw 
               inner join vw_ppl_activecaseworkersusers acu 
                       ON sw.caseworker_id = acu.id 
        WHERE  acu.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject') 
               AND lower(sw.workbaskettype_code) = 'personal'; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_result := NULL; 
    END; 

    RETURN v_result; 
END; 