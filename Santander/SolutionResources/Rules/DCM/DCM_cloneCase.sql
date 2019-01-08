declare
  v_caseId Integer;
  v_caseTypeId Integer;
  v_procedureId Integer;
  v_taskId Integer;
  v_taskWorkitemId Integer;
  v_createdCaseId Integer;
  v_createdCaseExtId Integer;
  v_csiId Integer;
  v_tsiId Integer;
  v_caseWorkitemId Integer;
  v_caseEventId Integer;
  v_slaEventId Integer;
  v_slaActionId Integer;
  v_arpId Integer;
  v_taskDependencyId Integer;
  v_taskEventId Integer;
  v_caseTypeCode nvarchar2(255);
  v_caseTitle nvarchar2(255);
  v_taskTitle nvarchar2(255);
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_affectedRows number;
  v_activityCode nvarchar2(255);
  v_workflowCode nvarchar2(255);
  v_result number;
  v_customdata nclob;
  v_customdataprocessor nvarchar2(255);
begin
  v_caseId := :CaseId;
  v_caseTypeId := :CaseTypeId;
  begin
    select col_id into v_result from tbl_case where col_id = v_caseId;
    exception
    when NO_DATA_FOUND then
      v_ErrorCode := 101;
      v_ErrorMessage := 'Case not found';
      return -1;
  end;
  if v_caseTypeId is not null then
    begin
      select col_code, col_casesystypeprocedure into v_caseTypeCode, v_procedureId from tbl_dict_casesystype where col_id = v_caseTypeId;
      exception
      when NO_DATA_FOUND then
      v_caseTypeId := null;
      v_caseTypeCode := null;
	  v_procedureId := null;
    end;
  end if;
  insert into tbl_case
  (
	col_caseid, col_createdby, col_createddate, col_dateassigned, col_owner, col_procedurecase, col_stp_prioritycase,
	col_stp_resolutioncodecase, col_casedict_casesystype, col_summary, col_resolveby, col_caseppl_workbasket,
	col_draft, col_processorname, col_defaultcasedocfolder, col_defaultmailcasedocfolder, col_defaultprtlcasedocfolder,
	col_int_integtargetcase, col_extsysid
  )
  select col_caseid, col_createdby, col_createddate, col_dateassigned, col_owner, col_procedurecase, col_stp_prioritycase,
	col_stp_resolutioncodecase, col_casedict_casesystype, col_summary, col_resolveby, col_caseppl_workbasket,
	col_draft, col_processorname, col_defaultcasedocfolder, col_defaultmailcasedocfolder, col_defaultprtlcasedocfolder,
	col_int_integtargetcase, col_extsysid
  from tbl_case
  where col_id = v_caseId;
  select gen_tbl_Case.currval into v_createdCaseId from dual;
  insert into tbl_caseext(col_caseextcase, col_description, col_customdata) select v_createdCaseId, col_description, col_customdata from tbl_caseext where col_caseextcase = v_caseid;
  if v_caseTypeId is not null then
    update tbl_case set col_casedict_casesystype = v_caseTypeId, col_procedurecase = v_procedureid where col_id = v_createdCaseId;
  end if;
  v_result := f_DCM_createCaseHistory(CaseId => v_caseId, MessageCode => 'CaseCreatedInState', IsSystem => 0);
  if v_caseTypeId is not null then
    v_result := f_CSW_createWorkitem2(CaseId => v_createdCaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                      Owner => sys_context('CLIENTCONTEXT', 'AccessSubject'), ProcedureId => v_procedureId);
    v_result := f_DCM_generateCaseId2(CaseId => v_createdCaseId, CaseTitle => v_caseTitle, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
    v_result := f_DCM_copyCaseStateInit(CaseId => v_createdCaseId);
    v_result := f_DCM_copyCaseEvent(CaseId => v_createdCaseId);
    v_result := f_DCM_copyCaseRuleParam(CaseId => v_createdCaseId);
    v_result := f_DCM_CopyTask (affectedRows => v_affectedRows, CaseId => v_createdCaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                owner => null, prefix => 'TASK-',
                                ProcedureId => v_procedureId, recordId => v_result, TOKEN_USERACCESSSUBJECT => sys_context('CLIENTCONTEXT', 'AccessSubject'));
    v_activityCode := f_dcm_getTaskNewState();
    v_workflowCode := f_UTIL_getDomainFn() || '_' || f_DCM_getTaskWorkflowCodeFn();
    begin
      for task_rec in (select col_id from tbl_task where col_casetask = v_createdCaseId)
      loop
        v_result := f_TSKW_createWorkitem2 (
                                            ActivityCode => v_activityCode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                            
                                            TaskId => task_rec.col_id, 
                                            WorkflowCode => v_workflowCode);
        v_result := f_DCM_addTaskDateEventList(TaskId => task_rec.col_id, state => v_activityCode);
        v_result := f_DCM_createTaskHistory (IsSystem => 0, MessageCode => 'TaskCreatedInState', TaskId => task_rec.col_id);
        -- CREATE A TASK EXT RECORD FOR EACH TASK
        insert into tbl_taskext(col_taskexttask) values(task_rec.col_id);
      end loop;
    end;
    v_result := f_DCM_copySlaEvent(CaseId => v_createdCaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
    v_result := f_DCM_CopyParticipant(CaseId => v_createdCaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
    v_result := f_DCM_CopyTaskStateInit(CaseId => v_createdCaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                        owner => sys_context('CLIENTCONTEXT', 'AccessSubject'));
    v_result := f_DCM_CopyTaskDependency(CaseId => v_createdCaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                         owner => sys_context('CLIENTCONTEXT', 'AccessSubject'));
    v_result := f_DCM_CopyTaskEvent(CaseId => v_createdCaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                    owner => sys_context('CLIENTCONTEXT', 'AccessSubject'));
    v_result := f_DCM_CopyRuleParameter(CaseId => v_createdCaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                        owner => sys_context('CLIENTCONTEXT', 'AccessSubject'));
    v_result := f_DCM_addCaseDateEventList2(CaseId => v_createdCaseId);
  else
    insert into tbl_cw_workitem(col_workflow,col_activity,col_cw_workitemdict_casestate,col_cw_workitemprevcasestate,col_instanceid,col_owner,col_createdby,col_createddate,col_instancetype)
    select col_workflow, col_activity, col_cw_workitemdict_casestate, col_cw_workitemprevcasestate, col_instanceid, col_owner, col_createdby, col_createddate, col_instancetype
    from tbl_cw_workitem where col_id = (select col_cw_workitemcase from tbl_case where col_id = v_caseId);
    select gen_tbl_cw_workitem.currval into v_caseWorkitemId from dual;
    update tbl_case
    set col_cw_workitemcase = v_caseWorkitemId,
        col_workflow = (select col_workflow from tbl_cw_workitem where col_id = (select col_cw_workitemcase from tbl_case where col_id = v_caseId)),
        col_activity = (select col_activity from tbl_cw_workitem where col_id = (select col_cw_workitemcase from tbl_case where col_id = v_caseId)),
        col_casedict_casestate = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id = (select col_cw_workitemcase from tbl_case where col_id = v_caseId))
    where col_id = v_createdCaseId;
    v_result := f_DCM_generateCaseId2(CaseId => v_caseId, CaseTitle => v_caseTitle, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
    for rec in (select v_createdCaseId as CreatedCaseId,col_map_csstinit_csst,col_processorcode,col_assignprocessorcode,col_casestateinit_initmethod,
	                   col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner
    from tbl_map_casestateinitiation where col_map_casestateinitcase = v_caseId)
    loop
      insert into tbl_map_casestateinitiation(col_map_casestateinitcase,col_map_csstinit_csst,col_processorcode,col_assignprocessorcode,
                                              col_casestateinit_initmethod,
                                              col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      values(v_createdCaseId,rec.col_map_csstinit_csst,rec.col_processorcode,rec.col_assignprocessorcode,rec.col_casestateinit_initmethod,
            rec.col_createdby,rec.col_createddate,rec.col_modifiedby,rec.col_modifieddate,rec.col_owner);
      select gen_tbl_map_casestateinitiat.currval into v_csiId from dual;
      for rec2 in (select ce.col_processorcode,ce.col_caseeventcasestateinit,ce.col_taskeventmomentcaseevent,ce.col_taskeventtypecaseevent,ce.col_caseeventorder,
                          ce.col_createdby,ce.col_createddate,ce.col_modifiedby,ce.col_modifieddate,ce.col_owner
                   from tbl_caseevent ce
                   where ce.col_caseeventcasestateinit = v_csiId)
      loop
        insert into tbl_caseevent(col_caseeventcasestateinit,col_processorcode,col_taskeventmomentcaseevent,col_taskeventtypecaseevent,col_caseeventorder,
                                  col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
        values(v_csiId,rec2.col_processorcode,rec2.col_taskeventmomentcaseevent,rec2.col_taskeventtypecaseevent,rec2.col_caseeventorder,
               rec2.col_createdby,rec2.col_createddate,rec2.col_modifiedby,rec2.col_modifieddate,rec2.col_owner);
        select gen_tbl_caseevent.currval into v_caseEventId from dual;
        for rec3 in (select arp.col_caseeventautoruleparam, arp.col_paramcode, arp.col_paramvalue,
                     arp.col_createdby, arp.col_createddate, arp.col_modifiedby, arp.col_modifieddate, arp.col_owner
                     from tbl_autoruleparameter arp
                     where col_caseeventautoruleparam = v_caseEventId)
        loop
          insert into tbl_autoruleparameter(col_caseeventautoruleparam, col_paramcode, col_paramvalue,
                                            col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
          values(v_caseEventId,rec3.col_paramcode,rec3.col_paramvalue,
                 rec3.col_createdby,rec3.col_createddate,rec3.col_modifiedby,rec3.col_modifieddate,rec3.col_owner);
        end loop;
      end loop;
    end loop;
    --SELECT ALL RULE PARAMETERS RELATED TO CASE STATE INITIATION
    for rec in (select csi.col_id as CaseStateInitId, csi.col_processorcode as CaseStateInitProcessorCode, csi.col_map_casestateinitcase as CaseStateInitCaseId,
               csi.col_casestateinit_initmethod as CaseStateInitMethodId, csi.col_map_csstinit_csst as CaseStateInitStateId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_ruleparam_casestateinit as RuleParamCaseStateInitId, arp.col_caseeventautoruleparam as RuleParamCaseEventId,
               arp.col_createdby as ArpCreatedBy, arp.col_createddate as ArpCreatedDate,
               arp.col_modifiedby as ArpModifiedBy, arp.col_modifieddate as ArpModifiedDate, arp.col_owner as ArpOwner
          from tbl_autoruleparameter arp
          inner join tbl_map_casestateinitiation csi on arp.col_ruleparam_casestateinit = csi.col_id
          inner join tbl_case cs on csi.col_map_casestateinitcase = cs.col_id
          where cs.col_id = v_caseId)
    loop
      insert into tbl_autoruleparameter(col_ruleparam_casestateinit, col_paramcode, col_paramvalue,
                                        col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      values(rec.CaseStateInitId, rec.RuleParamCode, rec.RuleParamValue, rec.ArpCreatedBy, rec.ArpCreatedDate, rec.ArpModifiedBy, rec.ArpModifiedDate, rec.ArpOwner);
    end loop;
    insert into tbl_caseparty(col_name,col_casepartycase,col_casepartyppl_caseworker,col_casepartyparticipant,
                              col_casepartyexternalparty,col_casepartydict_partytype,col_casepartyppl_businessrole,col_casepartyppl_skill,col_casepartyppl_team,
                              col_allowdelete)
    select col_name,v_createdCaseId,col_casepartyppl_caseworker,col_casepartyparticipant,
                              col_casepartyexternalparty,col_casepartydict_partytype,col_casepartyppl_businessrole,col_casepartyppl_skill,col_casepartyppl_team,
                              col_allowdelete
    from tbl_caseparty
    where col_casepartycase = v_caseId;
    for rec in (select col_id, col_id2,col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner,
                       col_type,col_parentid,col_description,col_name,col_taskid,col_depth,col_iconcls,col_icon,col_leaf,col_taskorder,
                       col_required,col_casetask,col_taskdict_tasksystype,col_processorname,col_taskdict_executionmethod,col_pagecode
                from tbl_task
                where col_casetask = v_caseId
                order by col_depth,col_parentid,col_taskorder,col_id)
    loop
      insert into tbl_task(col_id2,col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner,
                           col_type,col_parentid,col_description,col_name,col_taskid,col_depth,col_iconcls,col_icon,col_leaf,col_taskorder,
                           col_required,col_casetask,col_taskdict_tasksystype,col_processorname,col_taskdict_executionmethod,col_pagecode)
      values(rec.col_id,rec.col_createdby,rec.col_createddate,rec.col_modifiedby,rec.col_modifieddate,rec.col_owner,
             rec.col_type,rec.col_parentid,rec.col_description,rec.col_name,rec.col_taskid,rec.col_depth,
             rec.col_iconcls,rec.col_icon,rec.col_leaf,rec.col_taskorder,rec.col_required,v_createdCaseId,
             rec.col_taskdict_tasksystype,rec.col_processorname,rec.col_taskdict_executionmethod,rec.col_pagecode);
      select gen_tbl_task.currval into v_taskId from dual;
      v_result := f_DCM_generateTaskId2(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, TaskId => v_taskId, TaskTitle => v_taskTitle);
      insert into tbl_tw_workitem(col_workflow,col_activity,col_tw_workitemdict_taskstate,col_instanceid,col_owner,col_createdby,col_createddate,col_instancetype)
      select col_workflow,col_activity,col_tw_workitemdict_taskstate,col_instanceid,col_owner,col_createdby,col_createddate,col_instancetype
      from tbl_tw_workitem where col_id = (select col_tw_workitemtask from tbl_task where col_id = rec.col_id);
      select gen_tbl_tw_workitem.currval into v_taskWorkitemId from dual;
      update tbl_task set col_tw_workitemtask = v_taskWorkitemId where col_id = v_taskId;
      v_result := f_DCM_addTaskDateEventList(TaskId => v_taskId, state => f_dcm_getTaskNewState());
      v_result := f_DCM_createTaskHistory(IsSystem => 0, MessageCode => 'TaskCreatedInState', TaskId => v_taskId);
      insert into tbl_taskext (col_taskexttask) values (v_taskId);
      --SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS
      for rec2 in (
        select cast(tsk.col_processorName as nvarchar2(255)) as TaskStateInitProcessorCode,
               tsk.col_id as TaskId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_ruleparam_taskstateinit as RuleParamTaskStateInitId, arp.col_taskeventautoruleparam as RuleParamTaskEventId,
               arp.col_createdby as ArpCreatedBy, arp.col_createddate as ArpCreatedDate,
               arp.col_modifiedby as ArpModifiedBy, arp.col_modifieddate as ArpModifiedDate, arp.col_owner as ArpOwner
        from tbl_autoruleparameter arp
        inner join tbl_task tsk on arp.col_autoruleparametertask = tsk.col_id
        where tsk.col_id = rec.col_id)
      loop
        insert into tbl_autoruleparameter(col_paramcode,col_paramvalue,col_autoruleparametertask,
                                          col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
        values(rec2.RuleParamCode,rec2.RuleParamValue,v_taskId,rec2.ArpCreatedBy,rec2.ArpCreatedDate,rec2.ArpModifiedBy,rec2.ArpModifiedDate,rec2.ArpOwner);
      end loop;
      for rec2 in(select se.col_id as SlaEventId, tsk.col_id as TaskId, tsk.col_id2 as TaskTmplId, se.col_slaeventdict_slaeventtype as SlaEventType,
                         se.col_slaevent_dateeventtype as DateEventType, se.col_intervalds as SlaEventIntervalDS, se.col_intervalym as SlaEventIntervalYM,
                         se.col_slaevent_slaeventlevel as SlaEventLevel, se.col_maxattempts as MaxAttempts, se.col_attemptcount as AttemptCount,
                         se.col_slaeventorder as SlaEventOrder
                  from tbl_slaevent se
                  inner join tbl_task tsk on se.col_slaeventtask = tsk.col_id
                  where tsk.col_id = rec.col_id)
      loop
        insert into tbl_slaevent(col_code, col_slaeventtask, col_slaeventdict_slaeventtype, col_slaevent_dateeventtype, col_intervalds, col_intervalym,
                                 col_slaevent_slaeventlevel, col_maxattempts, col_attemptcount, col_slaeventorder)
        values(sys_guid(), v_taskId, rec2.SlaEventType, rec2.DateEventType, rec2.SlaEventIntervalDS, rec2.SlaEventIntervalYM, rec2.SlaEventLevel,
               rec2.MaxAttempts, rec2.AttemptCount, rec2.SlaEventOrder);
        select gen_tbl_slaevent.currval into v_slaEventId from dual;
        for rec3 in (select sa.col_id as SlaActionId, sa.col_code as SlaActionCode, sa.col_name as SlaActionName, sa.col_processorcode as SlaActionProcCode,
                            sa.col_slaaction_slaeventlevel as SlaEventLevel, sa.col_actionorder as SlaActionOrder
                     from tbl_slaaction sa
                     inner join tbl_slaevent se on sa.col_slaactionslaevent = se.col_id
                     inner join tbl_task tsk on se.col_slaeventtask = tsk.col_id
                     where se.col_id = rec2.SlaEventId and tsk.col_id = rec2.TaskId
                     order by sa.col_actionorder)
        loop
          insert into tbl_slaaction(col_code, col_name, col_processorcode, col_slaactionslaevent, col_slaaction_slaeventlevel, col_actionorder)
                                    values(sys_guid(), rec3.SlaActionName, rec3.SlaActionProcCode, v_SlaEventId, rec3.SlaEventLevel, rec3.SlaActionOrder);
          select gen_tbl_slaaction.currval into v_slaActionId from dual;
          for rec4 in (select arp.col_paramcode as ParamCode, col_paramvalue as ParamValue
                       from tbl_autoruleparameter arp
                       inner join tbl_slaaction sa on arp.col_autoruleparamslaaction = sa.col_id
                       inner join tbl_slaevent se on sa.col_slaactionslaevent = se.col_id
                       inner join tbl_task tsk on se.col_slaeventtask = tsk.col_id
                       where tsk.col_id = rec.col_id and sa.col_id = rec3.SlaActionId)
          loop
            insert into tbl_autoruleparameter(col_autoruleparamslaaction, col_paramcode, col_paramvalue, col_code)
            values(v_SlaActionId, rec4.ParamCode, rec4.ParamValue, sys_guid());
            select gen_tbl_autoruleparameter.currval into v_arpId from dual;
          end loop; /*records in tbl_autoruleparameter for SLA actions created*/
        end loop; /*records in tbl_slaaction created*/
      end loop; /*records in tbl_slaevent created*/
      for rec2 in (select tsk.col_id as TaskId, tsi.col_id as TsiId, tsi.col_processorcode as TsiProcessorCode, tsi.col_assignprocessorcode as TsiAssignProcessorCode,
                          tsi.col_map_tskstinit_initmtd as TsiInitMethod, tsi.col_map_tskstinit_tskst as TsiTaskState,
                          tsi.col_createdby as TsiCreatedBy, tsi.col_createddate as TsiCreatedDate, tsi.col_modifiedby as TsiModifiedBy,
                          tsi.col_modifieddate as TsiModifiedDate, tsi.col_owner as TsiOwner
                   from tbl_map_taskstateinitiation tsi
                   inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
                   where tsk.col_id = rec.col_id)
      loop
        insert into tbl_map_taskstateinitiation(col_id2,col_map_taskstateinittask,col_processorcode,col_assignprocessorcode,
                                                col_map_tskstinit_initmtd,col_map_tskstinit_tskst,
                                                col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
        values(rec2.TsiId,v_taskId,rec2.TsiProcessorCode,rec2.TsiAssignProcessorCode,rec2.TsiInitMethod,rec2.TsiTaskState,rec2.TsiCreatedBy,rec2.TsiCreatedDate,
               rec2.TsiModifiedBy,rec2.TsiModifiedDate,rec2.TsiOwner);
        select gen_tbl_map_taskstateinitiat.currval into v_tsiId from dual;
        --SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION
        for rec3 in (select tsi.col_id as TaskStateInitId, tsi.col_processorcode as TaskStateInitProcessorCode,
                            tsi.col_map_taskstateinittask as TaskStateInitTaskId,
                            tsi.col_map_tskstinit_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinit_tskst as TaskStateInitStateId,
                            arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
                            arp.col_ruleparam_taskstateinit as RuleParamTaskStateInitId, arp.col_taskeventautoruleparam as RuleParamTaskEventId,
                            arp.col_createdby as ArpCreatedBy, arp.col_createddate as ArpCreatedDate,
                            arp.col_modifiedby as ArpModifiedBy, arp.col_modifieddate as ArpModifiedDate, arp.col_owner as ArpOwner
          from tbl_autoruleparameter arp
          inner join tbl_map_taskstateinitiation tsi on arp.col_ruleparam_taskstateinit = tsi.col_id
          inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
          where tsk.col_id = rec.col_id)
        loop
          insert into tbl_autoruleparameter(col_ruleparam_taskstateinit,col_paramcode,col_paramvalue,
                                            col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
          values(v_tsiId,rec3.RuleParamCode,rec3.RuleParamValue,
                 rec3.ArpCreatedBy,rec3.ArpCreatedDate,rec3.ArpModifiedBy,rec3.ArpModifiedDate,rec3.ArpOwner);
        end loop;
      end loop; /*records in tbl_map_taskstateinitiation created*/
    end loop; /*records in tbl_task created*/
    --UPDATE PARENT TASKS IN CREATED CASE
    update tbl_task tt1
    set    col_parentid = (select col_id
                           from   tbl_task tt2
                           where  tt2.col_id2 = tt1.col_parentid
                             and tt2.col_casetask = v_createdCaseId)
    where  col_casetask = v_createdCaseId;
    --CREATE TASK DEPENDENCIES IN CREATED CASE
    for rec in (select td.col_id as TdId,td.col_tskdpndchldtskstateinit,td.col_tskdpndprnttskstateinit,td.col_type,td.col_processorcode,
                       td.col_taskdependencyorder,td.col_isdefault,td.col_createdby,td.col_createddate,td.col_modifiedby,td.col_modifieddate,td.col_owner,
                       ctsi.col_id as CTsiId, ptsi.col_id as PTsiId, ctsk.col_id as CTskId, ptsk.col_id as PTskId
                from tbl_taskdependency td
                inner join tbl_map_taskstateinitiation ctsi on td.col_tskdpndchldtskstateinit = ctsi.col_id
                inner join tbl_task ctsk on ctsi.col_map_taskstateinittask = ctsk.col_id
                inner join tbl_map_taskstateinitiation ptsi on td.col_tskdpndprnttskstateinit = ptsi.col_id
                inner join tbl_task ptsk on ptsi.col_map_taskstateinittask = ptsk.col_id
                where ctsk.col_casetask = v_caseId
                and ptsk.col_casetask = v_caseId
               )
    loop
      insert into tbl_taskdependency(col_tskdpndchldtskstateinit,col_tskdpndprnttskstateinit,col_type,col_processorcode,
                                     col_taskdependencyorder,col_isdefault,
                                     col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner,col_code)
      values((select col_id from tbl_map_taskstateinitiation where col_id2 = rec.col_tskdpndchldtskstateinit),
             (select col_id from tbl_map_taskstateinitiation where col_id2 = rec.col_tskdpndprnttskstateinit),
             rec.col_type,rec.col_processorcode,rec.col_taskdependencyorder,rec.col_isdefault,
             rec.col_createdby,rec.col_createddate,rec.col_modifiedby,rec.col_modifieddate,rec.col_owner,sys_guid());
      select gen_tbl_taskdependency.currval into v_taskDependencyId from dual;
      for rec2 in (select td.col_id as TaskDependencyId,
               ctsi.col_id as CTaskStateInitId, ctsi.col_processorcode as CTaskStateInitProcessorCode, ctsi.col_map_taskstateinittask as CTaskStateInitTaskId,
               ctsi.col_map_tskstinit_initmtd as CTaskStateInitMethodId, ctsi.col_map_tskstinit_tskst as CTaskStateInitStateId,
               ptsi.col_id as PTaskStateInitId, ptsi.col_processorcode as PTaskStateInitProcessorCode, ptsi.col_map_taskstateinittask as PTaskStateInitTaskId,
               ptsi.col_map_tskstinit_initmtd as PTaskStateInitMethodId, ptsi.col_map_tskstinit_tskst as PTaskStateInitStateId,
               arp.col_id as ARPId, arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_ruleparam_taskstateinit as RuleParamTaskStateInitId, arp.col_autoruleparamtaskdep as RuleParamTaskDepId,
               arp.col_createdby as ArpCreatedBy, arp.col_createddate as ArpCreatedDate,
               arp.col_modifiedby as ArpModifiedBy, arp.col_modifieddate as ArpModifiedDate, arp.col_owner as ArpOwner
        from tbl_autoruleparameter arp
        inner join tbl_taskdependency td on arp.col_autoruleparamtaskdep = td.col_id
        inner join tbl_map_taskstateinitiation ctsi on td.col_tskdpndchldtskstateinit = ctsi.col_id
        inner join tbl_task ctsk on ctsi.col_map_taskstateinittask = ctsk.col_id
        inner join tbl_map_taskstateinitiation ptsi on td.col_tskdpndprnttskstateinit = ptsi.col_id
        inner join tbl_task ptsk on ptsi.col_map_taskstateinittask = ptsk.col_id
        where ctsk.col_casetask = v_caseId and ptsk.col_casetask = v_caseId
        and arp.col_autoruleparamtaskdep = rec.TDId)
      loop
        insert into tbl_autoruleparameter(col_autoruleparamtaskdep,col_paramcode,col_paramvalue,
                                          col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
        values(v_taskDependencyId,rec2.RuleParamCode,rec2.RuleParamValue,
               rec2.ArpCreatedBy,rec2.ArpCreatedDate,rec2.ArpModifiedBy,rec2.ArpModifiedDate,rec2.ArpOwner);
      end loop; /*records in tbl_autoruleparameter related to task dependency created*/
    end loop; /*records in tbl_taskdependency created*/
    for rec in (select te.col_id as TaskEventId,te.col_processorcode as TaskEventProcessorCode,tsi.col_id as TsiId,
                       te.col_taskeventmomenttaskevent,te.col_taskeventtypetaskevent,te.col_taskeventorder,
                       te.col_createdby as TECreatedBy,te.col_createddate as TECreatedDate,
                       te.col_modifiedby as TEModifiedBy,te.col_modifieddate as TEModifiedDate,
                       te.col_owner as TEOwner
                from tbl_taskevent te
                inner join tbl_map_taskstateinitiation tsi on te.col_taskeventtaskstateinit = tsi.col_id
                inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
                where tsk.col_casetask = v_caseId)
    loop
      insert into tbl_taskevent(col_processorcode,col_taskeventtaskstateinit,col_taskeventmomenttaskevent,col_taskeventtypetaskevent,col_taskeventorder,
                                col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      values(rec.TaskEventProcessorCode,(select col_id from tbl_map_taskstateinitiation where col_id2 = rec.TsiId),rec.col_taskeventmomenttaskevent,
             rec.col_taskeventtypetaskevent,rec.col_taskeventorder,rec.TECreatedBy,rec.TECreatedDate,rec.TEModifiedBy,rec.TEModifiedDate,rec.TEOwner);
      select gen_tbl_taskevent.currval into v_taskEventId from dual;
      --SELECT ALL RULEPARAMETERS FOR TASK EVENTS, RELATED TO TASK STATE INITIATION EVENTS
      for rec2 in (
        select tsi.col_id as TaskStateInitId, tsi.col_processorCode as TaskStateInitProcessorCode, tsi.col_map_taskstateinittask as TaskStateInitTaskId,
               tsi.col_map_tskstinit_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinit_tskst as TaskStateInitStateId,
               tsi.col_map_taskstateinittask as TaskId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_ruleparam_taskstateinit as RuleParamTaskStateInitId, arp.col_taskeventautoruleparam as RuleParamTaskEventId,
               te.col_id as TaskEventId, te.col_processorcode as TaskEventProcessorCode,
               arp.col_createdby as ArpCreatedBy, arp.col_createddate as ArpCreatedDate,
               arp.col_modifiedby as ArpModifiedBy, arp.col_modifieddate as ArpModifiedDate, arp.col_owner as ArpOwner
        from tbl_autoruleparameter arp
        inner join tbl_taskevent te on arp.col_taskeventautoruleparam = te.col_id
        inner join tbl_map_taskstateinitiation tsi on te.col_taskeventtaskstateinit = tsi.col_id
        inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
        where te.col_id = rec.TaskEventId)
      loop
        insert into tbl_autoruleparameter(col_taskeventautoruleparam,col_paramcode,col_paramvalue,
                                          col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
        values(v_taskEventId,rec2.RuleParamCode,rec2.RuleParamValue,
               rec2.ArpCreatedBy,rec2.ArpCreatedDate,rec2.ArpModifiedBy,rec2.ArpModifiedDate,rec2.ArpOwner);
      end loop; /*records in tbl_autoruleparameter for task events created*/
    end loop; /*records in tbl_taskevent created*/
  end if;
  :CloneCaseId := v_createdCaseId;
  --RETRIEVE CUSTOM DATA FROM THE SOURCE CASE
  v_customdata := f_DCM_getCaseCustomData(CaseId => v_caseId);
  --FIND CUSTOM PROCESSOR IF ONE EXISTS
  begin 
    select col_customdataprocessor
    into   v_customdataprocessor
    from   tbl_dict_casesystype
    where  col_id = (select col_casedict_casesystype from tbl_case where col_id = v_createdCaseId);
    exception
    when no_data_found then
      v_customdataprocessor := null;
  end;
  --SAVE CUSTOM DATA TO THE TARGET CASE
  if v_customdataprocessor is not null then
    --USE CUSTOM PROCESSOR IF FOUND
    v_createdCaseExtId := f_dcm_invokeCaseCusDataProc(CaseId => v_createdCaseId, Input => v_customdata, ProcessorName => v_customdataprocessor);
  else
    --SET CUSTOM DATA XML IF NO CUSTOM PROCESSOR FOUND
    update tbl_caseext
    set col_customdata =  xmltype(v_customdata)
    where col_caseextcase = v_createdCaseId;
    v_createdCaseExtId := null;
  end if;
  :CloneCaseExtId := v_createdCaseExtId;
end;