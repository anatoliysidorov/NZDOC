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
  select GEN_tbl_taskevent.nextval into v_counter from dual;
  /*
  insert into tbl_taskevent(col_processorcode,col_taskeventtaskstateinit,col_taskeventmomenttaskevent,col_taskeventtypetaskevent,col_taskeventorder,
                            col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
  (select te.col_processorcode,tsi2.col_id,te.col_taskeventmomnttaskeventtp,te.col_taskeventtypetaskeventtp,te.col_taskeventorder,
          v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
    from tbl_taskeventtmpl te  

 --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
  inner join tbl_map_taskstateinittmpl tsi on te.col_TaskEventTpTaskStInitTp = tsi.col_id
  inner join tbl_task tsk on tsi.col_MAP_TaskStInitTplTaskTpl = tsk.col_id2
  --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
  inner join tbl_map_taskstateinittmpl tsi2 on tsk.col_id2 = tsi2.col_MAP_TaskStInitTplTaskTpl and tsi.col_MAP_TskStInitTpl_TskSt = tsi2.col_MAP_TskStInitTpl_TskSt
  where tsk.col_transactionid = v_TransactionId);
  */
  for rec in (select te.col_id as TaskEventTmplId,te.col_processorcode,tsi.col_id as TSITmplId,tsi2.col_id as TSIId,te.col_taskeventmomnttaskeventtp,te.col_taskeventtypetaskeventtp,te.col_taskeventorder
    from tbl_taskeventtmpl te
    --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
    inner join tbl_map_taskstateinittmpl tsi on te.col_TaskEventTpTaskStInitTp = tsi.col_id
    inner join tbl_task tsk on tsi.col_map_TaskStInitTplTaskTpl = tsk.col_id2
    --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
    inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinittpl_tskst = tsi2.col_map_tskstinit_tskst
    where tsk.col_transactionid = v_TransactionId)
    loop
      insert into tbl_taskevent(col_processorcode,col_taskeventtaskstateinit,col_taskeventmomenttaskevent,col_taskeventtypetaskevent,col_taskeventorder,
                            col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      values(rec.col_processorcode, rec.TSIId, rec.col_taskeventmomnttaskeventtp, rec.col_taskeventtypetaskeventtp, rec.col_taskeventorder,
             v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner);
      select gen_tbl_taskevent.currval into v_lastcounter from dual;
      insert into tbl_AutoRuleParameter(col_code, col_taskeventautoruleparam, col_paramcode, col_paramvalue)
      (select sys_guid(), v_lastcounter, col_paramcode, col_paramvalue from tbl_autoruleparamtmpl
      where col_taskeventtpautoruleparmtp = rec.TaskEventTmplId);
    end loop;
  
  select gen_tbl_taskevent.currval into v_lastcounter from dual;

  for rec in (select col_id from tbl_taskevent where col_id between v_counter and v_lastcounter)
  loop
    update tbl_taskevent set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
  
  exception
     when DUP_VAL_ON_INDEX then
       return -1;
     when OTHERS then
       return -1;
  end;
end;