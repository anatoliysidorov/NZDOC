DECLARE
	v_result INT;
    v_TargetType NVARCHAR2(30);

BEGIN
	v_TargetType := UPPER(:TargetType);
	
	IF v_TargetType = 'CASE' THEN
		v_result := f_DCM_genCaseTypeMsgPh(PlaceholderResult => :PlaceholderResult, CaseId => :TargetID);
	ELSIF v_TargetType = 'TASK' THEN
		v_result := f_DCM_genTaskTypeMsgPh(PlaceholderResult => :PlaceholderResult, TaskId => :TargetID);
	ELSE
		:PlaceholderResult := '<b>' || 'UNKNOWN' || '</b>';
	END IF;

EXCEPTION
WHEN no_data_found THEN
    :PlaceholderResult := 'NONE';
WHEN OTHERS THEN
    :PlaceholderResult := 'SYSTEM ERROR';
END;