DECLARE 
    v_event_id       NUMBER; 
    v_name           NVARCHAR2(255); 
    v_num_of_actions NUMBER; 
    v_action_order   NUMBER; 
	v_ProcessorCode           NVARCHAR2(255); 
	
BEGIN 
    v_event_id := :SLAEvent_Id; 
    v_name := :Name; 
	v_ProcessorCode := :ProcessorCode; 
    v_num_of_actions := 0; 
    v_action_order := 1; 

    BEGIN 
        SELECT Count(*) 
        INTO   v_num_of_actions 
        FROM   tbl_slaaction 
        WHERE  col_slaactionslaevent = v_event_id; 

        IF v_num_of_actions > 0 THEN 
          SELECT Max(col_actionorder) 
          INTO   v_action_order 
          FROM   tbl_slaaction 
          WHERE  col_slaactionslaevent = v_event_id; 

          IF v_action_order IS NULL THEN 
            v_action_order := 0; 
          END IF; 

          v_action_order := v_action_order + 1; 
        END IF; 

        INSERT INTO tbl_slaaction 
                    (col_code, 
                     col_slaactionslaevent, 
                     col_name,
					COL_PROCESSORCODE,					 
                     col_actionorder) 
        VALUES      ( sys_guid(),   /*F_util_codify(v_name),*/
                     v_event_id, 
                     v_name, 
					 v_ProcessorCode,
                     v_action_order); 
    END; 
END; 