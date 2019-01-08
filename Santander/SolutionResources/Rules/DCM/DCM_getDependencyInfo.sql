DECLARE 
    --input/output
	v_TaskDependencyId INTEGER; 	

	--internal
	v_inCache INTEGER;
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
	v_inCache := f_DCM_isTaskDepInCache(TaskDependencyId => v_TaskDependencyId);
	
	--get tasks from proper place
	IF v_inCache = 1 THEN
		SELECT tss.COL_MAP_TASKSTATEINITCCTASKCC, tst.COL_MAP_TASKSTATEINITCCTASKCC
        INTO   v_childTask, v_parentTask
        FROM   tbl_TaskDependencyCC td 
		INNER JOIN TBL_MAP_TaskStateInitCC tss ON td.COL_TASKDPCHLDCCTASKSTINITCC = tss.col_id
		INNER JOIN TBL_MAP_TaskStateInitCC tst ON td.COL_TASKDPPRNTCCTASKSTINITCC = tst.col_id
        WHERE  td.col_id = v_TaskDependencyId; 	
	ELSE
		SELECT tss.COL_MAP_TASKSTATEINITTASK, tst.COL_MAP_TASKSTATEINITTASK
        INTO   v_childTask, v_parentTask
        FROM   tbl_TaskDependency td 
		INNER JOIN TBL_MAP_TaskStateInitiation tss ON td.COL_TSKDPNDCHLDTSKSTATEINIT = tss.col_id
		INNER JOIN TBL_MAP_TaskStateInitiation tst ON td.COL_TSKDPNDPRNTTSKSTATEINIT = tst.col_id
        WHERE  td.col_id = v_TaskDependencyId;
	END IF;

	
	--get data for each tasks
	v_result := f_DCM_getTaskInfo(TaskId => v_childTask, StateId => v_childTaskState, CaseId => v_childTaskCase, CustomData => v_childTaskCustomData);
	v_result := f_DCM_getTaskInfo(TaskId => v_parentTask, StateId => v_parentTaskState, CaseId => v_parentTaskCase, CustomData => v_parentTaskCustomData);
	
	:childTask := v_childTask;
	:childTaskState := v_childTaskState;
	:childTaskCase := v_childTaskCase;
	:childTaskCustomData := v_childTaskCustomData;
	
	:parentTask := v_parentTask;
	:parentTaskState := v_parentTaskState;
	:parentTaskCase := v_parentTaskCase;
	:parentTaskCustomData := v_parentTaskCustomData;
	
EXCEPTION 
	WHEN OTHERS THEN 
		:ChildTask := NULL;
		:ParentTask := NULL;
END;