declare
  v_RootCaseId Integer;
  v_RootTaskId Integer;
  v_TaskId Integer;
  v_CreatedBy nvarchar2(255);
  v_CreatedDate date;
  v_SessionId nvarchar2(255);
  v_TaskPrefix nvarchar2(255);
  v_TaskIcon nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_stateNew nvarchar2(255);
  v_stateStarted nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateResolved nvarchar2(255);
  v_TokenDomain nvarchar2(255);
  v_workflow nvarchar2(255);
  v_activity nvarchar2(255);
  v_activitycode nvarchar2(255);
  v_workflowcode nvarchar2(255);
  v_ErrorMessage nvarchar2(255);
  v_ErrorCode number;
  v_affectedRows number;
  v_GenTaskId nvarchar2(255);
  v_Recordid Integer;
  v_Result number;
  v_ProcessorCode nvarchar2(255);
  v_owner nvarchar2(255);
  v_ProcedureId Integer;
  v_counter number;
  v_lastcounter number;
   v_counter1 number;
  v_lastcounter1 number;
  
   v_counter2 number;
  v_lastcounter2 number;
begin
  v_RootTaskId := :TaskId;
  v_CreatedBy := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_CreatedDate := sysdate;
  v_owner := v_CreatedBy;
  v_SessionId := sys_guid();
  v_TaskPrefix := 'TASK-';
  v_TaskIcon := 'tick';
  v_ProcessorCode := null;
  v_ProcedureId := null;
  v_TokenDomain := f_UTIL_getDomainFn();
  v_workflow := f_DCM_getTaskWorkflowCodeFn();
  v_activity := f_dcm_getTaskNewState();
  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  v_stateResolved := f_dcm_getTaskResolvedState();
  v_stateClosed := f_dcm_getTaskClosedState();

  v_activitycode := v_activity;
  v_workflowcode := v_TokenDomain || '_' || v_workflow;

  begin
    select col_casetask into v_RootCaseId from tbl_task where col_id = v_RootTaskId;
	exception
	when NO_DATA_FOUND then
	  v_ErrorMessage := 'No record found';
  end;

  begin
    select col_id into v_ProcedureId from tbl_procedure where col_code in (select col_paramvalue from tbl_autoruleparameter where col_autoruleparametertask = v_RootTaskId and lower(col_paramcode) = 'procedurecode');
    exception
    when NO_DATA_FOUND then
      v_ErrorMessage := 'Procedure for injection not found';
      return -1;
  end;

  delete from tbl_dynamictask
    where col_casedynamictask = v_RootCaseId;

