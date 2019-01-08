BEGIN 
    DECLARE 
        v_recordid INTEGER; 
        v_prefix   NVARCHAR2(255); 
        v_caseid   NVARCHAR2(255); 
    BEGIN 
        v_recordid := :recordid; 
        v_prefix := :prefix; 
        v_caseid := v_prefix || '-' || to_char(sysdate, 'YYYY')|| '-' || To_char(v_recordid); 
        :caseid := v_caseid; 

        BEGIN 
            UPDATE tbl_case 
            SET    col_caseid = v_caseid 
            WHERE  col_id = v_recordid; 

            :affectedRows := 1; 
        EXCEPTION 
            WHEN no_data_found THEN 
              :affectedRows := 0; 
            WHEN dup_val_on_index THEN 
              :affectedRows := 0; 
        END; 
    END; 
END; 