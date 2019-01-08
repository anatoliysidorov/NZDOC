declare
  v_CaseId Integer;
  v_result number;
begin
  v_CaseId := :CaseId;
  v_result := f_dcm_statcasemonthCC (CaseId => v_CaseId);
  v_result := f_dcm_statcaseweekCC (CaseId => v_CaseId);
  v_result := f_dcm_statcasedayCC (CaseId => v_CaseId);
end;