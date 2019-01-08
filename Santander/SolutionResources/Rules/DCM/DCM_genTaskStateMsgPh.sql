DECLARE 
    --input/output
	v_taskid INTEGER; 	

	--internal
	v_inCache INTEGER;
  v_CSisInCache INTEGER;
  
BEGIN 
    v_taskid := :TaskId;
	v_inCache := f_DCM_isTaskInCache(TaskID => v_taskid);
  v_CSisInCache :=f_DCM_CSisTaskInCache(TaskID => v_taskid);
	
	--get task from proper place
	IF v_inCache = 1 THEN
		SELECT ts.col_name 
    INTO   :PlaceholderResult 
    FROM   tbl_taskCC tse 
     inner join tbl_tw_workitemCC twi ON tse.COL_TW_WORKITEMCCTASKCC = twi.col_id 
     inner join tbl_dict_taskstate ts ON twi.COL_TW_WORKITEMCCDICT_TASKST = ts.col_id 
    WHERE  tse.col_id = v_taskid; 	
  END IF;  
    
  IF (v_inCache = 0) AND (v_CSisInCache=0) THEN
		SELECT ts.col_name 
    INTO   :PlaceholderResult 
    FROM   tbl_task tse 
     inner join tbl_tw_workitem twi ON tse.COL_TW_WORKITEMTASK = twi.col_id 
     inner join tbl_dict_taskstate ts ON twi.COL_TW_WORKITEMDICT_TASKSTATE = ts.col_id 
    WHERE  tse.col_id = v_taskid;
	END IF;
  
  IF v_CSisInCache=1 THEN
		SELECT ts.col_name 
    INTO   :PlaceholderResult 
    FROM   tbl_cstask tse 
     inner join tbl_cstw_workitem twi ON tse.COL_TW_WORKITEMTASK = twi.col_id 
     inner join tbl_dict_taskstate ts ON twi.COL_TW_WORKITEMDICT_TASKSTATE = ts.col_id 
    WHERE  tse.col_id = v_taskid;
	END IF;  
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;