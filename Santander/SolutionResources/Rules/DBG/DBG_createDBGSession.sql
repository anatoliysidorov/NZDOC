declare
  v_DebugSession nvarchar2(255);
  v_result number;
  v_CaseId Integer;
  v_CaseTypeId Integer;
  v_ProcedureId Integer;
  v_sessionGUID NVARCHAR2(255);
begin
  v_CaseTypeId := :CaseTypeId;
  v_ProcedureId := :ProcedureId;
  v_CaseId := :CaseId;
  v_DebugSession := null;
    /**/  
  v_sessionGUID := sys_context('CLIENTCONTEXT', 'SessionGuid');

  IF v_sessionGUID IS NULL THEN 
       DBMS_SESSION.SET_CONTEXT (
                 namespace =>  'CLIENTCONTEXT',
                 ATTRIBUTE =>  'SessionGuid',
                 value     =>   sys_guid(),
                 username  =>   sys_context('CLIENTCONTEXT', 'AccessSubject')
                 );
  END IF;    
  /**/
  if f_DBG_isDebugOn(CaseTypeId => v_CaseTypeId, ProcedureId => v_ProcedureId) > 0 then
    v_DebugSession := f_DBG_createDebugSession(CaseId => v_CaseId);
  end if;
  return v_DebugSession;
end;