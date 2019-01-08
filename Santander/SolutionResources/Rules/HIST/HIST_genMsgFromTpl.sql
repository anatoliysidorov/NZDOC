BEGIN 
	:Result := f_HIST_genMsgFromTplFn(MessageCode => :MessageCode, targetid => :TargetId, targettype => :TargetType); 
	:ErrorCode := 0; 
	:ErrorMessage := ''; 
EXCEPTION 
WHEN OTHERS THEN
	:ErrorCode := SQLCODE; 
	:ErrorMessage := SQLERRM; 
END;