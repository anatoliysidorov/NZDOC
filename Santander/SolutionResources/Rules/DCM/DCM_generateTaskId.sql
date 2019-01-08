BEGIN 
    DECLARE 
        v_recordid INTEGER; 
        v_prefix   NVARCHAR2(255); 
        v_taskid   NVARCHAR2(255); 
        v_caseid   NVARCHAR2(255); 
    BEGIN 
        v_recordid := :recordid; 
        v_prefix := :prefix; 
        v_taskid := v_prefix || '-' || To_char(v_recordid); 
        :taskid := ''; 

        BEGIN 
            SELECT col_caseid 
            INTO   v_caseid 
            FROM   tbl_case cs 
                   inner join tbl_task tsk ON cs.col_id = tsk.col_casetask 
            WHERE  tsk.col_id = v_recordid; 
        EXCEPTION 
            WHEN no_data_found THEN 
              RETURN 0; 
        END; 

        v_taskid := /*v_caseid || '|' || */v_taskid; 
        :taskid := v_taskid; 

    END;
END;