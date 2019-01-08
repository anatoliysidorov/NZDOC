declare
  v_result number;
  v_CaseId Integer;
begin
  v_CaseId := :CaseId;
  v_result := 1;
  :ValidationResult := v_result;
end;