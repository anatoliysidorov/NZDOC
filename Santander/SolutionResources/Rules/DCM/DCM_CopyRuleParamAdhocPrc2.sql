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
    select gen_tbl_autoruleparameter.nextval
    into
           v_counter
    from   dual;
    
    begin
        insert into tbl_autoruleparameter(col_ruleparam_taskstateinit,
                      col_taskeventautoruleparam,
                      col_paramcode,
                      col_paramvalue,
                      col_ttautoruleparameter,
                      col_autoruleparametertask,
                      col_createdby,
                      col_createddate,
                      col_modifiedby,
                      col_modifieddate,
                      col_owner)(select s1.RTTaskStateInitId,
                       s1.RTTaskEventId,
                       s1.RuleParamCode,
                       s1.RuleParamValue,
                       s1.RuleParamTaskTmplId,
                       s1.RTTaskId,
                       v_createdby,
                       v_createddate,
                       v_modifiedby,
                       v_modifieddate,
                       v_owner
               from   (
                       --SELECT AUTORULEPARAMETER RECORDS FOR COPYING FROM DESIGN TIME TO RUNTIME
                       --SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION
                       select     tsi.col_id as DTTaskStateInitId,
                                  tsi.col_processorcode as TaskStateInitProcessorCode,
                                  tsi.col_map_TaskStInitTplTaskTpl as TaskStateInitTaskId,
                                  tsi.col_map_tskstinittpl_initmtd as TaskStateInitMethodId,
                                  tsi.col_MAP_TskStInitTpl_TskSt as TaskStateInitStateId,
                                  tsi.col_MAP_TaskStInitTplTaskTpl as TaskTmplId,
                                  tsi2.col_id as RTTaskStateInitId,
                                  tsi2.col_MAP_TaskStInitTplTaskTpl as TaskId,
                                  null as RTTaskId,
                                  arp.col_id as AutoRuleParamId,
                                  arp.col_paramcode as RuleParamCode,
                                  arp.col_paramvalue as RuleParamValue,
                                  arp.col_RuleParTp_TaskStateInitTp as RuleParamTaskStateInitId,
                                  arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId,
                                  arp.col_TaskTemplateAutoRuleParTp as RuleParamTaskTmplId,
                                  null as TaskEventId,
                                  null as TaskEventProcessorCode,
                                  null as RTTaskEventId,
                                  null as RTTaskEventProcCode
                       from       tbl_autoruleparamtmpl arp
                                  --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
                       inner join tbl_map_taskstateinittmpl tsi on arp.col_RuleParTp_TaskStateInitTp = tsi.col_id
                       inner join tbl_task tsk                  on tsi.col_MAP_TaskStInitTplTaskTpl = tsk.col_id2
                                  --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
                       inner join tbl_map_taskstateinittmpl tsi2 on tsk.col_id2 = tsi2.col_MAP_TaskStInitTplTaskTpl and tsi.col_MAP_TskStInitTpl_TskSt = tsi2.col_MAP_TskStInitTpl_TskSt
                       where      tsk.col_transactionid = v_TransactionId
                       union
                       --SELECT ALL RULEPARAMETERS FOR EVENTS, RELATED TO TASK STATE INITIATION EVENTS
                       select     tsi.col_id as DTTaskStateInitId,
                                  tsi.col_processorCode as TaskStateInitProcessorCode,
                                  tsi.col_MAP_TaskStInitTplTaskTpl as TaskStateInitTaskId,
                                  tsi.col_map_tskstinittpl_initmtd as TaskStateInitMethodId,
                                  tsi.col_MAP_TskStInitTpl_TskSt as TaskStateInitStateId,
                                  tsi.col_MAP_TaskStInitTplTaskTpl as TaskTmplId,
                                  null as RTTaskStateInitId,
                                  tsi2.col_MAP_TaskStInitTplTaskTpl as TaskId,
                                  null as RTTaskId,
                                  arp.col_id as AutoRuleParamId,
                                  arp.col_paramcode as RuleParamCode,
                                  arp.col_paramvalue as RuleParamValue,
                                  arp.col_RuleParTp_TaskStateInitTp as RuleParamTaskStateInitId,
                                  arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId,
                                  arp.col_TaskTemplateAutoRuleParTp as RuleParamTaskTmplId,
                                  te.col_id as TaskEventId,
                                  te.col_processorcode as TaskEventProcessorCode,
                                  te2.col_id as RTTaskEventId,
                                  te2.col_processorcode as RTTaskEventProcCode
                       from       tbl_autoruleparamtmpl arp
                       inner join tbl_taskeventtmpl te on arp.col_taskeventtpautoruleparmtp = te.col_id
                                  --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
                       inner join tbl_map_taskstateinittmpl tsi on te.col_taskeventtptaskstinittp = tsi.col_id
                       inner join tbl_task tsk                  on tsi.col_MAP_TaskStInitTplTaskTpl = tsk.col_id2
                                  --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
                       inner join tbl_map_taskstateinittmpl tsi2 on tsk.col_id2 = tsi2.col_MAP_TaskStInitTplTaskTpl and tsi.col_MAP_TskStInitTpl_TskSt = tsi2.col_MAP_TskStInitTpl_TskSt
                       inner join tbl_taskeventtmpl te2          on tsi2.col_id = te2.col_TaskEventTpTaskStInitTp
                       where      tsk.col_transactionid = v_TransactionId
                       union
                       --SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS
                       select     null as DTTaskStateInitId,
                                  cast(tsk.col_processorName as nvarchar2(255)) as TaskStateInitProcessorCode,
                                  null as TaskStateInitTaskId,
                                  null as TaskStateInitMethodId,
                                  null as TaskStateInitStateId,
                                  tskt.col_Id as TaskTmplId,
                                  null as RTTaskStateInitId,
                                  tsk.col_id as TaskId,
                                  tsk.col_id as RTTaskId,
                                  arp.col_id as AutoRuleParamId,
                                  arp.col_paramcode as RuleParamCode,
                                  arp.col_paramvalue as RuleParamValue,
                                  arp.col_RuleParTp_TaskStateInitTp as RuleParamTaskStateInitId,
                                  arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId,
                                  null as RuleParamTaskTmplId,
                                  null as TaskEventId,
                                  null as TaskEventProcessorCode,
                                  null as RTTaskEventId,
                                  null as RTTaskEventProcCode
                       from       tbl_autoruleparamtmpl arp
                       inner join tbl_tasktemplate tskt on arp.col_TaskTemplateAutoRuleParTp = tskt.col_id
                       inner join tbl_task tsk          on tskt.col_id = tsk.col_id2
                       where      tsk.col_transactionid = v_TransactionId) s1);
    
    exception
    when DUP_VAL_ON_INDEX then
        return -1;
    when OTHERS then
        return -1;
    end;
    begin
        insert into tbl_autoruleparameter(col_autoruleparamtaskdep,
                      col_paramcode,
                      col_paramvalue,
                      col_createdby,
                      col_createddate,
                      col_modifiedby,
                      col_modifieddate,
                      col_owner)
        select s1.RTTaskDependencyId,
               s1.RuleParamCode,
               s1.RuleParamValue,
               v_createdby,
               v_createddate,
               v_modifiedby,
               v_modifieddate,
               v_owner
        from  (select    td.col_id as DTTaskDependencyId,
                          td2.col_id as RTTaskDependencyId,
                          ctsi.col_id as CDTTaskStateInitId,
                          ctsi.col_processorcode as CTaskStateInitProcessorCode,
                          ctsi.col_MAP_TaskStInitTplTaskTpl as CTaskStateInitTaskId,
                          ctsi.col_map_tskstinittpl_initmtd as CTaskStateInitMethodId,
                          ctsi.col_MAP_TskStInitTpl_TskSt as CTaskStateInitStateId,
                          ctsi.col_MAP_TaskStInitTplTaskTpl as CTaskTmplId,
                          ctsi2.col_id as CRTTaskStateInitId,
                          ctsi2.col_MAP_TaskStInitTplTaskTpl as CTaskId,
                          ptsi.col_id as PDTTaskStateInitId,
                          ptsi.col_processorcode as PTaskStateInitProcessorCode,
                          ptsi.col_MAP_TaskStInitTplTaskTpl as PTaskStateInitTaskId,
                          ptsi.col_map_tskstinittpl_initmtd as PTaskStateInitMethodId,
                          ptsi.col_MAP_TskStInitTpl_TskSt as PTaskStateInitStateId,
                          ptsi.col_MAP_TaskStInitTplTaskTpl as PTaskTmplId,
                          ptsi2.col_id as PRTTaskStateInitId,
                          ptsi2.col_MAP_TaskStInitTplTaskTpl as PTaskId,
                          arp.col_id as ARPId,
                          arp.col_id as AutoRuleParamId,
                          arp.col_paramcode as RuleParamCode,
                          arp.col_paramvalue as RuleParamValue,
                          arp.col_RuleParTp_TaskStateInitTp as RuleParamTaskStateInitId,
                          arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId,
                          arp.col_TaskTemplateAutoRuleParTp as RuleParamTaskTmplId
               from       tbl_autoruleparamtmpl arp
               inner join tbl_taskdependencytmpl td      on arp.col_autoruleparamtptaskdeptp = td.col_id
               inner join tbl_map_taskstateinittmpl ctsi on td.COL_TASKDPCHLDTPTASKSTINITTP = ctsi.col_id
               inner join tbl_task ctsk                  on ctsi.col_MAP_TaskStInitTplTaskTpl = ctsk.col_id2
               inner join tbl_map_taskstateinittmpl ptsi on td.COL_TASKDPPRNTTPTASKSTINITTP = ptsi.col_id
               inner join tbl_task ptsk                  on ptsi.col_MAP_TaskStInitTplTaskTpl = ptsk.col_id2
                          --RUNTIME
               inner join tbl_map_taskstateinittmpl ctsi2 on ctsk.col_id = ctsi2.col_MAP_TaskStInitTplTaskTpl and ctsi.col_MAP_TskStInitTpl_TskSt = ctsi2.col_MAP_TskStInitTpl_TskSt
               inner join tbl_map_taskstateinittmpl ptsi2 on ptsk.col_id = ptsi2.col_MAP_TaskStInitTplTaskTpl and ptsi.col_MAP_TskStInitTpl_TskSt = ptsi2.col_MAP_TskStInitTpl_TskSt
               inner join tbl_taskdependencytmpl td2      on ctsi2.col_id = td2.COL_TASKDPCHLDTPTASKSTINITTP and ptsi2.col_id = td2.COL_TASKDPPRNTTPTASKSTINITTP
               where      ctsk.col_transactionid = v_TransactionId
                          and ptsk.col_transactionid = v_TransactionId) s1;
    
    exception
    when DUP_VAL_ON_INDEX then
        return -1;
    when OTHERS then
        return -1;
    end;
    select gen_tbl_autoruleparameter.currval
    into
           v_lastcounter
    from   dual;
    
    for rec in(select col_id
    from    tbl_autoruleparamtmpl
    where   col_id between v_counter and v_lastcounter)
    loop
        update tbl_autoruleparameter
        set    col_code = sys_guid()
        where  col_id = rec.col_id;
    
    end loop;
end;