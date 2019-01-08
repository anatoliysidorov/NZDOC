declare
  v_TaskId Integer;
  v_CaseId Integer;
  v_StateConfigId Integer;
  v_CurrTaskState Integer;
  v_PrevTaskState Integer;
  v_TaskClosedStateId Integer;
  v_result number;
begin
  v_TaskId := :TaskId;
  begin
    select nvl(col_stateconfigtasksystype,0) into v_StateConfigId from tbl_dict_tasksystype where col_id =
          (select col_taskdict_tasksystype from tbl_task where col_id = v_TaskId);
    exception
    when NO_DATA_FOUND then
    v_StateConfigId := 0;
  end;
  v_TaskClosedStateId := f_DCM_getTaskClosedState3(StateConfigId => v_StateConfigId);
  begin
    select twi.col_tw_workitemdict_taskstate, twi.col_tw_workitemprevtaskstate, tsk.col_casetask into v_CurrTaskState, v_PrevTaskState, v_CaseId
    from tbl_tw_workitem twi inner join tbl_task tsk on twi.col_id = tsk.col_tw_workitemtask where tsk.col_id = v_TaskId;
    exception
    when NO_DATA_FOUND then
    v_CurrTaskState := 0;
    v_PrevTaskState := 0;
    v_CaseId := 0;
  end;
  if v_PrevTaskState = v_TaskClosedStateId and v_CurrTaskState <> v_TaskClosedStateId then
    delete from tbl_slaactionqueue where col_slaactionqueueslaevent in (select col_id from tbl_slaevent where col_slaeventtask = v_TaskId);
    update tbl_slaevent set col_attemptcount = 0 where col_slaeventtask = v_TaskId;
    v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
  end if;
end;