declare
  v_names nclob;
  v_rn number;
  v_total number;
begin
  begin
    select substr (sys_connect_by_path (UserName, ','), 2), rn, cnt_total
      into v_names, v_rn, v_total
    from
    (select pr.accesssubject, cwu.name as UserName, row_number() over (order by cwu.name) rn, count(*) over() cnt_total from table(f_dcm_getproxyassignorlist()) pr
       left join vw_ppl_activecaseworkersusers cwu on pr.accesssubject = cwu.accode
       where accesssubject <> sys_context('CLIENTCONTEXT', 'AccessSubject'))
    where rn = cnt_total
    start with rn = 1
    connect by rn = prior rn + 1;
    exception
    when NO_DATA_FOUND then
      v_names := null;
  end;
  return v_names;
end;