declare
  v_CaseId Integer;
  v_result number;
begin
  v_CaseId := :CaseId;
  v_result := f_dcm_statcasemonth (CaseId => v_CaseId);
  v_result := f_dcm_statcaseweek (CaseId => v_CaseId);
  v_result := f_dcm_statcaseday (CaseId => v_CaseId);
end;