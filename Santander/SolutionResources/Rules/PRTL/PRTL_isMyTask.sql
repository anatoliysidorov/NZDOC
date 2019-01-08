declare
  v_result number;
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  begin
    select t.ID into v_result
    from vw_dcm_simpletask t
    inner join tbl_ppl_workbasket wb on t.workbasket_id = wb.col_id
    inner join tbl_externalparty ep on wb.col_workbasketexternalparty = ep.col_id
    inner join vw_users vu on ep.col_userid = vu.userid
    where t.ID = v_TaskId and vu.accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject');
    exception
    when NO_DATA_FOUND then
    v_result := 0;
  end;
  return case when v_result > 0 then 1 else 0 end;
end;