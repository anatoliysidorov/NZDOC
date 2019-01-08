declare
  v_CaseTypeId Integer;
begin
  --dbms_output.enable(500000);
  delete from tbl_ac_casetypeviewcache;
  delete from tbl_ac_casetypedetailcache;
  delete from tbl_ac_casetypemodifycache;
  for rec in (select col_id as CaseTypeId, col_code as CaseTypeCode from tbl_dict_casesystype order by col_id)
  loop
    for rec2 in (select id as CaseworkerId, userid as CaseworkerUserId, accode as AccessSubjectCode
                 from vw_ppl_activecaseworkersusers
                 order by id)
    loop
      --dbms_output.put_line('CaseTypeId= ' || rec.CaseTypeId || ' CaseTypeCode= ' || rec.CaseTypeCode);
      --dbms_output.put_line('CaseworkerId= ' || rec2.CaseworkerId || ' AccessSubjectCode= ' || rec2.AccessSubjectCode);
      begin
        select ct.col_id into v_CaseTypeId
        from tbl_dict_casesystype ct
        where 1 in (select Allowed from table(f_dcm_getCaseworkerAccessFn2(p_AccessObjectId => (select ao.col_id
                                                                      from tbl_ac_accessobject ao
                                                                      inner join tbl_dict_casesystype cst on ao.col_accessobjectcasesystype = cst.col_id
                                                                      inner join tbl_ac_accessobjecttype aot on ao.col_accessobjaccessobjtype = aot.col_id
                                                                      where lower(aot.col_code) = 'case_type' and cst.col_id = rec.CaseTypeId),
                                                 p_CaseId => null,
                                                 p_CaseworkerId => (select id
                                                                    from vw_ppl_activecaseworkersusers
                                                                    where accode = rec2.AccessSubjectCode),
                                                 p_PermissionId => (select col_id from tbl_ac_permission where col_code = 'VIEW' and col_permissionaccessobjtype =
                                                                    (select col_id from tbl_ac_accessobjecttype where col_code = 'CASE_TYPE')),
                                                 p_TaskId => null)) where caseworkertype = 'CASEWORKER')
        and ct.col_id = rec.CaseTypeId;
        exception
        when NO_DATA_FOUND then
        v_CaseTypeId := null;
        when OTHERS then
        --dbms_output.put_line(substr(sqlerrm,128));
        v_CaseTypeId := null;
        return -1;
      end;
      if nvl(v_CaseTypeId, 0) > 0 then
        insert into tbl_ac_casetypeviewcache(col_cstpviewcachecaseworker, col_accesssubjectcode, col_casetypeviewcachecasetype)
        values(rec2.CaseworkerId, rec2.AccessSubjectCode, rec.CaseTypeId);
      end if;
      begin
        select ct.col_id into v_CaseTypeId
        from tbl_dict_casesystype ct
        where 1 in (select Allowed from table(f_dcm_getCaseworkerAccessFn2(p_AccessObjectId => (select ao.col_id
                                                                      from tbl_ac_accessobject ao
                                                                      inner join tbl_dict_casesystype cst on ao.col_accessobjectcasesystype = cst.col_id
                                                                      inner join tbl_ac_accessobjecttype aot on ao.col_accessobjaccessobjtype = aot.col_id
                                                                      where lower(aot.col_code) = 'case_type' and cst.col_id = rec.CaseTypeId),
                                                 p_CaseId => null,
                                                 p_CaseworkerId => (select id
                                                                    from vw_ppl_activecaseworkersusers
                                                                    where accode = rec2.AccessSubjectCode),
                                                 p_PermissionId => (select col_id from tbl_ac_permission where col_code = 'DETAIL' and col_permissionaccessobjtype =
                                                                    (select col_id from tbl_ac_accessobjecttype where col_code = 'CASE_TYPE')),
                                                 p_TaskId => null)) where caseworkertype = 'CASEWORKER')
        and ct.col_id = rec.CaseTypeId;
        exception
        when NO_DATA_FOUND then
        v_CaseTypeId := null;
        when OTHERS then
        --dbms_output.put_line(substr(sqlerrm,128));
        v_CaseTypeId := null;
        return -1;
      end;
      if nvl(v_CaseTypeId, 0) > 0 then
        insert into tbl_ac_casetypedetailcache(col_cstpdetcachecaseworker, col_accesssubjectcode, col_casetypedetcachecasetype)
        values(rec2.CaseworkerId, rec2.AccessSubjectCode, rec.CaseTypeId);
      end if;
      begin
        select ct.col_id into v_CaseTypeId
        from tbl_dict_casesystype ct
        where 1 in (select Allowed from table(f_dcm_getCaseworkerAccessFn2(p_AccessObjectId => (select ao.col_id
                                                                      from tbl_ac_accessobject ao
                                                                      inner join tbl_dict_casesystype cst on ao.col_accessobjectcasesystype = cst.col_id
                                                                      inner join tbl_ac_accessobjecttype aot on ao.col_accessobjaccessobjtype = aot.col_id
                                                                      where lower(aot.col_code) = 'case_type' and cst.col_id = rec.CaseTypeId),
                                                 p_CaseId => null,
                                                 p_CaseworkerId => (select id
                                                                    from vw_ppl_activecaseworkersusers
                                                                    where accode = rec2.AccessSubjectCode),
                                                 p_PermissionId => (select col_id from tbl_ac_permission where col_code = 'MODIFY' and col_permissionaccessobjtype =
                                                                    (select col_id from tbl_ac_accessobjecttype where col_code = 'CASE_TYPE')),
                                                 p_TaskId => null)) where caseworkertype = 'CASEWORKER')
        and ct.col_id = rec.CaseTypeId;
        exception
        when NO_DATA_FOUND then
        v_CaseTypeId := null;
        when OTHERS then
        --dbms_output.put_line(substr(sqlerrm,128));
        v_CaseTypeId := null;
        return -1;
      end;
      if nvl(v_CaseTypeId, 0) > 0 then
        insert into tbl_ac_casetypemodifycache(col_cstpmodcachecaseworker, col_accesssubjectcode, col_casetypemodcachecasetype)
        values(rec2.CaseworkerId, rec2.AccessSubjectCode, rec.CaseTypeId);
      end if;
    end loop;
  end loop;
end;