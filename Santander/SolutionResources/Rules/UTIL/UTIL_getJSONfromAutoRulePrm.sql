DECLARE
    v_TaskId Integer;
	v_data nclob :='[';

BEGIN
    BEGIN
      SELECT col_map_taskstateinittask into v_TaskId
        FROM tbl_map_taskstateinitiation tsi
        INNER JOIN tbl_taskevent te on tsi.col_id = te.col_taskeventtaskstateinit
        WHERE te.col_id = :TaskEventId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 'TASK NOT FOUND';
    END;
    FOR rec in ( 
      SELECT col_ParamCode, col_ParamValue
        FROM Tbl_AutoRuleParameter
        WHERE col_taskeventautoruleparam = :TaskEventId
		)
        
        LOOP
        	 IF (UPPER(rec.col_ParamCode) != 'TaskId') THEN
            	v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';
             END IF;
        END LOOP;

        v_data := v_data || '{"name": "TaskId", "value": ' || v_TaskId || '} ] ';

    RETURN v_data;
  END;