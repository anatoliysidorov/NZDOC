declare
  v_result number;
  v_CaseTypeId Integer;
  v_ProcedureId Integer;
  v_User nvarchar2(255);
  v_debugmode Integer;
begin
  v_CaseTypeId := :CaseTypeId;
  v_ProcedureId := :ProcedureId;
  v_User := sys_context('CLIENTCONTEXT', 'AccessSubject');
  v_debugmode := 0;
  if nvl(v_CaseTypeId, 0) > 0 then
    begin
      select nvl(col_debugmode, 0) into v_debugmode from tbl_dict_casesystype where col_id = v_CaseTypeId;
      exception
      when NO_DATA_FOUND then
        v_debugmode := 0;
    end;
  end if;
  if v_debugmode = 1 then
    return v_debugmode;
  end if;
  if nvl(v_ProcedureId, 0) > 0 then
    begin
      select nvl(col_debugmode, 0) into v_debugmode from tbl_procedure where col_id = v_ProcedureId;
      exception
      when NO_DATA_FOUND then
        v_debugmode := 0;
    end;
  end if;
  return v_debugmode;
end;