DECLARE
	--input
	v_TaskID INTEGER;
	v_CaseID INTEGER;
	v_DataKey NVARCHAR2(255); 
	
	--calculated
	v_temp INTEGER;
	v_result NVARCHAR2(255); 
BEGIN 
	--input
	v_TaskID := :TaskId;
	v_CaseID := NVL(:CaseID, f_DCM_getCaseIdByTaskId(v_TaskID));
	v_DataKey := lower(:DataKey);
	
	--calculate values
	IF v_DataKey = 'caseid' THEN
		v_temp := f_DCM_genCaseIdMsgPh(CaseId=> v_CaseID, PlaceholderResult => v_result);
		
	ELSIF v_DataKey = 'casesummary' THEN
		v_temp := f_DCM_genCaseSummMsgPh(CaseId=> v_CaseID, PlaceholderResult => v_result);
		
	ELSIF v_DataKey = 'casetype' THEN
		v_temp := f_DCM_genCaseTypeMsgPh(CaseId=> v_CaseID, PlaceholderResult => v_result);
	
	ELSIF v_DataKey = 'casemilestone' THEN
		v_temp := f_DCM_genCaseMlstnMsgPh(CaseId=> v_CaseID, PlaceholderResult => v_result);
		
	ELSE
		v_result := '==MISSING DATA KEY==';	
	END IF;
	
	:ResultText := v_result; 
	
EXCEPTION  
	WHEN OTHERS THEN 
		:ResultText := 'SYSTEM ERROR'; 
END;