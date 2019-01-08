DECLARE 
    v_activity NVARCHAR2(255); 
BEGIN 
    BEGIN 
        SELECT Nvl(activity, '') 
        INTO   v_activity 
        FROM   TABLE (F_dcm_getcasestates(:CaseId)) 
        WHERE  ( CASE 
                   WHEN Lower(:StateFlag) = 'create' 
                        AND iscreate = 1 THEN 1 
                   WHEN Lower(:StateFlag) = 'start' 
                        AND isstart = 1 THEN 1 
                   WHEN Lower(:StateFlag) = 'assign' 
                        AND isassign = 1 THEN 1 
                   WHEN Lower(:StateFlag) = 'inprocess' 
                        AND isinprocess = 1 THEN 1 
                   WHEN Lower(:StateFlag) = 'resolve' 
                        AND isresolve = 1 THEN 1 
                   WHEN Lower(:StateFlag) = 'finish' 
                        AND isfinish = 1 THEN 1 
                   ELSE 0 
                 END ) = 1; 

        RETURN v_activity; 
    EXCEPTION 
        WHEN no_data_found THEN 
          RETURN ''; 
    END; 
END; 