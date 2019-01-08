DECLARE 
    --INPUT 
    v_participant_code NVARCHAR2(255); 
    v_rule_code        NVARCHAR2(255); 
	
    --INTERNAL 
    v_wb               INTEGER; 
    v_result           INTEGER; 
	v_CaseId			INTEGER;
	
    --OUTPUT 
    v_message          NCLOB; 
    v_validationresult NUMBER; 
	
    --temp variables for returns 
    v_tempErrMsg       NCLOB; 
    v_tempErrCd       INTEGER; 
    v_tempSccss        NCLOB; 
	
BEGIN 
	--CALCULATED--	
	v_CaseId := f_DCM_getCaseIdByTaskId(:TaskId);
	v_wb := 0;
	v_participant_code := TRIM(Lower(F_form_getparambyname(:INPUT, 'ParticipantCode')));
	v_rule_code	 := TRIM(Lower(F_form_getparambyname(:INPUT, 'WorkbasketRule')));
	
	--OUTPUT--
	v_validationresult := 1; 
    v_message := ''; 
	
	--ADD BASIC INFORMATION
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: param Participt Code - ' || NVL(v_participant_code, ' ==none=='));	
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: param Workbasket Rule - ' || NVL(v_rule_code, ' ==none=='));	

	IF v_participant_code IS NOT NULL AND v_rule_code IS NOT NULL THEN
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'WARNING: Workbasket Rule will be ignored because a Participant Code is provided');
	END IF;
	
	--TRY TO ASSIGN USING PARTICIPANT CODE OR RULE	
	IF v_participant_code IS NOT NULL THEN
    --if participant_code is supplied, then try to calculate from the case party
     v_result := f_DCM_assignCaseFn(
           --Context   => 'ASSIGN_CASE',
           action    => 'ASSIGN_TO_PARTY', 
           case_id   => v_CaseId, 
           caseparty_id  => f_PPL_getCasePartyByCode(CaseID => v_CaseId, ParticipantCode => v_participant_code),  
           errorcode     => v_tempErrCd, 
           errormessage  => v_tempErrMsg, 
           note          => NULL, 
           successresponse => v_tempSccss, 
           workbasket_id   => NULL
          );  
		
	ELSIF v_rule_code IS NOT NULL THEN
		--if rule code is supplied, then try to calculate using an invoker
		v_wb := TO_NUMBER(f_UTIL_genericInvokerFn(ProcessorName => v_rule_code, TargetType => 'CASE', TargetId => v_CaseId));
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Workbasket Rule invoked and returned ' || NVL(TO_CHAR(v_wb), '==NOTHING=='));
    v_result := f_DCM_assignCaseFn(
           --Context   => 'ASSIGN_CASE',
           action    => 'ASSIGN', 
           case_id   => v_CaseId, 
           caseparty_id  => NULL,  
           errorcode     => v_tempErrCd, 
           errormessage  => v_tempErrMsg, 
           note          => NULL, 
           successresponse => v_tempSccss, 
           workbasket_id   => v_wb
          );
	ELSE
		v_tempErrCd := 120;
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: This event is missing both a Participant Code and a Workbasket Rule');
		GOTO cleanup;
	END IF;
	
	--DETERMINE IF ASSIGNMENT WAS SUCCESSFUL
	IF v_result > 0 AND NVL(v_tempErrCd, 0) = 0 THEN
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
		TargetID => v_CaseId, 
		TargetType=>'CASE'
	);		
	
	:ValidationResult := 0;
	:Message := v_tempErrMsg;
	RETURN -1;

END;