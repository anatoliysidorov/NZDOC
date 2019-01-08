DECLARE
	v_TargetType NVARCHAR2(30);
	v_TargetID INT;
	v_result INT;

BEGIN
	v_result:= f_DOC_getContextFn(DocumentID => :DocumentID, TargetID => v_TargetID, TargetType => v_TargetType);
	v_TargetType := UPPER(v_TargetType);
	
	IF v_TargetType = 'CASE' THEN
		v_result := f_DCM_genCaseTypeMsgPh(PlaceholderResult => :PlaceholderResult, CaseId => v_TargetID);
	ELSIF v_TargetType = 'TASK' THEN
		v_result := f_DCM_genTaskTypeMsgPh(PlaceholderResult => :PlaceholderResult, TaskId => v_TargetID);
	ELSE
		:PlaceholderResult := '<b>' || 'UNKNOWN' || '</b>';
	END IF;

EXCEPTION
WHEN no_data_found THEN
    :PlaceholderResult := 'NONE';
WHEN OTHERS THEN
    :PlaceholderResult := 'SYSTEM ERROR';
END;