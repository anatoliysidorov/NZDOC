DECLARE 
    --input/output
	v_PlaceholderResult NVARCHAR2(255); 	
	v_result int;
BEGIN  
	v_result := f_DCM_genCaseStateMsgPh(CaseId => :TaskId, PlaceholderResult => v_PlaceholderResult); --because of legacy 
	:PlaceholderResult := v_PlaceholderResult;
END;