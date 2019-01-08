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
  select gen_tbl_taskdependency.nextval into v_counter from dual;
  
   /*
   insert into tbl_taskdependency(col_tskdpndchldtskstateinit,col_tskdpndprnttskstateinit,col_type,col_processorcode,col_taskdependencyorder,col_isdefault,
                                           col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
   (select tsic2.col_id, tsip2.col_id, td.col_type, td.col_processorcode, col_taskdependencyorder, col_isdefault, v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
    from tbl_taskdependencytmpl td
    inner join tbl_map_taskstateinittmpl tsic on td.COL_TASKDPCHLDTPTASKSTINITTP = tsic.col_id
    inner join tbl_task tskc on tsic.col_MAP_TaskStInitTplTaskTpl = tskc.col_id2
    inner join tbl_map_taskstateinitiation tsic2 on tskc.col_id = tsic2.col_map_taskstateinittask and tsic.col_MAP_TskStInitTpl_TskSt = tsic2.col_map_tskstinit_tskst
    inner join tbl_map_taskstateinittmpl tsip on td.COL_TaskDpPrntTpTaskStInitTp = tsip.col_id
    inner join tbl_task tskp on tsip.col_MAP_TaskStInitTplTaskTpl = tskp.col_id2
    inner join tbl_map_taskstateinitiation tsip2 on tskp.col_id = tsip2.col_map_taskstateinittask and tsip.col_MAP_TskStInitTpl_TskSt = tsip2.col_map_tskstinit_tskst
    where tskc.col_transactionid = v_TransactionId and tskp.col_transactionid = v_TransactionId
   );
   */
   
   for rec in(select tsic2.col_id as TsicId, tsip2.col_id as TsipId, td.col_id as TaskDepTmplId, td.col_type, td.col_processorcode, col_taskdependencyorder, col_isdefault
    from tbl_taskdependencytmpl td
    inner join tbl_map_taskstateinittmpl tsic on td.COL_TASKDPCHLDTPTASKSTINITTP = tsic.col_id
    inner join tbl_task tskc on tsic.col_MAP_TaskStInitTplTaskTpl = tskc.col_id2
    inner join tbl_map_taskstateinitiation tsic2 on tskc.col_id = tsic2.col_map_taskstateinittask and tsic.col_MAP_TskStInitTpl_TskSt = tsic2.col_map_tskstinit_tskst
    inner join tbl_map_taskstateinittmpl tsip on td.COL_TaskDpPrntTpTaskStInitTp = tsip.col_id
    inner join tbl_task tskp on tsip.col_MAP_TaskStInitTplTaskTpl = tskp.col_id2
    inner join tbl_map_taskstateinitiation tsip2 on tskp.col_id = tsip2.col_map_taskstateinittask and tsip.col_MAP_TskStInitTpl_TskSt = tsip2.col_map_tskstinit_tskst
    where tskc.col_transactionid = v_TransactionId and tskp.col_transactionid = v_TransactionId)
   loop
     insert into tbl_taskdependency(col_tskdpndchldtskstateinit,col_tskdpndprnttskstateinit,col_type,col_processorcode,col_taskdependencyorder,col_isdefault,
                                    col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
     values(rec.TsicId,rec.TsipId,rec.col_type,rec.col_processorcode,rec.col_taskdependencyorder,rec.col_isdefault,
            v_createdby,v_createddate,v_modifiedby,v_modifieddate,v_owner);
     select gen_tbl_taskdependency.currval into v_lastcounter from dual;
     insert into tbl_AutoRuleParameter(col_code, col_autoruleparamtaskdep, col_paramcode, col_paramvalue)
     (select sys_guid(), v_lastcounter, col_paramcode, col_paramvalue from tbl_autoruleparamtmpl
     where col_autoruleparamtptaskdeptp = rec.TaskDepTmplId);
   end loop;
   
   select gen_tbl_taskdependency.currval into v_lastcounter from dual;

  for rec in (select col_id from tbl_taskdependency  where col_id between v_counter and v_lastcounter)
  loop
    update tbl_taskdependency  set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
   
   exception
     when DUP_VAL_ON_INDEX then
       return -1;
     when OTHERS then
       return -1;
  end;
end;