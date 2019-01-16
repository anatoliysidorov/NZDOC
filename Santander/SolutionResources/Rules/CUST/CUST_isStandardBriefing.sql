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
    
    v_TASKRESULT1 INTEGER;
    v_TASKRESULT2 INTEGER;
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
    
    v_result := F_CUST_isUrgentMemo(
        TASKDEPENDENCYID => v_TaskDependencyId,
        TASKRESULT => v_TASKRESULT1
    );
  
    v_result := F_CUST_isUrgentEmailAdvice(
        TASKDEPENDENCYID => v_TaskDependencyId,
        TASKRESULT => v_TASKRESULT2
    );  
    
    SELECT DECODE(GREATEST(v_TASKRESULT1, v_TASKRESULT2), 1, 0, 1) INTO :TaskResult FROM dual;
    
	RETURN :TaskResult;
END;