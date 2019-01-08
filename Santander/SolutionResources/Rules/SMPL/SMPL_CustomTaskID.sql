DECLARE 
    v_taskid    NUMBER;     
BEGIN 
    v_taskid := :TaskId; 
	return 'SOMETITLE-' || TO_CHAR(v_taskid);
END; 