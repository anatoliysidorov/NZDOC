DECLARE 
    v_state NVARCHAR2(255); 
BEGIN 
    BEGIN 
        SELECT col_activity 
        INTO   v_state 
        FROM   tbl_dict_taskstate 
        WHERE  col_isdefaultoncreate = 1; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_state := 'root_TSK_Status_NEW'; 
        WHEN too_many_rows THEN 
          v_state := 'root_TSK_Status_NEW'; 
    END; 

    RETURN v_state; 
END; 