declare
    v_TaskId Integer;
    v_createdby nvarchar2(255);
    v_createddate date;
    v_modifiedby nvarchar2(255);
    v_modifieddate date;
    v_owner nvarchar2(255);
    v_counter number;
    v_lastcounter number;
    v_TaskTemplateId number;
begin
    v_TaskId := :TaskId;
    v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
    v_createdby := v_owner;
    v_createddate := sysdate;
    v_modifiedby := v_createdby;
    v_modifieddate := v_createddate;
    v_TaskTemplateId := NULL;
    BEGIN
        SELECT COL_ID2
        INTO
               v_TaskTemplateId
        FROM   TBL_TASK
        WHERE  COL_ID = v_TaskId;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_TaskTemplateId := null;
    END;
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
                      col_owner)
        select s1.RTTaskStateInitId,
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
        from  (select    tsi.col_id as DTTaskStateInitId,
                          tsi.col_processorcode as TaskStateInitProcessorCode,
                          tsi.col_MAP_TaskStInitTplTaskTpl as TaskStateInitTaskId,
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
               inner join tbl_map_taskstateinittmpl tsi on arp.col_RuleParTp_TaskStateInitTp = tsi.col_id and tsi.col_TaskStateInitTp_TaskType =(select col_taskdict_tasksystype
                          from    tbl_task
                          where   col_id = v_TaskId)
               inner join tbl_map_taskstateinittmpl tsi2 on tsi.col_MAP_TskStInitTpl_TskSt = tsi2.col_MAP_TskStInitTpl_TskSt
               where      tsi2.col_MAP_TaskStInitTplTaskTpl = v_TaskTemplateId) s1;
    
    exception
    when DUP_VAL_ON_INDEX then
        return -1;
    when OTHERS then
        return -1;
    end;
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
                      col_owner)
        select s1.RTTaskStateInitId,
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
        from  (select    tsi.col_id as DTTaskStateInitId,
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
               inner join tbl_dict_tasksystype tst      on tsi.col_TaskStateInitTp_TaskType = tst.col_id
                          --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
               inner join tbl_map_taskstateinittmpl tsi2 on tsi2.col_MAP_TaskStInitTplTaskTpl = v_TaskTemplateId and tsi.col_MAP_TskStInitTpl_TskSt = tsi2.col_MAP_TskStInitTpl_TskSt
               inner join tbl_taskeventtmpl te2          on tsi2.col_id = te2.col_taskeventtptaskstinittp
               where      tst.col_id =(select col_taskdict_tasksystype
                          from    tbl_task
                          where   col_id = v_TaskId)) s1;
    
    end;
    select gen_tbl_autoruleparameter.currval
    into
           v_lastcounter
    from   dual;
    
    for rec in(select col_id
    from    tbl_autoruleparameter
    where   col_id between v_counter and v_lastcounter)
    loop
        update tbl_autoruleparameter
        set    col_code = sys_guid()
        where  col_id = rec.col_id;
    
    end loop;
end;