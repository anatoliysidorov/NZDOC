--Rule Name- SMPL_execRuleNQSLAfn
--Rule Type- Non Query SQL deployed as Function
--Input- SlaActionId, Integer
--This should create a history record viewable both in the Task and 

DECLARE
	v_result INT;
BEGIN
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo=>'This is a rule for testing Workflow Events', 
		IsSystem=>0, 
		Message=> 'Executed SQL NonQuery Function named SMPL_execRuleNQSLAfn',
		MessageCode => NULL,
		TargetID => F_dcm_gettaskidbyslafn(:SLAActionID), 
		TargetType=>'TASK'
	);		
END;