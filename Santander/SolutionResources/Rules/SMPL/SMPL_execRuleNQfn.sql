--Rule Name- SMPL_execRuleNQfn
--Rule Type- Non Query SQL deployed as Function
--Input- TaskId, Integer
--This should create a history record viewable both in the Task and the Case

DECLARE
	v_result INT;
BEGIN
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo=>'This is a rule for testing Workflow Events', 
		IsSystem=>0, 
		Message=> 'Executed SQL Non Query rule SMPL_execRuleNQfn deployed as a function',
		MessageCode => NULL,
		TargetID => :TaskID, 
		TargetType=>'TASK'
	);		
END;
