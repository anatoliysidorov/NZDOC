declare
  v_result number;
  v_CaseId Integer;
begin
  v_CaseId := :CaseId;
  v_result := 1;
  insert into tbl_log(col_data1,col_data2) values(v_CaseId, 'f_DCM_processCaseDependency');
  :ValidationResult := v_result;
end;