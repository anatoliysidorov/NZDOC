--Rule Name SMPL_MS_execRuleNQfn
--Rule Type Non Query SQL Function
--Input CaseId, Integer
--This should create a history record viewable in the Case

DECLARE  
  v_result       NUMBER;  
BEGIN
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo=>NULL, 
		IsSystem=>0, 
		Message=> 'This is a sample SQL NonQuery function rule',
		MessageCode =>  NULL, 
		TargetID =>:CaseId, 
		TargetType=>'CASE'
	);
	
	IF v_Result > 0 THEN
		:ValidationResult := 1;
		:Message          := 'Successfully added history item';
	ELSE
		:ValidationResult := 0;
		:Message          := 'Failed to add history item';
	END IF;
END;