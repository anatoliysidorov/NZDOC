--Rule Name SMPL_execRuleNQ
--Rule Typ Non Query SQL
--Input TaskId, Integer and SlaActionId, Integer
--This should create a history record viewable both in the Task and the Case

DECLARE
	v_result INT;
	v_SlaActionId INT;
	v_TaskId INT;
BEGIN
	v_SlaActionId := NVL(:SlaActionId, 0);
	v_TaskId := NVL(:TaskId, 0);

	--if executed from an SLA, then get the Task ID from the SLA
	IF v_TaskId = 0 AND v_SlaActionId > 0 THEN
		v_TaskId := F_dcm_gettaskidbyslafn(v_SlaActionId);
	END IF;

	--create history
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo=>'This is a rule for testing Workflow Events', 
		IsSystem=>0, 
		Message=> 'Executed SQL NonQuery rule SMPL_execRuleNQ',
		MessageCode => NULL,
		TargetID => v_TaskId, 
		TargetType=>'TASK'
	);		
END;