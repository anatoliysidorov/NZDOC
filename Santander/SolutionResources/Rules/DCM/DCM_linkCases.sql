declare
  v_result number;
  v_ParentCaseId Integer;
  v_ParentTaskId Integer;
  v_ChildCaseId Integer;
  v_ChildTaskId Integer;
begin
  v_ParentCaseId := :ParentCaseId;
  v_ParentTaskId := :ParentTaskId;
  v_ChildCaseId := :ChildCaseId;
  v_ChildTaskId := :ChildTaskId;
  insert into tbl_caselink(col_caselinkparentcase, col_caselinkparenttask, col_caselinkchildcase, col_caselinkchildtask)
  values(v_ParentCaseId, v_ParentTaskId, v_ChildCaseId, v_ChildTaskId);
  select gen_tbl_caselink.nextval into v_result from dual;
end;