DECLARE 
    v_caseid    NUMBER; 
BEGIN 
    v_caseid := :CaseId; 
	:Result := 'This is a sample message for testing Twilio';     
END; 