BEGIN 
	:Result := F_util_genericinvokerfn(processorname => :ProcessorName, targetid => :TargetId, targettype => :TargetType); 
	:ErrorCode := 0; 
	:ErrorMessage := ''; 
EXCEPTION 
WHEN OTHERS THEN
	:ErrorCode := SQLCODE; 
	:ErrorMessage := SQLERRM; 
END;