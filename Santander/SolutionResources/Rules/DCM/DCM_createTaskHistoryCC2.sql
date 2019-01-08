declare
  v_TaskId Integer;
  v_Message nclob;
  v_result nclob;
  v_name nvarchar2(255);
  v_issystem number;
  v_prevtaskstate Integer;
  v_nexttaskstate Integer;
  v_result2 number;
begin
  v_TaskId := :TaskId;
  v_Message := :Message;
  if v_Message is null then
    return -1;
  end if;
  v_issystem := :IsSystem;
  begin
    select name into v_name from vw_users where accesssubjectcode = SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
    exception
      when NO_DATA_FOUND then
        v_name := null;
  end;
  begin
    select twi.col_tw_workitemccprevtaskst, twi.col_tw_workitemccdict_taskst into v_prevtaskstate, v_nexttaskstate
    from tbl_tw_workitemcc twi
    inner join tbl_taskcc tsk on twi.col_id = tsk.col_tw_workitemcctaskcc
    where tsk.col_id = v_TaskId;
    exception
    when NO_DATA_FOUND then
    v_prevtaskstate := null;
    v_nexttaskstate := null;
  end;
  v_result2 := f_DCM_fwrdHistoryCC();
  insert into tbl_historycc(col_historycctaskcc, col_createdbyname, col_description, col_activitytimedate, col_issystem, col_historyccprevtaskstate, col_historyccnexttaskstate)
    values (v_TaskId, v_name, v_result, sysdate, v_issystem, v_prevtaskstate, v_nexttaskstate);
end;