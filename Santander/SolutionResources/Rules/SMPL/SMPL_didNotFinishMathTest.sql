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
	
	--math test results
	v_problem1 INTEGER;
	v_problem2 INTEGER;
	v_problem3 INTEGER;
	v_problem4 INTEGER;
	v_problem5 INTEGER;
	
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
	
	--get answers for all math problems
	v_problem1 := f_form_getparambyname(v_parentTaskCustomData,'SIMPLE_MATH_TEST/PROBLEM_1');
	v_problem2 := f_form_getparambyname(v_parentTaskCustomData,'SIMPLE_MATH_TEST/PROBLEM_2');
	v_problem3 := f_form_getparambyname(v_parentTaskCustomData,'SIMPLE_MATH_TEST/PROBLEM_3');
	v_problem4 := f_form_getparambyname(v_parentTaskCustomData,'SIMPLE_MATH_TEST/PROBLEM_4');
	v_problem5 := f_form_getparambyname(v_parentTaskCustomData,'SIMPLE_MATH_TEST/PROBLEM_5');
	
	IF 
		v_problem1 IS NULL AND 
		v_problem2 IS NULL AND 
		v_problem3 IS NULL AND 
		v_problem4 IS NULL AND 
		v_problem5 IS NULL 
	THEN
		:TaskResult := 1;
		RETURN 1;
	ELSE 
		:TaskResult := 0;
		RETURN 0;
	END IF;
	
END;