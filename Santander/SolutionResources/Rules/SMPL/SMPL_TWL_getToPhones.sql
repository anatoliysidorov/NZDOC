DECLARE 
    v_taskid    NUMBER; 
    v_phonelist NCLOB; 
BEGIN 
    v_taskid := :TaskId; 
	:Result := '+1(555)555-5555,+1(555)555-1234';     
END; 