DECLARE 
    v_taskid INTEGER; 
BEGIN 	
	IF f_DCM_isSlaEventinCache(:SLAEventID) = 1 THEN
		SELECT COL_SLAEVENTCCTASKCC
		INTO v_taskid
		FROM TBL_SLAEVENTCC
		WHERE col_id = :SLAEventID;
		
	ELSE 
		SELECT COL_SLAEVENTTASK
		INTO v_taskid
		FROM TBL_SLAEVENT
		WHERE col_id = :SLAEventID;
		
	END IF;
	
	RETURN v_taskid;
EXCEPTION 
    WHEN no_data_found THEN 
      RETURN NULL; 
END; 