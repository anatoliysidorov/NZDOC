declare
    v_result number;
    v_caseid Integer;
begin
    v_caseid := :caseId;
    if f_DCM_caseCreatedByMe(caseId => v_caseid) = 1 or f_DCM_caseAssignedToGroup(caseId => v_caseId) = 1 then
      return 1;
    else
      return 0;
    end if;
end; 