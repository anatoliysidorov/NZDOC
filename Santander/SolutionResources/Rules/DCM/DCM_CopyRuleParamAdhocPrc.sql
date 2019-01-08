declare
  v_StartTaskId Integer;
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
  v_counter number;
  v_lastcounter number;
begin
  v_StartTaskId := :StartTaskId;
  v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  select gen_tbl_autoruleparameter.nextval into v_counter from dual;
  begin
    insert into tbl_autoruleparameter(col_ruleparam_taskstateinit,col_taskeventautoruleparam,col_paramcode,col_paramvalue,col_ttautoruleparameter,col_autoruleparametertask,
                                      col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
    (select s1.RTTaskStateInitId, s1.RTTaskEventId, s1.RuleParamCode, s1.RuleParamValue, s1.RuleParamTaskTmplId, s1.RTTaskId,
            v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
      from
      (
      --SELECT AUTORULEPARAMETER RECORDS FOR COPYING FROM DESIGN TIME TO RUNTIME
      --SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION
      select tsi.col_id as DTTaskStateInitId, tsi.col_processorcode as TaskStateInitProcessorCode, tsi.col_map_taskstateinittask as TaskStateInitTaskId,
             tsi.col_map_tskstinit_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinit_tskst as TaskStateInitStateId,
             tsi.col_map_taskstateinittasktmpl as TaskTmplId,
             tsi2.col_id as RTTaskStateInitId, tsi2.col_map_taskstateinittask as TaskId, null as RTTaskId,
             arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
             arp.col_ruleparam_taskstateinit as RuleParamTaskStateInitId, arp.col_taskeventautoruleparam as RuleParamTaskEventId, arp.col_ttautoruleparameter as RuleParamTaskTmplId,
             null as TaskEventId, null as TaskEventProcessorCode,
             null as RTTaskEventId, null as RTTaskEventProcCode
        from tbl_autoruleparameter arp
        --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi on arp.col_ruleparam_taskstateinit = tsi.col_id
        inner join tbl_task tsk on tsi.col_map_taskstateinittasktmpl = tsk.col_id2
        --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinit_tskst = tsi2.col_map_tskstinit_tskst
        where tsk.col_id > v_StartTaskId
      union
      --SELECT ALL RULEPARAMETERS FOR EVENTS, RELATED TO TASK STATE INITIATION EVENTS
      select tsi.col_id as DTTaskStateInitId, tsi.col_processorCode as TaskStateInitProcessorCode, tsi.col_map_taskstateinittask as TaskStateInitTaskId,
             tsi.col_map_tskstinit_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinit_tskst as TaskStateInitStateId,
             tsi.col_map_taskstateinittasktmpl as TaskTmplId,
             null as RTTaskStateInitId, tsi2.col_map_taskstateinittask as TaskId, null as RTTaskId,
             arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
             arp.col_ruleparam_taskstateinit as RuleParamTaskStateInitId, arp.col_taskeventautoruleparam as RuleParamTaskEventId, arp.col_ttautoruleparameter as RuleParamTaskTmplId,
             te.col_id as TaskEventId, te.col_processorcode as TaskEventProcessorCode,
             te2.col_id as RTTaskEventId, te2.col_processorcode as RTTaskEventProcCode
        from tbl_autoruleparameter arp
        inner join tbl_taskevent te on arp.col_taskeventautoruleparam = te.col_id
        --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi on te.col_taskeventtaskstateinit = tsi.col_id
        inner join tbl_task tsk on tsi.col_map_taskstateinittasktmpl = tsk.col_id2
        --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinit_tskst = tsi2.col_map_tskstinit_tskst
        inner join tbl_taskevent te2 on tsi2.col_id = te2.col_taskeventtaskstateinit
        where tsk.col_id > v_StartTaskId
      union
      --SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS
      select null as DTTaskStateInitId, cast(tsk.col_processorName as nvarchar2(255)) as TaskStateInitProcessorCode, null as TaskStateInitTaskId,
             null as TaskStateInitMethodId, null as TaskStateInitStateId,
             tskt.col_Id as TaskTmplId,
             null as RTTaskStateInitId, tsk.col_id as TaskId, tsk.col_id as RTTaskId,
             arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
             arp.col_ruleparam_taskstateinit as RuleParamTaskStateInitId, arp.col_taskeventautoruleparam as RuleParamTaskEventId, null as RuleParamTaskTmplId,
             null as TaskEventId, null as TaskEventProcessorCode,
             null as RTTaskEventId, null as RTTaskEventProcCode
        from tbl_autoruleparameter arp
          inner join tbl_tasktemplate tskt on arp.col_ttautoruleparameter = tskt.col_id
          inner join tbl_task tsk on tskt.col_id = tsk.col_id2
          where tsk.col_id > v_StartTaskId
      )s1);
      exception
       when DUP_VAL_ON_INDEX then
         return -1;
       when OTHERS then
         return -1;
  end;
  begin
    insert into tbl_autoruleparameter(col_autoruleparamtaskdep, col_paramcode,col_paramvalue,
                                      col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
     select s1.RTTaskDependencyId, s1.RuleParamCode, s1.RuleParamValue,
                                      v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
     from
     (select td.col_id as DTTaskDependencyId, td2.col_id as RTTaskDependencyId,
             ctsi.col_id as CDTTaskStateInitId, ctsi.col_processorcode as CTaskStateInitProcessorCode, ctsi.col_map_taskstateinittask as CTaskStateInitTaskId,
             ctsi.col_map_tskstinit_initmtd as CTaskStateInitMethodId, ctsi.col_map_tskstinit_tskst as CTaskStateInitStateId,
             ctsi.col_map_taskstateinittasktmpl as CTaskTmplId,
             ctsi2.col_id as CRTTaskStateInitId, ctsi2.col_map_taskstateinittask as CTaskId,
             ptsi.col_id as PDTTaskStateInitId, ptsi.col_processorcode as PTaskStateInitProcessorCode, ptsi.col_map_taskstateinittask as PTaskStateInitTaskId,
             ptsi.col_map_tskstinit_initmtd as PTaskStateInitMethodId, ptsi.col_map_tskstinit_tskst as PTaskStateInitStateId,
             ptsi.col_map_taskstateinittasktmpl as PTaskTmplId,
             ptsi2.col_id as PRTTaskStateInitId, ptsi2.col_map_taskstateinittask as PTaskId,
             arp.col_id as ARPId, arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
             arp.col_ruleparam_taskstateinit as RuleParamTaskStateInitId, arp.col_taskeventautoruleparam as RuleParamTaskEventId,
             arp.col_ttautoruleparameter as RuleParamTaskTmplId
      from tbl_autoruleparameter arp
      inner join tbl_taskdependency td on arp.col_autoruleparamtaskdep = td.col_id
      inner join tbl_map_taskstateinitiation ctsi on td.col_tskdpndchldtskstateinit = ctsi.col_id
      inner join tbl_task ctsk on ctsi.col_map_taskstateinittasktmpl = ctsk.col_id2
      inner join tbl_map_taskstateinitiation ptsi on td.col_tskdpndprnttskstateinit = ptsi.col_id
      inner join tbl_task ptsk on ptsi.col_map_taskstateinittasktmpl = ptsk.col_id2
      --RUNTIME
      inner join tbl_map_taskstateinitiation ctsi2 on ctsk.col_id = ctsi2.col_map_taskstateinittask and ctsi.col_map_tskstinit_tskst = ctsi2.col_map_tskstinit_tskst
      inner join tbl_map_taskstateinitiation ptsi2 on ptsk.col_id = ptsi2.col_map_taskstateinittask and ptsi.col_map_tskstinit_tskst = ptsi2.col_map_tskstinit_tskst
      inner join tbl_taskdependency td2 on ctsi2.col_id = td2.col_tskdpndchldtskstateinit and ptsi2.col_id = td2.col_tskdpndprnttskstateinit
      where ctsk.col_id > v_StartTaskId and ptsk.col_id > v_StartTaskId) s1;
      exception
       when DUP_VAL_ON_INDEX then
         return -1;
       when OTHERS then
         return -1;
  end;
  select gen_tbl_autoruleparameter.currval into v_lastcounter from dual;
  for rec in (select col_id from tbl_autoruleparameter where col_id between v_counter and v_lastcounter)
  loop
    update tbl_autoruleparameter set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
end;