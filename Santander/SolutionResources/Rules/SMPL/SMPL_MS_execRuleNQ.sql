--Rule Name SMPL_MS_execRuleNQ
--Rule Type Non Query SQL
--Input CaseId, Integer and StateSLAActionID, Integer
--This should create a history record viewable both in the Task and the Case

DECLARE
	v_result INT;
	v_StateSLAActionID INT;
	v_caseid INT;
	v_message NVARCHAR2(255);
BEGIN
	v_StateSLAActionID := NVL(:StateSLAActionID, 0);
	v_caseid := NVL(:CaseId, 0);

	--create history
	v_message := 'Executed SQL NonQuery rule SMPL_MS_execRuleNQ.';
	if v_StateSLAActionID > 0 THEN
		v_message := v_message || ' Executed from an SLA.';
	end if;
	
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo=>'This is a rule for testing Milestone Events', 
		IsSystem=>0, 
		Message=> v_message ,
		MessageCode => NULL,
		TargetID => v_caseid, 
		TargetType=>'CASE'
	);		
END;