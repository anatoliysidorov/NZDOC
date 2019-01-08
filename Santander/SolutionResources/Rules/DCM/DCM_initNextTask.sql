declare
  v_NextTaskId Integer;
  v_CaseId Integer;
  v_SystemType nvarchar2(255);
  v_now date;
  v_stateCaseResolved nvarchar2(255);
  v_stateTaskStarted nvarchar2(255);
  v_TaskTypeCaseClosed nvarchar2(255);
  v_result number;
  v_affectedRows number;
begin
  v_NextTaskId := :NextTaskId;
  v_now := sysdate;
  --READ FROM CONFIGURATION ACTIVITY THAT CASE IS SET WHEN RESOLVED
  v_stateCaseResolved := f_dcm_getCaseResolvedState();
  --READ FROM CONFIGURATION ACTIVITY THAT TASK IS SET WHEN RESOLVED
  v_stateTaskStarted := f_dcm_getTaskStartedState();
  --READ FROM CONFIGURATION TASK SYSTEM TYPE THAT IS ASSOCIATED WITH CASE CLOSING
  v_TaskTypeCaseClosed := f_dcm_getscalarsetting(p_name=>'TASK_CASE_CLOSE', defaultresult=>'ReviewClose');
  --FIND CASE ID AND TASK SYSTEM TYPE FOR CURRENT TASK
  begin
	select col_casetask, col_systemtype2 into v_CaseId, v_SystemType from tbl_task where col_id = v_NextTaskId;
	exception
	  when NO_DATA_FOUND then
	    v_CaseId := null;
		v_SystemType := null;
		return -1;
  end;

  --UPDATE CASE STATE IF NEXT TASK IS CASE CLOSING TASK
  if(v_SystemType is not null) and (v_SystemType = v_TaskTypeCaseClosed) then

    begin
      --SET CASE TO RESOLVED STATE
      update tbl_cw_workitem
        set col_activity = v_stateCaseResolved
        where col_id = (select col_cw_workitemcase
                          from tbl_case
                          where col_id = v_CaseId);
      update tbl_case set col_activity = v_stateCaseResolved where col_id = v_CaseId;
        exception
          when NO_DATA_FOUND then
            v_affectedRows := -1;
    end;
  end if;

  --INITIATE NEXT TASK BY ENABLING AND SETTING ASSIGNED DATE
  begin
    update tbl_task
      set col_enabled = 1,
          col_DateAssigned = v_now
      where col_id = v_NextTaskId;
    --SET TASK DATE EVENT
    v_Result := f_DCM_createTaskDateEvent (Name => 'DATE_TASK_ASSIGNED', TaskId => v_NextTaskId);
    exception
      when NO_DATA_FOUND then
        v_affectedRows := -2;
  end;

  --SET NEXT TASK STATE TO STARTED STATE
  begin
    update tbl_tw_workitem
      set col_activity = v_stateTaskStarted, col_tw_workitemprevtaskstate = col_tw_workitemdict_taskstate, col_tw_workitemdict_taskstate = (select col_id from tbl_dict_taskstate where col_activity = v_stateTaskStarted),
	      col_modifieddate = v_now
      where col_id = (select col_tw_workitemtask from tbl_task where col_id = v_NextTaskId);
    --SET TASK DATE EVENT
    v_Result := f_DCM_createTaskDateEvent (Name => 'DATE_TASK_STARTED', TaskId => v_NextTaskId);
    exception
	  when NO_DATA_FOUND then
	    v_affectedRows := -3;
  end;

  --ADD HISTORY RECORD FOR TASK BEING ASSIGNED
  v_Result := f_DCM_addTaskHistory(Status => 12, TaskId => v_NextTaskId);


end;