insert into tbl_dynamictask
                (col_id2,
                 col_sessionid,
                 col_createdby,
                 col_createddate,
                 col_modifiedby,
                 col_modifieddate,
                 col_owner,
                 col_type,
                 col_dynamictaskparentid,
                 col_deadline,
                 col_description,
                 col_goal,
                 col_name,
                 col_taskid,
                 col_urgency,
                 col_depth,
                 col_iconcls,
                 col_icon,
                 col_leaf,
                 col_taskorder,
                 col_required,
                 col_casedynamictask,
                 col_dynamictasktasksystype,
                 col_processorname,
                 col_dynamictaskexecmethod)
    select col_id,
           v_sessionid,
           v_CreatedBy,
           v_CreatedDate,
           v_CreatedBy,
           v_CreatedDate,
           v_owner,
           col_type,
           col_parentttid,
           col_deadline,
           col_description,
           col_goal,
           col_name,
           col_taskid,
           col_urgency,
           col_depth,
           col_iconcls,
           col_icon,
           col_leaf,
           col_taskorder,
           col_required,
           v_RootCaseId,
           col_tasktmpldict_tasksystype,
           col_processorcode,
           col_execmethodtasktemplate
    from   tbl_tasktemplate
    where  col_proceduretasktemplate = v_procedureid
    order  by col_depth,
              col_parentttid,
              col_id;

    update tbl_dynamictask tt1
    set    col_dynamictaskparentid = (select col_id
                           from   tbl_dynamictask tt2
                           where  tt2.col_id2 = tt1.col_dynamictaskparentid
                             and tt2.col_sessionid = v_SessionId)
    where  col_sessionid = v_SessionId;

    begin
     for rec in (
     select col_id, col_taskid from tbl_dynamictask where col_sessionid = v_SessionId)
     loop
       v_Result := f_DCM_genDynamicTaskId (affectedRows => v_affectedRows, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                          prefix => v_TaskPrefix, recordid => rec.col_id, taskid => v_GenTaskId);
       v_Result := f_TSKW_createDynamicWI (AccessSubjectCode => v_createdby, ActivityCode => v_activitycode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                   Owner => v_owner, TaskId => rec.col_Id, TOKEN_USERACCESSSUBJECT => SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'), WorkflowCode => v_workflowcode);
     end loop;
     exception
       when NO_DATA_FOUND then
         v_affectedRows := 0;
      when OTHERS then
        v_ErrorCode := 100;
        v_ErrorMessage := substr(sqlerrm, 1, 200);
   end;

   update tbl_dynamictask set col_dynamictaskparentid = 0 where col_sessionid = v_SessionId and col_dynamictaskparentid is null;

   select gen_tbl_slaevent.currval into v_lastcounter from dual;
   begin
    insert into tbl_slaevent(col_slaeventdynamictask, col_slaeventdict_slaeventtype, col_slaevent_dateeventtype, col_intervalds, col_intervalym, col_slaevent_slaeventlevel, col_maxattempts, col_attemptcount, col_slaeventorder)
    (select tsk.col_id, se.col_slaeventdict_slaeventtype, se.col_slaevent_dateeventtype, se.col_intervalds, se.col_intervalym, se.col_slaevent_slaeventlevel, se.col_maxattempts, se.col_attemptcount, se.col_slaeventorder
       from tbl_slaevent se
         inner join tbl_dynamictask tsk on se.col_slaeventtasktemplate = tsk.col_id2
         where tsk.col_sessionid = v_SessionId);
     exception
       when DUP_VAL_ON_INDEX then
         v_affectedRows := 0;
       when OTHERS then
         v_affectedRows := 0;
   end;
   select gen_tbl_slaevent.currval into v_lastcounter from dual;
   for rec in (select col_id from tbl_slaevent where col_id between v_counter and v_lastcounter)
   loop
     update tbl_slaevent set col_code = sys_guid() where col_id = rec.col_id;
   end loop;

   select gen_tbl_slaaction.nextval into v_counter from dual;
   begin
    insert into tbl_slaaction(col_code, col_name, col_processorcode, col_slaactionslaevent, col_slaaction_slaeventlevel, col_actionorder)
    (select null, sa.col_name, sa.col_processorcode, se2.col_id, sa.col_slaaction_slaeventlevel, sa.col_actionorder
       from tbl_slaevent se
         inner join tbl_dynamictask tsk on se.col_slaeventtasktemplate = tsk.col_id2
         inner join tbl_slaevent se2 on tsk.col_id = se2.col_slaeventdynamictask
         inner join tbl_slaaction sa on se.col_id = sa.col_slaactionslaevent
         where tsk.col_sessionid = v_SessionId);
     exception
       when DUP_VAL_ON_INDEX then
         v_affectedRows := 0;
       when OTHERS then
         v_affectedRows := 0;
   end;
   select gen_tbl_slaaction.currval into v_lastcounter from dual;
   for rec in (select col_id from tbl_slaaction where col_id between v_counter and v_lastcounter)
   loop
     update tbl_slaaction set col_code = sys_guid() where col_id = rec.col_id;
   end loop;

   select gen_tbl_map_taskstateinitiat.nextval into v_counter from dual;
   begin
     insert into tbl_map_taskstateinitiation(col_taskstateinitdynamictask,col_processorcode,col_map_tskstinit_initmtd,col_map_tskstinit_tskst,
                                            col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
     (select tsk.col_id, col_processorcode, col_map_tskstinit_initmtd, col_map_tskstinit_tskst, v_createdby, v_createddate, v_createdby, v_createddate, v_owner
       from tbl_map_taskstateinitiation tsi
       inner join tbl_dynamictask tsk on tsi.col_map_taskstateinittasktmpl = tsk.col_id2
       where tsk.col_sessionid = v_SessionId);
     exception
       when DUP_VAL_ON_INDEX then
         v_affectedRows := 0;
       when OTHERS then
         v_affectedRows := 0;
   end;
   select gen_tbl_map_taskstateinitiat.currval into v_lastcounter from dual;
   for rec in (select col_id from tbl_map_taskstateinitiation where col_id between v_counter and v_lastcounter)
   loop
     update tbl_map_taskstateinitiation set col_code = sys_guid() where col_id = rec.col_id;
   end loop;

   begin
   	select GEN_TBL_TASKDEPENDENCY.nextval into v_counter2 from dual;
   
     insert into tbl_taskdependency(col_tskdpndchldtskstateinit,col_tskdpndprnttskstateinit,col_type,col_processorcode,
                                             col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
     (select tsic2.col_id, tsip2.col_id, td.col_type, td.col_processorcode, v_createdby, v_createddate, v_createdby, v_createddate, v_owner
      from tbl_taskdependency td
      inner join tbl_map_taskstateinitiation tsic on td.col_tskdpndchldtskstateinit = tsic.col_id
      inner join tbl_dynamictask tskc on tsic.col_map_taskstateinittasktmpl = tskc.col_id2
      inner join tbl_map_taskstateinitiation tsic2 on tskc.col_id = tsic2.col_taskstateinitdynamictask and tsic.col_map_tskstinit_tskst = tsic2.col_map_tskstinit_tskst
      inner join tbl_map_taskstateinitiation tsip on td.col_tskdpndprnttskstateinit = tsip.col_id
      inner join tbl_dynamictask tskp on tsip.col_map_taskstateinittasktmpl = tskp.col_id2
      inner join tbl_map_taskstateinitiation tsip2 on tskp.col_id = tsip2.col_taskstateinitdynamictask and tsip.col_map_tskstinit_tskst = tsip2.col_map_tskstinit_tskst
      where tskc.col_sessionid = v_SessionId and tskp.col_sessionid = v_SessionId
     );
     
     select GEN_TBL_TASKDEPENDENCY.currval into v_lastcounter2 from dual;

      for rec in (select col_id from tbl_taskdependency where col_id between v_counter2 and v_lastcounter2)
      loop
        update tbl_taskdependency set col_code = sys_guid() where col_id = rec.col_id;
      end loop;
  
     
     exception
       when DUP_VAL_ON_INDEX then
         v_affectedRows := 0;
       when OTHERS then
         v_affectedRows := 0;
   end;

   begin
   	select GEN_TBL_TASKEVENT.nextval into v_counter1 from dual;
     insert into tbl_taskevent(col_processorcode,col_taskeventtaskstateinit,col_taskeventmomenttaskevent,col_taskeventtypetaskevent,col_taskeventorder,
                            col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
       (select te.col_processorcode,tsi2.col_id,te.col_taskeventmomenttaskevent,te.col_taskeventtypetaskevent,te.col_taskeventorder,
        v_createdby, v_createddate, v_createdby, v_createddate, v_owner
        from tbl_taskevent te
        --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi on te.col_taskeventtaskstateinit = tsi.col_id
        inner join tbl_dynamictask tsk on tsi.col_map_taskstateinittasktmpl = tsk.col_id2
        --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_taskstateinitdynamictask and tsi.col_map_tskstinit_tskst = tsi2.col_map_tskstinit_tskst
        where tsk.col_sessionid = v_SessionId);
        
      select GEN_TBL_TASKEVENT.currval into v_lastcounter1 from dual;

      for rec in (select col_id from tbl_taskevent where col_id between v_counter1 and v_lastcounter1)
      loop
        update tbl_taskevent set col_code = sys_guid() where col_id = rec.col_id;
      end loop;
     exception
       when DUP_VAL_ON_INDEX then
         v_affectedRows := 0;
       when OTHERS then
         v_affectedRows := 0;
   end;

   select gen_tbl_autoruleparameter.nextval into v_counter from dual;
   begin
    insert into tbl_autoruleparameter(col_ruleparam_taskstateinit,col_taskeventautoruleparam,col_paramcode,col_paramvalue,col_ttautoruleparameter,col_autoruleparamdynamictask,
                                      col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
    (select s1.RTTaskStateInitId, s1.RTTaskEventId, s1.RuleParamCode, s1.RuleParamValue, s1.RuleParamTaskTmplId, s1.RTTaskId,
            v_createdby, v_createddate, v_createdby, v_createddate, v_owner
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
        inner join tbl_dynamictask tsk on tsi.col_map_taskstateinittasktmpl = tsk.col_id2
        --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_taskstateinitdynamictask and tsi.col_map_tskstinit_tskst = tsi2.col_map_tskstinit_tskst
        where tsk.col_sessionid = v_SessionId
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
        inner join tbl_dynamictask tsk on tsi.col_map_taskstateinittasktmpl = tsk.col_id2
        --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_taskstateinitdynamictask and tsi.col_map_tskstinit_tskst = tsi2.col_map_tskstinit_tskst
        inner join tbl_taskevent te2 on tsi2.col_id = te2.col_taskeventtaskstateinit
        where tsk.col_sessionid = v_SessionId
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
          inner join tbl_dynamictask tsk on tskt.col_id = tsk.col_id2
          where tsk.col_sessionid = v_SessionId
      )s1);
      exception
       when DUP_VAL_ON_INDEX then
         v_affectedRows := 0;
       when OTHERS then
         v_affectedRows := 0;
   end;
   select gen_tbl_autoruleparameter.currval into v_lastcounter from dual;
   for rec in (select col_id from tbl_autoruleparameter where col_id between v_counter and v_lastcounter)
   loop
     update tbl_autoruleparameter set col_code = sys_guid() where col_id = rec.col_id;
   end loop;

   :SessionId := v_SessionId;

end;