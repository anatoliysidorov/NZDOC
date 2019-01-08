declare
  v_result number;
  v_parentid Integer;
  v_message nclob;
begin
  v_parentid := :ParentId;
  v_message := :Message;
  begin
    select s1.ThreadId into v_result
    from
    (select col_id as ThreadId, row_number() over (order by col_id desc) as RowNumber from tbl_thread
    where col_id = v_parentid and lower(col_status) = 'active') s1
    where s1.RowNumber = 1;
    exception
    when NO_DATA_FOUND then
    v_result := 0;
    return 0;
  end;
  insert into tbl_thread (col_code, col_datestarted, col_threadsourcetask, col_threadtargettask, col_message, col_datemessage, col_messageworkbasket, col_threadworkbasket, col_status, col_parentmessageid)
  select col_code, col_datestarted, col_threadsourcetask, col_threadtargettask, v_message, sysdate,
            (select wb.col_id from vw_ppl_activecaseworkersusers cwu
            inner join tbl_ppl_workbasket wb on cwu.id = wb.col_caseworkerworkbasket
            inner join tbl_dict_workbaskettype wbt on wbt.col_id = wb.col_workbasketworkbaskettype AND wbt.col_code = 'PERSONAL'
            where cwu.accode = sys_context('CLIENTCONTEXT', 'accesssubject')),
            (select wb.col_id from vw_ppl_activecaseworkersusers cwu
            inner join tbl_ppl_workbasket wb on cwu.id = wb.col_caseworkerworkbasket
            inner join tbl_dict_workbaskettype wbt on wbt.col_id = wb.col_workbasketworkbaskettype AND wbt.col_code = 'PERSONAL'
            where cwu.accode = sys_context('CLIENTCONTEXT', 'accesssubject')), col_status, v_parentid from tbl_thread where col_id = v_result;
  select gen_tbl_thread.currval into v_result from dual;
  return v_result;
end;