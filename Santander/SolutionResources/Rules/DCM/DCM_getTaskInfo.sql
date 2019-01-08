DECLARE 
    --input/output
	v_taskid INTEGER; 

	--output
	v_StateId INTEGER;
	v_CustomData NCLOB;
	v_CaseId INTEGER;

	--internal
	v_inCache INTEGER;
BEGIN 
    v_taskid := :TaskId;
	v_inCache := f_DCM_isTaskInCache(TaskID => v_taskid);	
	
	
	--get task from proper place
	IF v_inCache = 1 THEN
		SELECT twi.COL_TW_WORKITEMCCDICT_TASKST, tse.COL_CASECCTASKCC, f_DCM_getTaskCustomData(v_taskid)
        INTO   v_StateId, v_CaseId, v_CustomData
        FROM   tbl_taskCC tse 
               left join tbl_tw_workitemCC twi ON tse.COL_TW_WORKITEMCCTASKCC = twi.col_id 
        WHERE  tse.col_id = v_taskid; 	
	ELSE
		SELECT twi.COL_TW_WORKITEMDICT_TASKSTATE, tse.COL_CASETASK, f_DCM_getTaskCustomData(v_taskid)
        INTO   v_StateId, v_CaseId, v_CustomData
        FROM   tbl_task tse 
               inner join tbl_tw_workitem twi ON tse.COL_TW_WORKITEMTASK = twi.col_id 
        WHERE  tse.col_id = v_taskid;
	END IF;
	
	:StateId := v_StateId;
	:CustomData := v_CustomData;
	:CaseId := v_CaseId;

EXCEPTION 
	WHEN OTHERS THEN 
		:StateId := NULL;
		:CustomData := NULL;
		:CaseId := NULL;
END;