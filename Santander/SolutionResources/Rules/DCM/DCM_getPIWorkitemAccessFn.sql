declare
  v_result number;
  v_workbasketid number;
  v_permissioncode nvarchar2(255);
  v_isdeleted number;
begin
  v_isdeleted := :IsDeleted;
  v_workbasketid := :WorkbasketId;
  v_permissioncode := :PermissionCode;
  begin
    select allowed into v_result from table(f_DCM_getAccSubjectAccessFn(p_AccessObjectId => (select col_id from tbl_ac_accessobject where col_code = 'WORKITEM'),
         p_AccessSubjectId => (select col_id from tbl_ac_accesssubject where col_code = (select f_DCM_calcAccessSubject(IsDeleted => v_isdeleted, WorkbasketId => v_workbasketid) from dual)),
                                                p_PermissionId => (select col_id from tbl_ac_permission where col_code = v_permissioncode and col_permissionaccessobjtype =
                                                (select col_id from tbl_ac_accessobjecttype where col_code = 'WORKITEM'))));
    exception
    when NO_DATA_FOUND then
      v_result := null;
  end;
  return v_result;
end;