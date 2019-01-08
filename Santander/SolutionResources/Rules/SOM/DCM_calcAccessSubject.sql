declare
  v_result nvarchar2(255);
  v_isdeleted number;
  v_workbasketid Integer;
begin
  v_isdeleted := :IsDeleted;
  v_workbasketid := :WorkbasketId;
  begin
    select
    case
    when nvl(v_isdeleted, 0) = 1 then 'TRASH'
    when nvl(v_workbasketid, 0) = 0 then 'OWNER_NOBODY'
    when v_workbasketid = (select swb.id
    from vw_ppl_simpleworkbasket swb
    where swb.accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject') and workbaskettype_code = 'PERSONAL') then 'OWNER_MYCW'
    when (select count(*) from vw_ppl_simpleworkbasket swb
    where col_id = v_workbasketid and caseworker_id is not null and swb.accesssubjectcode <> sys_context('CLIENTCONTEXT', 'AccessSubject') and workbaskettype_code = 'PERSONAL') > 0 then 'OWNER_OTHERCW'
    when v_workbasketid in
    (select wb.col_id as WorkbasketId
    from vw_users u
    inner join tbl_ppl_caseworker cw on u.userid = cw.col_userid
    inner join tbl_caseworkerbusinessrole cwbr on cw.col_id = cwbr.col_br_ppl_caseworker
    inner join tbl_ppl_businessrole br on cwbr.col_tbl_ppl_businessrole = br.col_id
    inner join tbl_ppl_workbasket wb on br.col_id = wb.col_workbasketbusinessrole
    where u.accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject')
    union
    select wb.col_id as WorkbasketId
    from vw_users u
    inner join tbl_ppl_caseworker cw on u.userid = cw.col_userid
    inner join tbl_caseworkerteam cwtm on cw.col_id = cwtm.col_tm_ppl_caseworker
    inner join tbl_ppl_team tm on cwtm.col_tbl_ppl_team = tm.col_id
    inner join tbl_ppl_workbasket wb on tm.col_id = wb.col_workbasketteam
    where u.accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject')
    union
    select wb.col_id as WorkbasketId
    from vw_users u
    inner join tbl_ppl_caseworker cw on u.userid = cw.col_userid
    inner join tbl_caseworkerskill cwsk on cw.col_id = cwsk.col_sk_ppl_caseworker
    inner join tbl_ppl_skill sk on cwsk.col_tbl_ppl_skill = sk.col_id
    inner join tbl_ppl_workbasket wb on sk.col_id = wb.col_workbasketskill
    where u.accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject')
    ) then 'OWNER_MYGROUP'
    when v_workbasketid not in (select col_id from tbl_ppl_workbasket) then 'OWNER_NOBODY'
    else 'OWNER_NOBODY' end as AccessSubject into v_result
    from dual;
    exception
    when NO_DATA_FOUND then
    v_result := null;
  end;
  return v_result;
end;