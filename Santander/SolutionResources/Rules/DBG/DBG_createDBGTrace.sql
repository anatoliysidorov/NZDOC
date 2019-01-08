declare
  v_result number;
  v_CaseId Integer;
  v_TaskId Integer;
  v_Rule nvarchar2(255);
  v_Message nclob;
  v_Location nvarchar2(255);
begin
  v_CaseId := :CaseId;
  v_Location := :Location;
  v_Message := :Message;
  v_Rule := :Rule;
  v_TaskId := :TaskId;
  if f_DBG_findDebugSession(CaseId => v_CaseId) is not null then
    v_result := f_DBG_addDebugTrace(CaseId => v_CaseId, Location => v_Location, Message => v_Message, Rule => v_Rule, TaskId => v_TaskId);
  end if;
end;