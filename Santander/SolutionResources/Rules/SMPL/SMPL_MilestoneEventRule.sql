DECLARE  
  v_result       NUMBER;  
BEGIN
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo=>:INPUT, 
		IsSystem=>0, 
		Message=> 'Example of an SQL Function Rule Event added to a Milestone',
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