declare
  v_CaseId Integer;
begin
  v_CaseId := :CaseId;
  --SET CASE BACK TO IN_PROCESS
  begin
    update tbl_cw_workitem
      set col_activity = 'root_CS_Status_IN_PROCESS'
      where col_id = (select col_cw_workitemcase
                        from tbl_case
                        where col_id = v_CaseId);
    update tbl_case set col_activity = 'root_CS_Status_IN_PROCESS' where col_id = v_CaseId;
    exception
      when NO_DATA_FOUND then
        :affectedRows := -1;
  end;
end;