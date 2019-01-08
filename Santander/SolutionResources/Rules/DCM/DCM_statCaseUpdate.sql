declare
  v_CaseId Integer;
begin
  v_CaseId := :CaseId;
  update tbl_case set col_statupdated = 1 where col_id = v_CaseId;
end;