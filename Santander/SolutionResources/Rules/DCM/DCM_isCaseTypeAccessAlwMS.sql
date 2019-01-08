declare
  v_result number;
  v_allow number;
begin
  v_allow := 0;
  if :AccessObjectId is null then
    return v_allow;
  end if;
  for rec in
  (select CaseworkerId from table(f_DCM_getProxyAssignorList()))
  loop
    select Allowed into v_result from table(f_dcm_getCaseworkerAccessFn2(p_AccessObjectId => :AccessObjectId, p_CaseId => null,
                                                       p_CaseworkerId => rec.CaseworkerId,
                                                       p_PermissionId => (select col_id from tbl_ac_permission where col_code = 'VIEW' and col_permissionaccessobjtype =
                                                         (select col_id from tbl_ac_accessobjecttype where col_code = 'CASE_TYPE')),
                                                       p_TaskId => null)) where caseworkertype = 'CASEWORKER';
    if v_result = 1 then
      v_allow := 1;
      return v_allow;
    end if;
  end loop;
  return v_allow;
end;