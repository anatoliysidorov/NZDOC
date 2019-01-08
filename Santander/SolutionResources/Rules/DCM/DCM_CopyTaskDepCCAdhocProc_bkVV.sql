declare
  v_TransactionId Integer;
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
   v_counter number;
  v_lastcounter number;
begin
  v_TransactionId := :TransactionId;
  v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  begin
  select GEN_TBL_TASKDEPENDENCYCC.nextval into v_counter from dual;
  
   insert into tbl_taskdependencycc(col_taskdpchldcctaskstinitcc,col_taskdpprntcctaskstinitcc,col_type,col_processorcode,col_taskdependencyorder,col_isdefault,
                                           col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
   (select tsic2.col_id, tsip2.col_id, td.col_type, td.col_processorcode, td.col_taskdependencyorder, td.col_isdefault,
                                           td.col_createdby,td.col_createddate,td.col_modifiedby,td.col_modifieddate,td.col_owner
    from tbl_taskdependencytmpl td
    inner join tbl_map_taskstateinittmpl tsic on td.col_taskdpchldtptaskstinittp = tsic.col_id
    inner join tbl_taskcc tskc on tsic.col_map_taskstinittpltasktpl = tskc.col_id2
    inner join tbl_map_taskstateinitcc tsic2 on tskc.col_id = tsic2.col_map_taskstateinitcctaskcc and tsic.col_map_tskstinittpl_tskst = tsic2.col_map_tskstinitcc_tskst
    inner join tbl_map_taskstateinittmpl tsip on td.col_taskdpprnttptaskstinittp = tsip.col_id
    inner join tbl_taskcc tskp on tsip.col_map_taskstinittpltasktpl = tskp.col_id2
    inner join tbl_map_taskstateinitcc tsip2 on tskp.col_id = tsip2.col_map_taskstateinitcctaskcc and tsip.col_map_tskstinittpl_tskst = tsip2.col_map_tskstinitcc_tskst
    where tskc.col_transactionid = v_TransactionId and tskp.col_transactionid = v_TransactionId
   );
   
   select GEN_TBL_TASKDEPENDENCYCC.currval into v_lastcounter from dual;

  for rec in (select col_id from tbl_taskdependencycc where col_id between v_counter and v_lastcounter)
  loop
    update tbl_taskdependencycc set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
   
   exception
     when DUP_VAL_ON_INDEX then
       return -1;
     when OTHERS then
       return -1;
  end;
end;