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
       
    select count(1) into :TaskResult
    from tbl_Task t 
    join tbl_cdm_briefings cb on cb.COL_BRIEFINGSCASE = t.COL_CASETASK
    join tbl_dict_customword cw on cw.col_id = cb.COL_CDM_BRIEFINGSURGENCY AND UPPER(cw.col_Code) = 'HIGH_URGENCY'
    join tbl_dict_customcategory cc on cw.col_wordcategory = cc.col_id AND UPPER(cc.col_code) = 'URGENCY'
    join tbl_dict_customword cw1 on cw1.col_id = cb.COL_CDM_BRIEFINGBRIEFING_PRO AND UPPER(cw1.col_Code) = 'ADVICE'
    join tbl_dict_customcategory cc1 on cw1.col_wordcategory = cc1.col_id AND UPPER(cc1.col_code) = 'BRIEFING_PRODUCT'
    join tbl_dict_customword cw2 on cw2.col_id = cb.COL_CDM_BRIEFINGBRIEFING_TYP AND UPPER(cw2.col_Code) = 'EMAIL'
    join tbl_dict_customcategory cc2 on cw2.col_wordcategory = cc2.col_id AND UPPER(cc2.col_code) = 'BRIEFING_TYPE'
    where t.col_id = v_parentTask;
    
	RETURN :TaskResult;
END;