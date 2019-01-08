DECLARE 
    v_state         NVARCHAR2(255); 
    v_stateconfigid INTEGER; 
BEGIN 
    v_stateconfigid := :StateConfigId; 

    --Calculate task state machine configuration 
    IF v_stateconfigid IS NULL THEN 
      BEGIN 
          SELECT col_id 
          INTO   v_stateconfigid 
          FROM   tbl_dict_stateconfig 
          WHERE  col_isdefault = 1 
                 AND Lower(col_type) = 'task'; 
      EXCEPTION 
          WHEN no_data_found THEN 
            v_stateconfigid := NULL; 
          WHEN too_many_rows THEN 
            v_stateconfigid := NULL; 
      END; 
    END IF; 

    BEGIN 
        SELECT col_activity 
        INTO   v_state 
        FROM   tbl_dict_taskstate 
        WHERE  col_isdefaultoncreate = 1 
               AND Nvl(col_stateconfigtaskstate, 0) = Nvl(v_stateconfigid, 0); 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_state := 'root_TSK_Status_NEW'; 
        WHEN too_many_rows THEN 
          v_state := 'root_TSK_Status_NEW'; 
    END; 

    RETURN v_state; 
END; 