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
		SELECT tt.col_name
        INTO   :PlaceholderResult 
        FROM   tbl_taskCC t
		LEFT JOIN tbl_dict_tasksystype tt ON tt.col_id = t.COL_TASKCCDICT_TASKSYSTYPE
        WHERE  t.col_id = v_taskid; 	
	ELSE
		SELECT tt.col_name
        INTO   :PlaceholderResult 
        FROM   tbl_task t
		LEFT JOIN tbl_dict_tasksystype tt ON tt.col_id = t.COL_TASKDICT_TASKSYSTYPE
        WHERE  t.col_id = v_taskid; 	
	END IF;
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;