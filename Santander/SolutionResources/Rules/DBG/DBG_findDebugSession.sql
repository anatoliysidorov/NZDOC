declare
  v_result number;
  v_CaseId Integer;
  v_SessionId Integer;
  v_User nvarchar2(255);
  v_sessionIDVarchar NVARCHAR2(255);
begin
  v_CaseId := CaseId;
  v_User := sys_context('CLIENTCONTEXT', 'AccessSubject');
  v_sessionIDVarchar := sys_context('CLIENTCONTEXT', 'SessionGuid');
  begin
    select col_id into v_SessionId from tbl_debugsession where col_sessionuser = v_User 
   /* AND col_debugsessioncase = nvl(v_CaseId,0)*/
    AND col_code  = v_sessionIDVarchar;
    exception
    when NO_DATA_FOUND then
      v_SessionId := null;
      return v_SessionId;
  end;
  return v_SessionId;
end;