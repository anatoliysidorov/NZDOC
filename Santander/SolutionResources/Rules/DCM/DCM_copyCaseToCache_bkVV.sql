declare
  v_CaseId Integer;
begin
  v_CaseId := :CaseId;
  --CASE
  insert into tbl_casecc(col_id,col_casecccase,col_dateassigned,col_dateclosed,col_manualdateresolved,col_resolveby,col_casefrom,col_caseid,
                        col_createdby,col_extsysid,col_manualworkduration,col_modifiedby,col_owner,col_processorname,col_summary,col_lockedby,col_modifieddate,
                        col_createddate,col_lockeddate,col_lockedexpdate,col_draft,col_statupdated,col_cw_workitemcccasecc,col_caseccdict_casesystype,
                      	col_caseccppl_workbasket,col_procedurecasecc,col_stp_prioritycasecc,col_stp_resolutioncodecasecc,col_defaultcaseccdocfoldercc,
                        col_dfltmailcaseccdocfoldercc,col_dfltprntcaseccdocfoldercc,col_workflow,col_activity,col_caseccdict_casestate)
                (select col_id,col_id,col_dateassigned,col_dateclosed,col_manualdateresolved,col_resolveby,col_casefrom,col_caseid,
                        col_createdby,col_extsysid,col_manualworkduration,col_modifiedby,col_owner,col_processorname,col_summary,col_lockedby,col_modifieddate,
                        col_createddate,col_lockeddate,col_lockedexpdate,col_draft,col_statupdated,col_cw_workitemcase,col_casedict_casesystype,
                        col_caseppl_workbasket,col_procedurecase,col_stp_prioritycase,col_stp_resolutioncodecase,col_defaultcasedocfolder,
                        col_defaultmailcasedocfolder,col_defaultprtlcasedocfolder,col_workflow,col_activity,col_casedict_casestate
                  from tbl_case
                  where col_id = v_CaseId);
  --HISTORY FOR CASE
  insert into tbl_historycc(col_lockedexpdate,col_owner,col_description,col_createddate,col_historycctaskcc,col_historyccprevtaskstate,col_historyccprevcasestate,
                            col_id,col_historycchistory,col_historycccasecc,col_lockeddate,col_additionalinfo,col_historyccnextcasestate,col_createdbyname,col_modifiedby,col_modifieddate,
                            col_issystem,col_historyccnexttaskstate,col_createdby,col_lockedby,col_activitytimedate, COL_MESSAGETYPEHISTORYCC, COL_HistoryCreatedBy)
                    (select col_lockedexpdate,col_owner,col_description,col_createddate,col_historytask,col_historyprevtaskstate,col_historyprevcasestate,
                            col_id,col_id,col_historycase,col_lockeddate,col_additionalinfo,col_historynextcasestate,col_createdbyname,col_modifiedby,col_modifieddate,
                            col_issystem,col_historynexttaskstate,col_createdby,col_lockedby,col_activitytimedate, COL_MESSAGETYPEHISTORY, COL_HistoryCreatedBy
                     from tbl_history
                     where col_historycase = v_CaseId);
  --CASE WORKITEMS
  insert into tbl_cw_workitemcc(col_owner,col_createddate,col_id,col_cw_workitemcccw_workitem,col_subject,col_instancetype,col_isonhold,col_refparentid,col_modifieddate,col_prevactivity,col_cw_workitemccprevcasest,
                                col_createdby,col_lockedexpdate,col_prevactivityname,col_workflow,col_receiveddate,col_holdexpdate,col_cw_workitemccdict_casest,col_activity,
                                col_lockeddate,col_modifiedby,col_prevsubjectname,col_holdsetdate,col_lockedby,col_instanceid,col_prevsubject,col_notes)
                        (select col_owner,col_createddate,col_id,col_id,col_subject,col_instancetype,col_isonhold,col_refparentid,col_modifieddate,col_prevactivity,col_cw_workitemprevcasestate,
                                col_createdby,col_lockedexpdate,col_prevactivityname,col_workflow,col_receiveddate,col_holdexpdate,col_cw_workitemdict_casestate,col_activity,
                                col_lockeddate,col_modifiedby,col_prevsubjectname,col_holdsetdate,col_lockedby,col_instanceid,col_prevsubject,col_notes
                         from tbl_cw_workitem
                         where col_id = (select col_cw_workitemcase from tbl_case where col_id = v_CaseId));
  -- CASE STATE INITIATION
  insert into tbl_map_casestateinitcc(col_lockedexpdate,col_owner,col_processorcode,col_map_casestateinitcccasecc,col_casestateinitcc_casetype,col_createddate,col_casestateinitcc_initmtd,
                                      col_code,col_id,col_casestinitcccasestinit,col_assignprocessorcode,col_lockeddate,col_id2,col_modifiedby,col_modifieddate,col_createdby,col_map_csstinitcc_csst,col_lockedby)
                              (select col_lockedexpdate,col_owner,col_processorcode,col_map_casestateinitcase,col_casestateinit_casesystype,col_createddate,col_casestateinit_initmethod,
                                      col_code,col_id,col_id,col_assignprocessorcode,col_lockeddate,col_id2,col_modifiedby,col_modifieddate,col_createdby,col_map_csstinit_csst,col_lockedby
                               from tbl_map_casestateinitiation
                               where col_map_casestateinitcase = v_CaseId);
  --CASE EVENTS
  insert into tbl_caseeventcc(col_lockedexpdate,col_owner,col_processorcode,col_taskeventtypecaseeventcc,col_createddate,col_code,col_id,col_caseeventcccaseevent,col_caseeventcccasestinitcc,col_taskeventsnctpcaseeventcc,
                              col_taskeventmomntcaseeventcc,col_lockeddate,col_caseeventorder,col_modifiedby,col_modifieddate,col_createdby,col_lockedby)
                      (select col_lockedexpdate,col_owner,col_processorcode,col_taskeventtypecaseevent,col_createddate,col_code,col_id,col_id,col_caseeventcasestateinit,col_tskeventsynctypecaseevent,
                              col_taskeventmomentcaseevent,col_lockeddate,col_caseeventorder,col_modifiedby,col_modifieddate,col_createdby,col_lockedby
                         from tbl_caseevent
                         where col_caseeventcasestateinit in (select col_id from tbl_map_casestateinitiation where col_map_casestateinitcase = v_CaseId));
  --AUTO RULE PARAMETERS FOR CASE EVENTS
  insert into tbl_autoruleparamcc(col_ruleparcc_taskstateinitcc,col_autoruleparamcccasetype,col_lockedexpdate,col_owner,col_autoruleparccslaactioncc,col_tasktemplateautoruleparcc,col_createddate,col_paramvalue,
                                  col_autoruleparamcccasedepcc,col_code,col_ruleparcc_casestateinitcc,col_id,col_autoruleparccautorulepar,col_caseeventccautoruleparcc,col_autoruleparamcctaskcc,col_autoruleparamccparamconf,col_lockeddate,
                                  col_tasksystypeautoruleparcc,col_paramcode,col_autoruleparamcctaskdepcc,col_modifiedby,col_modifieddate,col_taskeventccautoruleparmcc,col_issystem,col_createdby,col_lockedby)
                          (select col_ruleparam_taskstateinit,col_autoruleparamcasesystype,col_lockedexpdate,col_owner,col_autoruleparamslaaction,col_ttautoruleparameter,col_createddate,col_paramvalue,
                                  col_autoruleparamcasedep,col_code,col_ruleparam_casestateinit,col_id,col_id,col_caseeventautoruleparam,col_autoruleparametertask,col_autoruleparamparamconfig,col_lockeddate,
                                  col_tasksystypeautoruleparam,col_paramcode,col_autoruleparamtaskdep,col_modifiedby,col_modifieddate,col_taskeventautoruleparam,col_issystem,col_createdby,col_lockedby
                           from tbl_autoruleparameter
                           where col_caseeventautoruleparam in
                             (select col_id from tbl_caseevent where col_caseeventcasestateinit in
                               (select col_id from tbl_map_casestateinitiation where col_map_casestateinitcase = v_CaseId)));
  --TASKS
  insert into tbl_taskcc(col_taskccppl_workbasket,col_type,col_owner,col_taskccpreviousworkbasket,col_description,col_leaf,col_createddate,col_manualdateresolved,col_dateclosed,col_id,col_taskcctask,col_iconcls,
                         col_statupdated,col_required,col_depth,col_resolutiondescription,col_dateassigned,col_taskorder,col_taskccdict_customword,col_taskid,col_modifieddate,
                         col_tw_workitemcctaskcc,col_createdby,col_extsysid,col_datestarted,col_taskccdict_executionmtd,col_parentidcc,col_lockedexpdate,col_customdata,col_taskccdict_tasksystype,
                         col_manualworkduration,col_systemtype2,col_hoursworked,col_icon,col_name,col_status,col_processorname,col_perccomplete,col_lockeddate,col_id2,col_modifiedby,col_pagecode,
                         col_taskccstp_resolutioncode,col_taskccprocedure,col_enabled,col_draft,col_lockedby,col_casecctaskcc,col_transactionid,col_taskccworkbasket_param,col_taskccresolcode_param)
                 (select col_taskppl_workbasket,col_type,col_owner,col_taskpreviousworkbasket,col_description,col_leaf,col_createddate,col_manualdateresolved,col_dateclosed,col_id,col_id,col_iconcls,
                         col_statupdated,col_required,col_depth,col_resolutiondescription,col_dateassigned,col_taskorder,col_taskdict_customword,col_taskid,col_modifieddate,
                         col_tw_workitemtask,col_createdby,col_extsysid,col_datestarted,col_taskdict_executionmethod,col_parentid,col_lockedexpdate,col_customdata,col_taskdict_tasksystype,
                         col_manualworkduration,col_systemtype2,col_hoursworked,col_icon,col_name,col_status,col_processorname,col_perccomplete,col_lockeddate,col_id2,col_modifiedby,col_pagecode,
                         col_taskstp_resolutioncode,col_taskprocedure,col_enabled,col_draft,col_lockedby,col_casetask,col_transactionid,col_taskworkbasket_param,col_taskresolutioncode_param
                  from tbl_task
                  where col_casetask = v_CaseId);
  --TASK WORKITEMS
  insert into tbl_tw_workitemcc(col_owner,col_createddate,col_id,col_tw_workitemcctw_workitem,col_subject,col_instancetype,col_tw_workitemccprevtaskst,col_isonhold,col_refparentid,col_modifieddate,col_prevactivity,col_createdby,
                                col_lockedexpdate,col_prevactivityname,col_workflow,col_receiveddate,col_holdexpdate,col_activity,col_lockeddate,col_modifiedby,col_prevsubjectname,col_tw_workitemccdict_taskst,
                                col_holdsetdate,col_lockedby,col_instanceid,col_prevsubject,col_notes)
                        (select col_owner,col_createddate,col_id,col_id,col_subject,col_instancetype,col_tw_workitemprevtaskstate,col_isonhold,col_refparentid,col_modifieddate,col_prevactivity,col_createdby,
                                col_lockedexpdate,col_prevactivityname,col_workflow,col_receiveddate,col_holdexpdate,col_activity,col_lockeddate,col_modifiedby,col_prevsubjectname,col_tw_workitemdict_taskstate,
                                col_holdsetdate,col_lockedby,col_instanceid,col_prevsubject,col_notes
                         from tbl_tw_workitem
                         where col_id in (select col_tw_workitemtask from tbl_task where col_casetask = v_CaseId));
  --DATE EVENTS FOR TASKS IN CASE
  insert into tbl_dateeventcc(col_datevalue,col_lockedexpdate,col_customdata,col_owner,col_createddate,col_id,col_dateeventccdateevent,col_performedby,col_dateeventcccasecc,col_lockeddate,col_datename,col_modifiedby,
                              col_dateeventccppl_workbasket,col_dateeventcc_dateeventtype,col_modifieddate,col_dateeventccppl_caseworker,col_dateeventcctaskcc,col_createdby,col_lockedby)
                      (select col_datevalue,col_lockedexpdate,col_customdata,col_owner,col_createddate,col_id,col_id,col_performedby,col_dateeventcase,col_lockeddate,col_datename,col_modifiedby,
                              col_dateeventppl_workbasket,col_dateevent_dateeventtype,col_modifieddate,col_dateeventppl_caseworker,col_dateeventtask,col_createdby,col_lockedby
                        from tbl_dateevent
                        where col_dateeventtask in (select col_id from tbl_task where col_casetask = v_CaseId));
  --HISTORY FOR TASKS IN CASE
  insert into tbl_historycc(col_lockedexpdate,col_owner,col_description,col_createddate,col_historycctaskcc,col_historyccprevtaskstate,col_historyccprevcasestate,
                            col_id,col_historycchistory,col_historycccasecc,col_lockeddate,col_additionalinfo,col_historyccnextcasestate,col_createdbyname,col_modifiedby,col_modifieddate,
                            col_issystem,col_historyccnexttaskstate,col_createdby,col_lockedby,col_activitytimedate, COL_MESSAGETYPEHISTORYCC, COL_HistoryCreatedBy)
                    (select col_lockedexpdate,col_owner,col_description,col_createddate,col_historytask,col_historyprevtaskstate,col_historyprevcasestate,
                            col_id,col_id,col_historycase,col_lockeddate,col_additionalinfo,col_historynextcasestate,col_createdbyname,col_modifiedby,col_modifieddate,
                            col_issystem,col_historynexttaskstate,col_createdby,col_lockedby,col_activitytimedate, COL_MESSAGETYPEHISTORY, COL_HistoryCreatedBy
                     from tbl_history
                     where col_historytask in (select col_id from tbl_task where col_casetask = v_CaseId));
  --SLA EVENTS
  insert into tbl_slaeventcc(col_lockedexpdate,col_slaeventcctasktemplate,col_owner,col_createddate,col_code,col_id,col_slaeventccslaevent,col_slaeventcccasecc,col_isrequired,col_slaeventcc_dateeventtype,
                             col_slaeventcctaskcc,col_lockeddate,col_slaeventcc_tasksystype,col_id2,col_intervalds,col_modifiedby,col_slaeventcc_slaeventtype,col_intervalym,
                             col_modifieddate,col_slaeventorder,col_maxattempts,col_createdby,col_lockedby,col_slaeventcc_slaeventlevel,col_attemptcount)
                     (select col_lockedexpdate,col_slaeventtasktemplate,col_owner,col_createddate,col_code,col_id,col_id,col_slaeventcase,col_isrequired,col_slaevent_dateeventtype,
                             col_slaeventtask,col_lockeddate,col_slaeventdict_tasksystype,col_id2,col_intervalds,col_modifiedby,col_slaeventdict_slaeventtype,col_intervalym,
                             col_modifieddate,col_slaeventorder,col_maxattempts,col_createdby,col_lockedby,col_slaevent_slaeventlevel,col_attemptcount
                      from tbl_slaevent
                      where col_slaeventtask in (select col_id from tbl_task where col_casetask = v_CaseId));
  --SLA ACTIONS
  insert into tbl_slaactioncc(col_lockedexpdate,col_owner,col_processorcode,col_description,col_createddate,col_code,col_name,col_id,col_slaactionccslaaction,col_slaactioncc_slaeventlevel,col_lockeddate,col_actionorder,col_modifiedby,
                              col_modifieddate,col_slaactionccslaeventcc,col_createdby,col_lockedby)
                      (select col_lockedexpdate,col_owner,col_processorcode,col_description,col_createddate,col_code,col_name,col_id,col_id,col_slaaction_slaeventlevel,col_lockeddate,col_actionorder,col_modifiedby,
                              col_modifieddate,col_slaactionslaevent,col_createdby,col_lockedby
                       from tbl_slaaction
                       where col_slaactionslaevent in (select col_id from tbl_slaevent where col_slaeventtask in (select col_id from tbl_task where col_casetask = v_CaseId)));
  --TASK STATE INITIATION
  insert into tbl_map_taskstateinitcc(col_lockedexpdate,col_owner,col_processorcode,col_map_taskstateinitcctaskcc,col_createddate,col_code,col_routeddate,col_id,col_taskstinitcctaskstinit,col_assignprocessorcode,
                                      col_map_taskstinitcctasktmpl,col_lockeddate,col_map_tskstinitcc_tskst,col_id2,col_modifiedby,col_map_tskstinitcc_initmtd,col_taskstateinitcc_tasktype,
                                      col_modifieddate,col_createdby,col_lockedby,col_routedby)
                              (select col_lockedexpdate,col_owner,col_processorcode,col_map_taskstateinittask,col_createddate,col_code,col_routeddate,col_id,col_id,col_assignprocessorcode,
                                      col_map_taskstateinittasktmpl,col_lockeddate,col_map_tskstinit_tskst,col_id2,col_modifiedby,col_map_tskstinit_initmtd,col_taskstateinit_tasksystype,
                                      col_modifieddate,col_createdby,col_lockedby,col_routedby
                               from tbl_map_taskstateinitiation
                               where col_map_taskstateinittask in (select col_id from tbl_task where col_casetask = v_CaseId));
  --TASK DEPENDENCIES
  insert into tbl_taskdependencycc(col_lockedexpdate,col_isdefault,col_owner,col_type,col_processorcode,col_createddate,col_code,col_id,col_taskdepcctaskdep,col_taskdpchldcctaskstinitcc,col_lockeddate,
                                   col_id2,col_taskdpprntcctaskstinitcc,col_modifiedby,col_modifieddate,col_taskdependencyorder,col_createdby,col_lockedby)
                           (select col_lockedexpdate,col_isdefault,col_owner,col_type,col_processorcode,col_createddate,col_code,col_id,col_id,col_tskdpndchldtskstateinit,col_lockeddate,
                                   col_id2,col_tskdpndprnttskstateinit,col_modifiedby,col_modifieddate,col_taskdependencyorder,col_createdby,col_lockedby
                              from tbl_taskdependency
                              where col_tskdpndchldtskstateinit in (select col_id from tbl_map_taskstateinitiation
                                  where col_map_taskstateinittask in (select col_id from tbl_task where col_casetask = v_CaseId))
                                and col_tskdpndprnttskstateinit in (select col_id from tbl_map_taskstateinitiation
                                  where col_map_taskstateinittask in (select col_id from tbl_task where col_casetask = v_CaseId)));
  --TASK EVENTS
  insert into tbl_taskeventcc(col_lockedexpdate,col_owner,col_processorcode,col_taskeventsnctptaskeventcc,col_createddate,col_code,col_id,col_taskeventcctaskevent,col_taskeventmomnttaskeventcc,col_lockeddate,
                              col_id2,col_modifiedby,col_taskeventtypetaskeventcc,col_modifieddate,col_taskeventorder,col_taskeventcctaskstinitcc,col_createdby,col_lockedby)
                      (select col_lockedexpdate,col_owner,col_processorcode,col_tskeventsynctypetaskevent,col_createddate,col_code,col_id,col_id,col_taskeventmomenttaskevent,col_lockeddate,
                              col_id2,col_modifiedby,col_taskeventtypetaskevent,col_modifieddate,col_taskeventorder,col_taskeventtaskstateinit,col_createdby,col_lockedby
                       from tbl_taskevent
                       where col_taskeventtaskstateinit in (select col_id from tbl_map_taskstateinitiation
                         where col_map_taskstateinittask in (select col_id from tbl_task where col_casetask = v_CaseId)));
  --SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION
  insert into tbl_autoruleparamcc(col_ruleparcc_taskstateinitcc,col_autoruleparamcccasetype,col_lockedexpdate,col_owner,col_autoruleparccslaactioncc,col_tasktemplateautoruleparcc,col_createddate,
                                  col_paramvalue,col_autoruleparamcccasedepcc,col_code,col_ruleparcc_casestateinitcc,col_id,col_autoruleparccautorulepar,col_caseeventccautoruleparcc,col_autoruleparamcctaskcc,
                                  col_autoruleparamccparamconf,col_lockeddate,col_tasksystypeautoruleparcc,col_paramcode,col_autoruleparamcctaskdepcc,col_modifiedby,col_modifieddate,
                                  col_taskeventccautoruleparmcc,col_issystem,col_createdby,col_lockedby)
                          (select col_ruleparam_taskstateinit,col_autoruleparamcasesystype,col_lockedexpdate,col_owner,col_autoruleparamslaaction,col_ttautoruleparameter,col_createddate,
                                  col_paramvalue,col_autoruleparamcasedep,col_code,col_ruleparam_casestateinit,col_id,col_id,col_caseeventautoruleparam,col_autoruleparametertask,
                                  col_autoruleparamparamconfig,col_lockeddate,col_tasksystypeautoruleparam,col_paramcode,col_autoruleparamtaskdep,col_modifiedby,col_modifieddate,
                                  col_taskeventautoruleparam,col_issystem,col_createdby,col_lockedby
                           from tbl_autoruleparameter
                           where col_ruleparam_taskstateinit in (select col_id from tbl_map_taskstateinitiation
                             where col_map_taskstateinittask in (select col_id from tbl_task where col_casetask = v_CaseId)));
  --SELECT ALL RULEPARAMETERS FOR TASK EVENTS
  insert into tbl_autoruleparamcc(col_ruleparcc_taskstateinitcc,col_autoruleparamcccasetype,col_lockedexpdate,col_owner,col_autoruleparccslaactioncc,col_tasktemplateautoruleparcc,col_createddate,
                                  col_paramvalue,col_autoruleparamcccasedepcc,col_code,col_ruleparcc_casestateinitcc,col_id,col_autoruleparccautorulepar,col_caseeventccautoruleparcc,col_autoruleparamcctaskcc,
                                  col_autoruleparamccparamconf,col_lockeddate,col_tasksystypeautoruleparcc,col_paramcode,col_autoruleparamcctaskdepcc,col_modifiedby,col_modifieddate,
                                  col_taskeventccautoruleparmcc,col_issystem,col_createdby,col_lockedby)
                          (select col_ruleparam_taskstateinit,col_autoruleparamcasesystype,col_lockedexpdate,col_owner,col_autoruleparamslaaction,col_ttautoruleparameter,col_createddate,
                                  col_paramvalue,col_autoruleparamcasedep,col_code,col_ruleparam_casestateinit,col_id,col_id,col_caseeventautoruleparam,col_autoruleparametertask,
                                  col_autoruleparamparamconfig,col_lockeddate,col_tasksystypeautoruleparam,col_paramcode,col_autoruleparamtaskdep,col_modifiedby,col_modifieddate,
                                  col_taskeventautoruleparam,col_issystem,col_createdby,col_lockedby
                           from tbl_autoruleparameter
                           where col_taskeventautoruleparam in (select col_id from tbl_taskevent
                             where col_taskeventtaskstateinit in (select col_id from tbl_map_taskstateinitiation
                               where col_map_taskstateinittask in (select col_id from tbl_task where col_casetask = v_CaseId))));
  --SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS
  insert into tbl_autoruleparamcc(col_ruleparcc_taskstateinitcc,col_autoruleparamcccasetype,col_lockedexpdate,col_owner,col_autoruleparccslaactioncc,col_tasktemplateautoruleparcc,col_createddate,
                                  col_paramvalue,col_autoruleparamcccasedepcc,col_code,col_ruleparcc_casestateinitcc,col_id,col_autoruleparccautorulepar,col_caseeventccautoruleparcc,col_autoruleparamcctaskcc,
                                  col_autoruleparamccparamconf,col_lockeddate,col_tasksystypeautoruleparcc,col_paramcode,col_autoruleparamcctaskdepcc,col_modifiedby,col_modifieddate,
                                  col_taskeventccautoruleparmcc,col_issystem,col_createdby,col_lockedby)
                          (select col_ruleparam_taskstateinit,col_autoruleparamcasesystype,col_lockedexpdate,col_owner,col_autoruleparamslaaction,col_ttautoruleparameter,col_createddate,
                                  col_paramvalue,col_autoruleparamcasedep,col_code,col_ruleparam_casestateinit,col_id,col_id,col_caseeventautoruleparam,col_autoruleparametertask,
                                  col_autoruleparamparamconfig,col_lockeddate,col_tasksystypeautoruleparam,col_paramcode,col_autoruleparamtaskdep,col_modifiedby,col_modifieddate,
                                  col_taskeventautoruleparam,col_issystem,col_createdby,col_lockedby
                           from tbl_autoruleparameter
                           where col_autoruleparametertask in (select col_id from tbl_task where col_casetask = v_CaseId));
  --SELECT ALL RULEPARAMETERS FOR TASK DEPENDENCIES
  insert into tbl_autoruleparamcc(col_ruleparcc_taskstateinitcc,col_autoruleparamcccasetype,col_lockedexpdate,col_owner,col_autoruleparccslaactioncc,col_tasktemplateautoruleparcc,col_createddate,
                                  col_paramvalue,col_autoruleparamcccasedepcc,col_code,col_ruleparcc_casestateinitcc,col_id,col_autoruleparccautorulepar,col_caseeventccautoruleparcc,col_autoruleparamcctaskcc,
                                  col_autoruleparamccparamconf,col_lockeddate,col_tasksystypeautoruleparcc,col_paramcode,col_autoruleparamcctaskdepcc,col_modifiedby,col_modifieddate,
                                  col_taskeventccautoruleparmcc,col_issystem,col_createdby,col_lockedby)
                          (select col_ruleparam_taskstateinit,col_autoruleparamcasesystype,col_lockedexpdate,col_owner,col_autoruleparamslaaction,col_ttautoruleparameter,col_createddate,
                                  col_paramvalue,col_autoruleparamcasedep,col_code,col_ruleparam_casestateinit,col_id,col_id,col_caseeventautoruleparam,col_autoruleparametertask,
                                  col_autoruleparamparamconfig,col_lockeddate,col_tasksystypeautoruleparam,col_paramcode,col_autoruleparamtaskdep,col_modifiedby,col_modifieddate,
                                  col_taskeventautoruleparam,col_issystem,col_createdby,col_lockedby
                           from tbl_autoruleparameter
                           where col_autoruleparamtaskdep in (select col_id from tbl_taskdependency
                             where col_tskdpndprnttskstateinit in (select col_id from tbl_map_taskstateinitiation
                              where col_map_taskstateinittask in (select col_id from tbl_task where col_casetask = v_CaseId))
                              and col_tskdpndchldtskstateinit in (select col_id from tbl_map_taskstateinitiation
                              where col_map_taskstateinittask in (select col_id from tbl_task where col_casetask = v_CaseId))));
  --SELECT ALL RULE PARAMETERS RELATED TO CASE STATE INITIATION
  insert into tbl_autoruleparamcc(col_ruleparcc_taskstateinitcc,col_autoruleparamcccasetype,col_lockedexpdate,col_owner,col_autoruleparccslaactioncc,col_tasktemplateautoruleparcc,col_createddate,
                                  col_paramvalue,col_autoruleparamcccasedepcc,col_code,col_ruleparcc_casestateinitcc,col_id,col_autoruleparccautorulepar,col_caseeventccautoruleparcc,col_autoruleparamcctaskcc,
                                  col_autoruleparamccparamconf,col_lockeddate,col_tasksystypeautoruleparcc,col_paramcode,col_autoruleparamcctaskdepcc,col_modifiedby,col_modifieddate,
                                  col_taskeventccautoruleparmcc,col_issystem,col_createdby,col_lockedby)
                          (select col_ruleparam_taskstateinit,col_autoruleparamcasesystype,col_lockedexpdate,col_owner,col_autoruleparamslaaction,col_ttautoruleparameter,col_createddate,
                                  col_paramvalue,col_autoruleparamcasedep,col_code,col_ruleparam_casestateinit,col_id,col_id,col_caseeventautoruleparam,col_autoruleparametertask,
                                  col_autoruleparamparamconfig,col_lockeddate,col_tasksystypeautoruleparam,col_paramcode,col_autoruleparamtaskdep,col_modifiedby,col_modifieddate,
                                  col_taskeventautoruleparam,col_issystem,col_createdby,col_lockedby
                           from tbl_autoruleparameter
                           where col_ruleparam_casestateinit in (select col_id from tbl_map_casestateinitiation
                             where col_map_casestateinitcase = v_CaseId));
                             
  /*VV*/
  --SELECT ALL RULE PARAMETERS RELATED TO SLA ACTIONS
  insert into tbl_autoruleparamcc(col_ruleparcc_taskstateinitcc,col_autoruleparamcccasetype,col_lockedexpdate,col_owner,col_autoruleparccslaactioncc,col_tasktemplateautoruleparcc,col_createddate,
                                  col_paramvalue,col_autoruleparamcccasedepcc,col_code,col_ruleparcc_casestateinitcc,col_id,col_autoruleparccautorulepar,col_caseeventccautoruleparcc,col_autoruleparamcctaskcc,
                                  col_autoruleparamccparamconf,col_lockeddate,col_tasksystypeautoruleparcc,col_paramcode,col_autoruleparamcctaskdepcc,col_modifiedby,col_modifieddate,
                                  col_taskeventccautoruleparmcc,col_issystem,col_createdby,col_lockedby)
                          (select col_ruleparam_taskstateinit,col_autoruleparamcasesystype,col_lockedexpdate,col_owner,col_autoruleparamslaaction,col_ttautoruleparameter,col_createddate,
                                  col_paramvalue,col_autoruleparamcasedep,col_code,col_ruleparam_casestateinit,col_id,col_id,col_caseeventautoruleparam,col_autoruleparametertask,
                                  col_autoruleparamparamconfig,col_lockeddate,col_tasksystypeautoruleparam,col_paramcode,col_autoruleparamtaskdep,col_modifiedby,col_modifieddate,
                                  col_taskeventautoruleparam,col_issystem,col_createdby,col_lockedby
                           from tbl_autoruleparameter
                           where col_AutoRuleParamSLAAction in 
                           (select col_id from tbl_slaaction where col_SLAActionSLAEvent in
                           (select col_id from tbl_slaevent where col_SLAEventTask in 
                           (select col_id from tbl_task where col_casetask = v_CaseId))));
  /*VV*/                              
  --DATE EVENTS FOR CASE
  insert into tbl_dateeventcc(col_datevalue,col_lockedexpdate,col_customdata,col_owner,col_createddate,col_id,col_dateeventccdateevent,col_performedby,col_dateeventcccasecc,col_lockeddate,col_datename,col_modifiedby,
                              col_dateeventccppl_workbasket,col_dateeventcc_dateeventtype,col_modifieddate,col_dateeventccppl_caseworker,col_dateeventcctaskcc,col_createdby,col_lockedby)
                      (select col_datevalue,col_lockedexpdate,col_customdata,col_owner,col_createddate,col_id,col_id,col_performedby,col_dateeventcase,col_lockeddate,col_datename,col_modifiedby,
                              col_dateeventppl_workbasket,col_dateevent_dateeventtype,col_modifieddate,col_dateeventppl_caseworker,col_dateeventtask,col_createdby,col_lockedby
                        from tbl_dateevent
                        where col_dateeventcase = v_CaseId);
end;