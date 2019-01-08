declare
	v_taskid            integer;
	v_resolutioncode    nvarchar2(255);    
	v_errorcode         number;
	v_errormessage      nclob;
	v_ResolutionId      number;
	v_result            number;	
begin
	v_taskid := :TaskId;    
	v_resolutioncode := :ResolutionCode;
	
	v_result := f_DCM_getTaskResolutionIdFn(ErrorCode => v_errorcode, ErrorMessage => v_errormessage, ResolutionId => v_ResolutionId,
											ResolutionCode => v_resolutioncode, TaskId => v_taskid);
    
	:ErrorCode := v_errorcode;
	:ErrorMessage := v_errormessage;
	:ResolutionId := v_ResolutionId;
end;