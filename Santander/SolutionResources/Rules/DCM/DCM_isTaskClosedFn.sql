DECLARE 
    v_isfinish INTEGER; 
BEGIN 
    BEGIN 
        SELECT ts.col_isfinish 
        INTO   v_isfinish 
        FROM   tbl_dict_taskstate ts
        inner join tbl_tw_workitem twi on ts.col_id = twi.col_tw_workitemdict_taskstate
        inner join tbl_task tsk on twi.col_id = tsk.col_tw_workitemtask
        WHERE  tsk.col_id = :Task_Id; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_isfinish := 0;
    END; 

    RETURN NVL(v_isfinish, 0); 
END; 