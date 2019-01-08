DECLARE 
    --INPUT 
    v_participant_code NVARCHAR2(255); 
    v_rule_code        NVARCHAR2(255); 
	
    --INTERNAL 
    v_wb               INTEGER; 
    v_result           INTEGER; 
	
    --OUTPUT 
    v_message          NCLOB; 
    v_validationresult NUMBER; 
	
    --temp variables for returns 
    v_tempErrMsg       NCLOB; 
    v_tempErrCd       INTEGER; 
    v_tempSccss        NCLOB; 
	
BEGIN 

	--CALCULATED--	
	v_wb := 0;
	v_participant_code := TRIM(Lower(F_form_getparambyname(:INPUT, 'ParticipantCode')));
	v_rule_code	 := TRIM(Lower(F_form_getparambyname(:INPUT, 'WORKBASKET_RULE')));
  IF v_rule_code IS NULL THEN
    v_rule_code	 := TRIM(Lower(F_form_getparambyname(:INPUT, 'WorkbasketRule')));
  END IF;  
	
	--OUTPUT--
	v_validationresult := 1; 
  v_message := ''; 
  :Message :=NULL;
  :ValidationResult :=NULL;
	
	--ADD BASIC INFORMATION
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: param Participt Code - ' || NVL(v_participant_code, ' ==none=='));	
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: param Workbasket Rule - ' || NVL(v_rule_code, ' ==none=='));	

	IF v_participant_code IS NOT NULL AND v_rule_code IS NOT NULL THEN
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'WARNING: Workbasket Rule will be ignored because a Participant Code is provided');
	END IF;
	
	--TRY TO ASSIGN USING PARTICIPANT CODE OR RULE	
	IF v_participant_code IS NOT NULL THEN
		--if participant_code is supplied, then try to calculate from the case party		
		v_result := F_dcm_assigntaskfn(
			action => 'ASSIGN_TO_PARTY', 
			task_id => TASKID, 
			caseparty_id => f_PPL_getCasePartyByCode(CaseID => F_dcm_getcaseidbytaskid(TASKID), ParticipantCode => v_participant_code), 
			workbasket_id => NULL,		
			note => NULL, 			
			errorcode => v_tempErrCd, 
			errormessage => v_tempErrMsg, 
			successresponse => v_tempSccss
		); 
		
	ELSIF v_rule_code IS NOT NULL THEN
		--if rule code is supplied, then try to calculate using an invoker
		v_wb := TO_NUMBER(f_UTIL_genericInvokerFn(ProcessorName => v_rule_code, TargetType => 'TASK', TargetId => TASKID));   
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Workbasket Rule invoked and returned ' || NVL(TO_CHAR(v_wb), '==NOTHING=='));
		v_result := F_dcm_assigntaskfn(
			action => 'ASSIGN', 
			task_id => TASKID, 
			caseparty_id => NULL, 
			workbasket_id => v_wb,		
			note => NULL, 			
			errorcode => v_tempErrCd, 
			errormessage => v_tempErrMsg, 
			successresponse => v_tempSccss 
		);

    --temp, do not delete this row (ask VV)
    IF v_tempErrCd IN (121, 201) THEN v_tempErrCd:=0; END IF;
	ELSE
		v_tempErrCd := 120;
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: This event is missing both a Participant Code and a Workbasket Rule');
		GOTO cleanup;
	END IF;
	
	--DETERMINE IF ASSIGNMENT WAS SUCCESSFUL
	IF v_result >= 0 AND NVL(v_tempErrCd, 0) = 0 THEN
		:ValidationResult := 1;
		:Message := 'Success';
	ELSE
		GOTO cleanup;		
	END IF; 
	
	RETURN 0;
	
	--ERROR BLOCK
	<<cleanup>>  
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'WARNING: Either no work basket was found or there was an error assigning to it');
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR CODE: ' || v_tempErrCd);
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR MESSAGE: ' || v_tempErrMsg);
	
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo => v_message,  
		IsSystem=>0, 
		Message=> NULL,
		MessageCode => 'GenericEventFailure', 
		TargetID => :TASKID, 
		TargetType=>'TASK'
	);		
	
	:ValidationResult := 0;
	:Message := v_tempErrMsg;
	RETURN -1;

END;