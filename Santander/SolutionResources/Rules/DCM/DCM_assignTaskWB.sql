declare
  v_TaskId Integer;
  v_dateassigned date;
  v_UserAccessSubject nvarchar2(255);
  v_TokenDomain nvarchar2(255);
  v_stateNew nvarchar2(255);
  v_stateStarted nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_WorkbasketId Integer;
  v_WorkbasketCode nvarchar2(255);
begin
  v_dateassigned := sysdate;
  v_TaskId := :TaskId;
  --CALCULATE WORKBASKET ID BASED ON BUSINESS LOGIC
  begin
    select col_id into v_WorkbasketId from tbl_ppl_workbasket where col_name = 'WB_IGOR';
    exception
      when NO_DATA_FOUND then
        v_WorkbasketId := null;
        :TaskAssigned := 0;
        return -1;
  end;
  select sys_context('CLIENTCONTEXT', 'AccessSubject') into v_UserAccessSubject from dual;
  v_TokenDomain := f_dcm_getscalarsetting(p_name => 'TOKEN_DOMAIN', defaultresult => null);
  v_stateClosed := f_dcm_getTaskClosedState();
  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  :TaskAssigned := 1;
  begin
    select col_code into v_WorkbasketCode from tbl_ppl_workbasket where col_id = v_WorkbasketId;
    exception
      when NO_DATA_FOUND then
        :TaskAssigned := 0;
        return -1;
  end;
  begin
    update tbl_task set col_taskpreviousworkbasket = col_taskppl_workbasket, col_taskppl_workbasket = v_WorkbasketId,
                        col_dateassigned = v_dateassigned
    where col_id = v_TaskId;
    exception 
      when NO_DATA_FOUND then
        :TaskAssigned := 0;   
      when DUP_VAL_ON_INDEX then
        :TaskAssigned := 0;   
  end;
end;