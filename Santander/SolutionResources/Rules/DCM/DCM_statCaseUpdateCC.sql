declare
  v_CaseId Integer;
begin
  v_CaseId := :CaseId;
  update tbl_casecc set col_statupdated = 1 where col_id = v_CaseId;
end;