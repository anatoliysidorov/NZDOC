declare
  v_CaseId Integer;
  v_status nvarchar2(255);
  v_count number;
begin
  v_CaseId := :CaseId;
  v_status := 'INVALID';
  select count(*) into v_count from tbl_casequeue where col_casecasequeue = v_CaseId and col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = v_status);
  if (v_count is null) or (v_count = 0) then
    insert into tbl_casequeue (col_casecasequeue, col_dict_vldtnstatcasequeue, col_casequeueprocessingstatus)
      values (v_CaseId, (select col_id from tbl_dict_validationstatus where col_code = v_status), (select col_id from tbl_dict_processingstatus where col_code = 'NEW'));
  end if;
end;
