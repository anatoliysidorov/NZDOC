declare
  v_TaskId Integer;
  v_Message nclob;
  v_result nclob;
  v_name nvarchar2(255);
  v_issystem number;
  v_prevtaskstate Integer;
  v_nexttaskstate Integer;
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
    select twi.col_tw_workitemprevtaskstate, twi.col_tw_workitemdict_taskstate into v_prevtaskstate, v_nexttaskstate
    from tbl_tw_workitem twi
    inner join tbl_task tsk on twi.col_id = tsk.col_tw_workitemtask
    where tsk.col_id = v_TaskId;
    exception
    when NO_DATA_FOUND then
    v_prevtaskstate := null;
    v_nexttaskstate := null;
  end;
  insert into tbl_history(col_historytask, col_createdbyname, col_description, col_activitytimedate, col_issystem, col_historyprevtaskstate, col_historynexttaskstate)
    values (v_TaskId, v_name, v_Message, sysdate, v_issystem, v_prevtaskstate, v_nexttaskstate);
end;