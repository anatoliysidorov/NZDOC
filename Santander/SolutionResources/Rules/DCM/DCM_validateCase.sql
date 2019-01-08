declare
  v_CaseId Integer;
  v_status nvarchar2(255);
begin
  v_CaseId := :CaseId;
  v_status := 'INVALID';
  delete from tbl_casequeue where col_casecasequeue = v_CaseId and col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = v_status);
  /*
  update tbl_casequeue set col_casequeueprocessingstatus = 1 where col_casecasequeue = v_CaseId and col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = v_status);
  update tbl_casequeue
  set col_casequeueprocessingstatus = (select col_id from tbl_dict_processingstatus where col_code = 'PROCESSED'),
  col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = 'VALID')
  where col_casecasequeue = v_CaseId and col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = v_status);
  */
end;