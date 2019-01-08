DECLARE 
    v_caseid    NUMBER; 
BEGIN 
    v_caseid := :CaseId; 
	:Result := TO_CHAR(f_DCM_getMyPersonalWorkbasket());  
END; 