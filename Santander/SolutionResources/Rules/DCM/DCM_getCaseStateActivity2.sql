DECLARE 
    v_activity NVARCHAR2(255); 
BEGIN 
    BEGIN 
        SELECT Nvl(activity, '') 
        INTO   v_activity 
        FROM   TABLE (F_dcm_getcasestates(:CaseId)) 
        WHERE  ( CASE 
                   WHEN UPPER(:StateCode) = code 
                        AND iscreate = 1 THEN 1 
                   WHEN UPPER(:StateCode) = code
                        AND isstart = 1 THEN 1 
                   WHEN UPPER(:StateCode) = code 
                        AND isassign = 1 THEN 1 
                   WHEN UPPER(:StateCode) = code
                        AND isinprocess = 1 THEN 1 
                   WHEN UPPER(:StateCode) = code 
                        AND isresolve = 1 THEN 1 
                   WHEN UPPER(:StateCode) = code 
                        AND isfinish = 1 THEN 1 
                   ELSE 0 
                 END ) = 1; 

        RETURN v_activity; 
    EXCEPTION 
        WHEN no_data_found THEN 
          RETURN ''; 
    END; 
END; 