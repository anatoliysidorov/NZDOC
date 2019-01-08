declare
  v_DebugSession nvarchar2(255);
  v_result number;
  v_CaseId Integer;
  v_TaskId Integer;
  v_Rule nvarchar2(255);
  v_Message nclob;
  v_Location nvarchar2(255);
  v_CaseTypeId Integer;
  v_ProcedureId Integer;
begin
  v_CaseTypeId := :CaseTypeId;
  v_ProcedureId := :ProcedureId;
  v_CaseId := :CaseId;
  v_Location := :Location;
  v_Message := :Message;
  v_Rule := :Rule;
  v_TaskId := :TaskId;
  v_DebugSession := null;
  if f_DBG_isDebugOn(CaseTypeId => v_CaseTypeId, ProcedureId => v_ProcedureId) > 0 and f_DBG_findDebugSession(CaseId => v_CaseId) > 0 then
    v_DebugSession := f_DBG_createDebugSession(CaseId => v_CaseId);
    v_result := f_DBG_addDebugTrace(CaseId => v_CaseId, Location => v_Location, Message => v_Message, Rule => v_Rule, TaskId => v_TaskId);
  end if;
  return v_DebugSession;
end;