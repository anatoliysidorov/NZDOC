declare
  v_TaskId Integer;
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
  v_counter number;
  v_lastcounter number;
begin
  v_TaskId := :TaskId;
  v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  select gen_tbl_autoruleparamcc.nextval into v_counter from dual;
  begin
    insert into tbl_autoruleparamcc(col_ruleparcc_taskstateinitcc,col_taskeventccautoruleparmcc,col_paramcode,col_paramvalue,col_tasktemplateautoruleparcc,col_autoruleparamcctaskcc,
                                    col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
     select s1.RTTaskStateInitId, s1.RTTaskEventId, s1.RuleParamCode, s1.RuleParamValue, s1.RuleParamTaskTmplId, s1.RTTaskId,
            v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
     from
    (select tsi.col_id as DTTaskStateInitId, tsi.col_processorcode as TaskStateInitProcessorCode, tsi.col_map_taskstateinitcctaskcc as TaskStateInitTaskId,
             tsi.col_map_tskstinitcc_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinitcc_tskst as TaskStateInitStateId,
             tsi.col_map_taskstinitcctasktmpl as TaskTmplId,
             tsi2.col_id as RTTaskStateInitId, tsi2.col_map_taskstateinitcctaskcc as TaskId, null as RTTaskId,
             arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
             arp.col_ruleparcc_taskstateinitcc as RuleParamTaskStateInitId, arp.col_taskeventccautoruleparmcc as RuleParamTaskEventId, arp.col_tasktemplateautoruleparcc as RuleParamTaskTmplId,
             null as TaskEventId, null as TaskEventProcessorCode,
             null as RTTaskEventId, null as RTTaskEventProcCode
     from tbl_autoruleparamcc arp
     inner join tbl_map_taskstateinitcc tsi on arp.col_ruleparcc_taskstateinitcc = tsi.col_id and tsi.col_taskstateinitcc_tasktype = (select col_taskccdict_tasksystype from tbl_taskcc where col_id = v_TaskId)
     inner join tbl_map_taskstateinitcc tsi2 on tsi.col_map_tskstinitcc_tskst = tsi2.col_map_tskstinitcc_tskst
     where tsi2.col_map_taskstateinitcctaskcc = v_TaskId) s1;
      exception
       when DUP_VAL_ON_INDEX then
         return -1;
       when OTHERS then
         return -1;
  end;
  begin
    insert into tbl_autoruleparamcc(col_ruleparcc_taskstateinitcc,col_taskeventccautoruleparmcc,col_paramcode,col_paramvalue,col_tasktemplateautoruleparcc,col_autoruleparamcctaskcc,
                                    col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      select s1.RTTaskStateInitId, s1.RTTaskEventId, s1.RuleParamCode, s1.RuleParamValue, s1.RuleParamTaskTmplId, s1.RTTaskId,
            v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
      from
      (
      select tsi.col_id as DTTaskStateInitId, tsi.col_processorCode as TaskStateInitProcessorCode, tsi.col_map_taskstateinitcctaskcc as TaskStateInitTaskId,
             tsi.col_map_tskstinitcc_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinitcc_tskst as TaskStateInitStateId,
             tsi.col_map_taskstinitcctasktmpl as TaskTmplId,
             null as RTTaskStateInitId, tsi2.col_map_taskstateinitcctaskcc as TaskId, null as RTTaskId,
             arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
             arp.col_ruleparcc_taskstateinitcc as RuleParamTaskStateInitId, arp.col_taskeventccautoruleparmcc as RuleParamTaskEventId, arp.col_tasktemplateautoruleparcc as RuleParamTaskTmplId,
             te.col_id as TaskEventId, te.col_processorcode as TaskEventProcessorCode,
             te2.col_id as RTTaskEventId, te2.col_processorcode as RTTaskEventProcCode
        from tbl_autoruleparamcc arp
        inner join tbl_taskeventcc te on arp.col_taskeventccautoruleparmcc = te.col_id
        --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitcc tsi on te.col_taskeventcctaskstinitcc = tsi.col_id
        inner join tbl_dict_tasksystype tst on tsi.col_taskstateinitcc_tasktype = tst.col_id
        --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitcc tsi2 on tsi2.col_map_taskstateinitcctaskcc = v_TaskId and tsi.col_map_tskstinitcc_tskst = tsi2.col_map_tskstinitcc_tskst
        inner join tbl_taskeventcc te2 on tsi2.col_id = te2.col_taskeventcctaskstinitcc
        where tst.col_id = (select col_taskccdict_tasksystype from tbl_taskcc where col_id = v_TaskId)) s1;
  end;
  select gen_tbl_autoruleparamcc.currval into v_lastcounter from dual;
  for rec in (select col_id from tbl_autoruleparamcc where col_id between v_counter and v_lastcounter)
  loop
    update tbl_autoruleparamcc set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
end;
