declare 
    v_taskid                   integer;
    v_resolutioncode           nvarchar2(255);    
    v_tasktypeid               integer;
    v_errorcode                number;
    v_errormessage             nclob;
begin 
    v_taskid := :TaskId;
    v_resolutioncode := :ResolutionCode;
	
	if (v_taskid is null) then 	
		:ErrorCode := 200;
		:ErrorMessage := 'TaskId is required';
		:ResolutionId := 0;
		return -1;
	end if;
	
	if (v_resolutioncode is null) then 
		:ErrorCode := 200;
		:ErrorMessage := 'ResolutionCode is required';
		:ResolutionId := 0;
		return -1;
	end if;
	
    if (v_taskid is not null and v_resolutioncode is not null) then	
		begin
		  select col_taskdict_tasksystype into v_tasktypeid from tbl_task where col_id = v_TaskId;
		  exception
		  when NO_DATA_FOUND then
			  v_tasktypeid := null;
			  :ErrorCode := 201;
			  :ErrorMessage := 'Tasktype is empty';
			  :ResolutionId := 0;		  
			  return -1;
		end;
		
		begin
			select rc.col_Id into :ResolutionId
			from Tbl_TaskSysTypeResolutionCode tst
			join tbl_STP_ResolutionCode rc on rc.col_type = 'TASK' and rc.col_id = tst.col_tbl_stp_ResolutionCode and rc.col_code = v_resolutioncode
			where  tst.col_tbl_dict_TaskSystype = v_tasktypeid;
			exception
			when NO_DATA_FOUND then
			  :ErrorCode := 202;
			  :ErrorMessage := 'ResolutionId is not found';
			  :ResolutionId := 0;
		end;
		
	end if;

end;