DECLARE 
    v_taskid    NUMBER;     
BEGIN 
    v_taskid := :TaskId; 
	:TaskAssigned :=v_taskid;
END; 