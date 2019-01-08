declare
  v_result number;
begin
  begin
    select Allowed into v_result from table(f_dcm_getCaseworkerAccessFn2(p_AccessObjectId => :AccessObjectId, p_CaseId => null,
                                                       p_CaseworkerId => (select id from vw_ppl_caseworkersusers where accode = sys_context('CLIENTCONTEXT', 'AccessSubject')),
                                                       p_PermissionId => (select col_id from tbl_ac_permission where col_code = 'VIEW' and col_permissionaccessobjtype =
                                                         (select col_id from tbl_ac_accessobjecttype where col_code = 'CASE_TYPE')),
                                                       p_TaskId => null)) where caseworkertype = 'CASEWORKER';
    exception
      when NO_DATA_FOUND then
        v_result := null;
  end;
  return v_result;
end;