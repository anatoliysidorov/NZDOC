DECLARE  
  v_result       NUMBER;  
BEGIN
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo=>:INPUT, 
		IsSystem=>CASE WHEN NVL(f_form_getparambyname(:INPUT, 'Important'), 0) = 0 THEN 1 ELSE 0 END, 
		Message=> NULL,
		MessageCode =>  f_FORM_getParamByName(:Input, 'MESSAGE_CODE'), 
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