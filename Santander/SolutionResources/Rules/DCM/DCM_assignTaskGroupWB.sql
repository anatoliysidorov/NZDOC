declare
  v_TaskId Integer;
  v_state nvarchar2(255);
  v_dateassigned date;
  v_UserAccessSubject nvarchar2(255);
  v_TokenDomain nvarchar2(255);
  v_stateNew nvarchar2(255);
  v_stateStarted nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_WorkbasketId Integer;
  v_WorkbasketCode nvarchar2(255);
  v_result number;
begin
  v_state := :State;
  v_TaskId := :TaskId;
  begin
    select col_canassign into v_result from tbl_dict_taskstate where col_activity = v_state;
    exception
      when NO_DATA_FOUND then
        :TaskAssigned := 0;
        return -1;
  end;
  begin
    select arp.col_paramvalue into v_WorkbasketCode
    from tbl_autoruleparameter arp
    inner join tbl_map_taskstateinitiation tsi on arp.col_ruleparam_taskstateinit = tsi.col_id
    inner join tbl_dict_taskstate dts on tsi.col_map_tskstinit_tskst = dts.col_id
    where tsi.col_map_taskstateinittask = v_TaskId and dts.col_activity = v_State;
    exception
      when NO_DATA_FOUND then
        :TaskAssigned := 0;
        return -1;
  end;
  begin
    select col_id into v_WorkbasketId from tbl_ppl_workbasket where col_code = v_WorkbasketCode;
    exception
      when NO_DATA_FOUND then
        v_WorkbasketId := -1;
        :TaskAssigned := 0;
        return -1;
      when TOO_MANY_ROWS then
        v_WorkbasketId := -1;
        :TaskAssigned := 0;
        return -1;
  end;
  update tbl_task set col_taskpreviousworkbasket = col_taskppl_workbasket, col_taskppl_workbasket = v_Workbasketid, col_dateassigned = v_dateassigned where col_id = v_TaskId;
  :TaskAssigned := 1;
end;