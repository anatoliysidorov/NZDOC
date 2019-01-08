DECLARE 
    --input/output
	v_taskid INTEGER; 	

	--internal
	v_inCache INTEGER;
BEGIN 
    v_taskid := :TaskId;
	v_inCache := f_DCM_isTaskInCache(TaskID => v_taskid);
	
	--get task from proper place
	IF v_inCache = 1 THEN
		SELECT p.col_name 
        INTO   :PlaceholderResult 
        FROM   tbl_taskCC tse 
               inner join tbl_procedure p ON tse.COL_TASKCCPROCEDURE = p.col_id
        WHERE  tse.col_id = v_taskid; 	
	ELSE
		SELECT p.col_name 
        INTO   :PlaceholderResult 
        FROM   tbl_task tse 
               inner join tbl_procedure p ON tse.COL_TASKPROCEDURE = p.col_id
        WHERE  tse.col_id = v_taskid;
	END IF;
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;