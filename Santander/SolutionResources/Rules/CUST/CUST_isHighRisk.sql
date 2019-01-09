DECLARE
	--input
	v_TaskDependencyId INTEGER;
	
	--system
	v_result INTEGER;

	v_parentTask INTEGER;
	v_parentTaskState INTEGER;
	v_parentTaskCase INTEGER;
	v_parentTaskCustomData NCLOB;

	v_childTask INTEGER;
	v_childTaskState INTEGER;
	v_childTaskCase INTEGER;
	v_childTaskCustomData NCLOB;

BEGIN
	v_TaskDependencyId := :TaskDependencyId;
	
	--get info about parent task (the one that has the math test)
	v_result := f_DCM_getDependencyInfo(
		TaskDependencyId => v_TaskDependencyId,
		childTask => v_childTask,
		childTaskCase => v_childTaskCase,
		childTaskCustomData => v_childTaskCustomData,
		childTaskState => v_childTaskState, 
		parentTask => v_parentTask,
		parentTaskCase => v_parentTaskCase,
		parentTaskCustomData => v_parentTaskCustomData,
		parentTaskState => v_parentTaskState
	);
    
    INSERT INTO tbl_log(col_data1) VALUES (v_parentTask);
    
    select count(1) into :TaskResult
    from tbl_Task t 
    join tbl_cdm_briefings cb on cb.COL_BRIEFINGSCASE = t.COL_CASETASK
    join tbl_dict_customword cw on cw.col_id = cb.COL_CDM_BRIEFINGSRISK AND UPPER(cw.col_Code) IN ('MEDIUM', 'HIGH')
    join tbl_dict_customcategory cc on cw.col_wordcategory = cc.col_id
    where t.col_id = v_parentTask;
    
	RETURN :TaskResult;
END;