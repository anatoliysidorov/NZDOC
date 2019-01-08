DECLARE 
    v_taskid    NUMBER; 
    v_phonelist NCLOB; 
BEGIN 
    v_taskid := :TaskId; 
	:Result := TO_CHAR(f_DCM_getMyPersonalWorkbasket());  
END; 