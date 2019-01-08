declare
  v_result nvarchar2(255);
  v_CaseId Integer;
begin
  v_CaseId := :CaseId;
  v_result :=  'CASE-' || to_char(sysdate, 'YYYY')|| '-' || To_char(v_CaseId);
  :CaseTitle := v_result;
end;