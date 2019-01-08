DECLARE
	--input
	v_TaskID INTEGER;
	v_DataKey NVARCHAR2(255); 
	
	--calculated
	v_temp INTEGER;
	v_result NVARCHAR2(255); 
BEGIN 
	--input
	v_TaskID := :TaskId;
	v_DataKey := lower(:DataKey);
	
	--calculate values	
	IF v_DataKey = 'tasktype' THEN
		v_temp := f_DCM_genTaskTypeMsgPh(TaskId=> v_TaskID, PlaceholderResult => v_result);
		
	ELSIF v_DataKey = 'taskname' THEN
		v_temp := f_DCM_genTaskNameMsgPh(TaskId=> v_TaskID, PlaceholderResult => v_result);
		
	ELSIF v_DataKey = 'taskid' THEN
		v_temp := f_DCM_genTaskIdMsgPh(TaskId=> v_TaskID, PlaceholderResult => v_result);
		
	ELSE
		v_result := '==MISSING DATA KEY==';	
	END IF;
	
	:ResultText := v_result;
	
EXCEPTION  
	WHEN OTHERS THEN 
		:ResultText := 'SYSTEM ERROR'; 
END;