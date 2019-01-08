declare
  v_CaseId Integer;
  v_maxorder Integer;
  v_SessionId nvarchar2(255);
  v_TaskId Integer;
  v_ParentId Integer;
  v_depth Integer;
  v_TaskOrder Integer;
  v_CurrTaskId Integer;
  v_affectedRows Integer;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_customTaskId nvarchar2(255);
  v_result number;
  v_Recordid Integer;
  v_MinTaskId Integer;
  v_MaxTaskId integer;
  v_StartedActivityCode nvarchar2(255);
  v_ClosedActivityCode nvarchar2(255);
  v_TokenDomain nvarchar2(255);
  v_workflow nvarchar2(255);
  v_activity nvarchar2(255);
  v_counter number;
  v_lastcounter number;
  
   v_counter1 number;
  v_lastcounter1 number;
  
   v_counter2 number;
  v_lastcounter2 number;
begin
  v_SessionId := :SessionId;
  v_TaskId := :TaskId;

  v_TokenDomain := f_UTIL_getDomainFn();
  v_workflow := f_DCM_getTaskWorkflowCodeFn();
  v_activity := f_dcm_getTaskNewState();

  begin
    select col_casetask, col_parentid, col_depth into v_CaseId, v_ParentId, v_depth from tbl_task where col_id = v_TaskId;
    exception
      when NO_DATA_FOUND then
        v_CaseId := null;
        return -1;
  end;
  
  update tbl_task set col_leaf = 1 where col_id = v_TaskId;

  begin
    select max(col_taskorder) into v_maxorder from tbl_task where col_parentid = v_TaskId;
    exception
      when NO_DATA_FOUND then
        v_maxorder := 0;
  end;
  if v_maxorder is null then
    v_maxorder := 0;
  end if;

  v_MinTaskId := 0;
  v_MaxTaskId := 0;

  for rec in (select col_id, col_dynamictaskparentid, col_taskid, col_casedynamictask, col_dynamictasktw_workitem, col_depth, col_leaf, col_name,
              col_description, col_icon, col_iconcls, col_taskorder, col_enabled, col_processorname, col_dynamictasktasksystype,
              col_dynamictaskexecmethod, col_dynamictaskppl_workbasket
                from tbl_dynamictask
                where col_casedynamictask = v_CaseId and col_sessionid = v_SessionId
                order by col_id)
  loop
    if rec.col_dynamictaskparentid = 0 then
      v_ParentId := v_TaskId;
      v_TaskOrder := v_maxorder + 1;
    else
      v_ParentId := rec.col_dynamictaskparentid;
      v_TaskOrder := rec.col_taskorder;
    end if;
    insert into tbl_task(col_id2, col_parentid, col_taskid, col_casetask, col_tw_workitemtask, col_depth, col_leaf, col_name,
                         col_description, col_icon, col_iconcls, col_taskorder, col_enabled, col_processorname,
						 col_taskdict_tasksystype, col_taskdict_executionmethod, col_taskppl_workbasket)
      values(rec.col_id, v_ParentId, rec.col_taskid, rec.col_casedynamictask, rec.col_dynamictasktw_workitem, rec.col_depth + v_depth, rec.col_leaf, rec.col_name,
             rec.col_description, rec.col_icon, rec.col_iconcls, v_TaskOrder, rec.col_enabled, rec.col_processorname,
             rec.col_dynamictasktasksystype, rec.col_dynamictaskexecmethod, rec.col_dynamictaskppl_workbasket);
	select gen_tbl_task.currval into v_CurrTaskId from dual;

        
	INSERT INTO tbl_taskext
				(COL_TASKEXTTASK) 
	VALUES      (v_CurrTaskId); 
	----------------------------------------------------------------------------

    if v_MinTaskId = 0 then
      v_MinTaskId := v_CurrTaskId;
    end if;
    if v_MaxTaskId = 0 then
      v_MaxTaskId := v_CurrTaskId;
    end if;
    if v_CurrTaskId < v_MinTaskId then
      v_MinTaskId := v_CurrTaskId;
    end if;
    if v_CurrTaskId > v_MaxTaskId then
      v_MaxTaskId := v_CurrTaskId;
    end if;

    if rec.col_dynamictaskparentid <> 0 then
      update tbl_task set col_parentid = (select col_id from tbl_task where col_id2 = rec.col_dynamictaskparentid and col_id between v_MinTaskId and v_MaxTaskId) where col_id = v_CurrTaskId;
    end if;
    v_result := f_DCM_generateTaskId (affectedRows => v_affectedRows, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                                         prefix => 'TASK-', recordid => v_CurrTaskId, taskid => v_CustomTaskId);
    update tbl_task set col_taskid = v_CustomTaskId where col_id = v_CurrTaskId;
    v_result := f_TSKW_createWorkitem (AccessSubjectCode => SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'), ActivityCode => v_activity, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                       Owner => SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'), TaskId => v_CurrTaskId, TOKEN_USERACCESSSUBJECT => SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'), WorkflowCode => v_workflow);
    --v_Result := f_DCM_createTaskDateEvent (Name => 'DATE_TASK_CREATED', TaskId => v_CurrTaskId);
    --v_Result := f_DCM_createTaskDateEvent (Name => 'DATE_TASK_MODIFIED', TaskId => v_CurrTaskId);
    v_result := f_DCM_addTaskDateEventList(TaskId => v_CurrTaskId, state => v_activity);
    for rec2 in (select col_id, col_taskstateinitdynamictask, col_map_tskstinit_initmtd, col_map_tskstinit_tskst, col_processorcode
                from tbl_map_taskstateinitiation
                where col_taskstateinitdynamictask = rec.col_id)
    loop
      insert into tbl_map_taskstateinitiation(col_map_taskstateinittask, col_map_tskstinit_initmtd, col_map_tskstinit_tskst, col_processorcode, col_code)
        values(v_CurrTaskId, rec2.col_map_tskstinit_initmtd, rec2.col_map_tskstinit_tskst, rec2.col_processorcode, sys_guid());
    end loop;
    for rec2 in (select col_id, col_slaeventdynamictask, col_slaeventdict_slaeventtype, col_slaevent_dateeventtype, col_intervalds, col_intervalym, col_slaevent_slaeventlevel, col_maxattempts, col_attemptcount, col_slaeventorder
                 from tbl_slaevent where col_slaeventdynamictask = rec.col_id)
    loop
      insert into tbl_slaevent(col_code, col_slaeventtask, col_slaeventdict_slaeventtype, col_slaevent_dateeventtype, col_intervalds, col_intervalym, col_slaevent_slaeventlevel, col_maxattempts, col_attemptcount, col_slaeventorder)
        values(sys_guid(), v_CurrTaskId, rec2.col_slaeventdict_slaeventtype, rec2.col_slaevent_dateeventtype, rec2.col_intervalds, rec2.col_intervalym, rec2.col_slaevent_slaeventlevel, rec2.col_maxattempts, rec2.col_attemptcount, rec2.col_slaeventorder);
    end loop;
    for rec2 in (select sa.col_id as Id, sa.col_code as Code, sa.col_name as Name, sa.col_processorcode as ProcessorCode, sa.col_slaactionslaevent as SlaActionSlaLevel,
	                    sa.col_slaaction_slaeventlevel as SlaActionSlaEventLevel, sa.col_actionorder as ActionOrder
                 from tbl_slaaction sa
                   inner join tbl_slaevent se on sa.col_slaactionslaevent = se.col_id
				   where se.col_slaeventdynamictask = rec.col_id)
    loop
      insert into tbl_slaaction(col_code, col_name, col_processorcode, col_slaactionslaevent, col_slaaction_slaeventlevel, col_actionorder)
	    values(sys_guid(), rec2.Name, rec2.ProcessorCode, rec2.SlaActionSlaLevel, rec2.SlaActionSlaEventLevel, rec2.ActionOrder);
    end loop;
  end loop;
  
  select GEN_TBL_TASKDEPENDENCY.nextval into v_counter2 from dual;
  insert into tbl_taskdependency(col_tskdpndchldtskstateinit,col_tskdpndprnttskstateinit,col_type)
    (select tsic2.col_id, tsip2.col_id, td.col_type
       from tbl_taskdependency td
       inner join tbl_map_taskstateinitiation tsic on td.col_tskdpndchldtskstateinit = tsic.col_id
       inner join tbl_task tskc on tsic.col_taskstateinitdynamictask = tskc.col_id2
       inner join tbl_map_taskstateinitiation tsic2 on tskc.col_id = tsic2.col_map_taskstateinittask and tsic.col_map_tskstinit_tskst = tsic2.col_map_tskstinit_tskst
       inner join tbl_map_taskstateinitiation tsip on td.col_tskdpndprnttskstateinit = tsip.col_id
       inner join tbl_task tskp on tsip.col_taskstateinitdynamictask = tskp.col_id2
       inner join tbl_map_taskstateinitiation tsip2 on tskp.col_id = tsip2.col_map_taskstateinittask and tsip.col_map_tskstinit_tskst = tsip2.col_map_tskstinit_tskst
       where tskc.col_id between v_MinTaskId and v_MaxTaskId and tskp.col_id between v_MinTaskId and v_MaxTaskId);
   
  select GEN_TBL_TASKDEPENDENCY.currval into v_lastcounter2 from dual;

  for rec in (select col_id from tbl_taskdependency where col_id between v_counter2 and v_lastcounter2)
  loop
    update tbl_taskdependency set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
   
  v_StartedActivityCode := 'root_TSK_Status_STARTED';
  v_ClosedActivityCode := 'TASK_CLOSED_ACTIVITY';

  -- CUSTOM DEPENDENCY BETWEEN SOURCE TASK AND FIRST DYNAMIC TASK
  /*
  insert into tbl_taskdependency(col_tskdpndchldtskstateinit,col_tskdpndprnttskstateinit,col_type)
  values((select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask = v_MinTaskId
          and col_map_tskstinit_tskst = (select col_id from tbl_dict_taskstate where col_activity = v_StartedActivityCode)),
         (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask = v_TaskId
		 and col_map_tskstinit_tskst = (select col_id from tbl_dict_taskstate where col_activity = v_ClosedActivityCode)), 'FS');
  */
	select GEN_TBL_TASKEVENT.nextval into v_counter1 from dual;
  insert into tbl_taskevent(col_processorcode,col_taskeventtaskstateinit,col_taskeventmomenttaskevent,col_taskeventtypetaskevent,col_taskeventorder)
    (select te.col_processorcode,tsi2.col_id,te.col_taskeventmomenttaskevent,te.col_taskeventtypetaskevent,te.col_taskeventorder
       from tbl_taskevent te
       --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
       inner join tbl_map_taskstateinitiation tsi on te.col_taskeventtaskstateinit = tsi.col_id
       inner join tbl_dynamictask dtsk on tsi.col_taskstateinitdynamictask = dtsk.col_id2
       --JOIN TO RUNTIME TASK AND TASKSTATEINITIATION RECORDS CORRESPONDING TO DYNAMIC TASK AND DYNAMIC TASKSTATEINITIATION RECORDS
	   inner join tbl_task tsk on dtsk.col_id = tsk.col_id2
       inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinit_tskst = tsi2.col_map_tskstinit_tskst
       where tsk.col_id between v_MinTaskId and v_MaxTaskId);
	select GEN_TBL_TASKEVENT.currval into v_lastcounter1 from dual;

  for rec in (select col_id from tbl_taskevent where col_id between v_counter1 and v_lastcounter1)
  loop
    update tbl_taskevent set col_code = sys_guid() where col_id = rec.col_id;
  end loop;



  select gen_tbl_autoruleparameter.nextval into v_counter from dual;
  insert into tbl_autoruleparameter(col_ruleparam_taskstateinit,col_taskeventautoruleparam,col_paramcode,col_paramvalue,col_ttautoruleparameter,col_autoruleparametertask,
                                      col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
    (select s1.RTTaskStateInitId, s1.RTTaskEventId, s1.RuleParamCode, s1.RuleParamValue, s1.RuleParamTaskTmplId, s1.RTTaskId,
            SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'), sysdate, SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'), sysdate, SYS_CONTEXT('CLIENTCONTEXT','AccessSubject')
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
        --JOIN TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi on arp.col_ruleparam_taskstateinit = tsi.col_id
        inner join tbl_dynamictask dtsk on tsi.col_map_taskstateinittasktmpl = dtsk.col_id2
        --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_task tsk on dtsk.col_id = tsk.col_id2
        inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinit_tskst = tsi2.col_map_tskstinit_tskst
        where dtsk.col_sessionid = v_SessionId and tsk.col_id between v_MinTaskId and v_MaxTaskId
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
        inner join tbl_dynamictask dtsk on tsi.col_map_taskstateinittasktmpl = dtsk.col_id2
        --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_task tsk on dtsk.col_id = tsk.col_id2
        inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinit_tskst = tsi2.col_map_tskstinit_tskst
        inner join tbl_taskevent te2 on tsi2.col_id = te2.col_taskeventtaskstateinit
        where dtsk.col_sessionid = v_SessionId and tsk.col_id between v_MinTaskId and v_MaxTaskId
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
          inner join tbl_dynamictask dtsk on tskt.col_id = dtsk.col_id2
          inner join tbl_task tsk on dtsk.col_id = tsk.col_id2
          where dtsk.col_sessionid = v_SessionId and tsk.col_id between v_MinTaskId and v_MaxTaskId
      )s1);
  select gen_tbl_autoruleparameter.currval into v_lastcounter from dual;
  for rec in (select col_id from tbl_autoruleparameter where col_id between v_counter and v_lastcounter)
  loop
    update tbl_autoruleparameter set col_code = sys_guid() where col_id = rec.col_id;
  end loop;

  update tbl_task tsk set col_id2 = (select col_id2 from tbl_dynamictask dtsk where tsk.col_id2 = dtsk.col_id and dtsk.col_sessionid = v_SessionId)
    where tsk.col_id between v_MinTaskId and v_MaxTaskId;

  v_result := f_DCM_cleanupDynamicProc(SessionId => V_SessionId);

  begin
    select max(col_taskorder) + 1 into v_maxorder from tbl_task where col_parentid = v_TaskId;
    exception
      when NO_DATA_FOUND then
        v_maxorder := 1;
  end;
  if v_maxorder is null then
    v_maxorder := 1;
  end if;

  for rec in
  (
  select col_id, col_parentid
    from tbl_task where col_id between v_MinTaskId + 1 and v_MaxTaskId and col_parentid = v_MinTaskId
  )
  loop
    update tbl_task set col_taskorder = v_maxorder, col_parentid = v_TaskId
      where col_id = rec.col_id and col_parentid = v_MinTaskId;
    v_maxorder := v_maxorder + 1;
  end loop;
  
  v_result := f_DCM_cleanupTask(TaskId => v_MinTaskId);

end;