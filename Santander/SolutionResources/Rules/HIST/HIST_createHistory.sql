DECLARE 
	v_result INTEGER;
BEGIN 
	v_result := f_HIST_createHistoryFn(AdditionalInfo=>:AdditionalInfo, IsSystem=>:IsSystem, Message=>:Message, MessageCode => :MessageCode, TargetID =>:TargetID, TargetType=>:TargetType);
	:ErrorCode := 0; 
	:ErrorMessage := ''; 
EXCEPTION 
WHEN OTHERS THEN
	:ErrorCode := SQLCODE; 
	:ErrorMessage := SQLERRM; 
END;