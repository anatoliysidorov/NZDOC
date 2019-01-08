/*
guys! please do not modify a text formatting
      please add a new columns to the end
*/
DECLARE
    v_CaseId  INTEGER;
    v_result  NUMBER;
    v_result2 NUMBER;
BEGIN
    v_CaseId := CaseId;
    
    /*---------------------------------------------------------------------------------------------------*/
    
    /*--Update existing data*/
    
    /*--CASE WORKITEMS*/
    FOR rec IN(SELECT cwi.col_id, cwi.col_activity, cwi.col_createdby, cwi.col_createddate,
                      cwi.col_holdexpdate, cwi.col_holdsetdate, cwi.col_instanceid,
                      cwi.col_instancetype, cwi.col_isonhold, cwi.col_lockedby,
                      cwi.col_lockeddate, cwi.col_lockedexpdate, cwi.col_modifiedby,
                      cwi.col_modifieddate, cwi.col_notes, cwi.col_owner,
                      cwi.col_prevactivity, cwi.col_prevactivityname, cwi.col_prevsubject,
                      cwi.col_prevsubjectname, cwi.col_receiveddate, cwi.col_refparentid,
                      cwi.col_subject, cwi.col_workflow, cwi.col_cw_workitemcccw_workitem,
                      cwi.col_cw_workitemccdict_casest, cwi.col_cw_workitemccprevcasest,
                      cwi.col_MilestoneActivity, cwi.col_PrevMSActivity,
                      cwi.col_CWICCDICT_State, cwi.col_PrevCWICCDICT_State
    FROM   TBL_CW_WORKITEMCC cwi
    WHERE  cwi.col_id =(
           SELECT col_cw_workitemcccasecc
           FROM   tbl_casecc
           WHERE  col_id = v_CaseId
           )
    )
    LOOP
        UPDATE TBL_CW_WORKITEM
        SET    col_activity = rec.col_activity,
               col_holdexpdate = rec.col_holdexpdate,
               col_holdsetdate = rec.col_holdsetdate,
               col_instanceid = rec.col_instanceid,
               col_instancetype = rec.col_instancetype,
               col_isonhold = rec.col_isonhold,
               col_notes = rec.col_notes,
               col_owner = rec.col_owner,
               col_prevactivity = rec.col_prevactivity,
               col_prevactivityname = rec.col_prevactivityname,
               col_prevsubject = rec.col_prevsubject,
               col_prevsubjectname = rec.col_prevsubjectname,
               col_receiveddate = rec.col_receiveddate,
               col_refparentid = rec.col_refparentid,
               col_subject = rec.col_subject,
               col_workflow = rec. col_workflow,
               col_cw_workitemcw_workitemcc = rec.col_id,
               col_cw_workitemdict_casestate = rec.col_cw_workitemccdict_casest,
               col_cw_workitemprevcasestate = rec.col_cw_workitemccprevcasest,
               col_MilestoneActivity = rec.col_MilestoneActivity,
               col_PrevMSActivity = rec.col_PrevMSActivity,
               col_PrevCWIDICT_State = rec.col_PrevCWICCDICT_State,
               col_CWIDICT_State = rec.col_CWICCDICT_State
        WHERE  col_id = rec.col_cw_workitemcccw_workitem;
    
    END LOOP;
    
    
    /*--CASE*/
    FOR rec IN(SELECT cs.col_id, cs.col_activity, cs.col_casefrom, cs.col_caseid,
                      cs.col_createdby, cs.col_createddate, cs.col_customdata,
                      cs.col_dateassigned, cs.col_dateclosed, cs.col_description,
                      cs.col_draft, cs.col_extsysid, cs.col_lockedby,
                      cs.col_lockeddate, cs.col_lockedexpdate, cs.col_manualdateresolved,
                      cs.col_manualworkduration, cs.col_modifiedby, cs.col_modifieddate,
                      cs.col_owner, cs.col_processorname, cs.col_resolutiondescription,
                      cs.col_resolveby, cs.col_statupdated, cs.col_summary,
                      cs.col_workflow, cs.col_cw_workitemcccasecc, cs.col_casecccase,
                      cs.col_caseccdict_casestate, cs.col_caseccdict_casesystype,
                      cs.col_caseccppl_workbasket, cs.col_defaultcaseccdocfoldercc,
                      cs.col_dfltmailcaseccdocfoldercc, cs.col_dfltprntcaseccdocfoldercc,
                      cs.col_procedurecasecc, cs.col_stp_prioritycasecc,
                      cs.col_stp_resolutioncodecasecc, cs.col_int_integtargetcasecc,
                      cs.COL_MILESTONEACTIVITY,  cs.COL_CaseCCDICT_State,
                      cs.COL_PrevMSActivity, cs.COL_PrevCaseCCDICT_State,
                      cs.COL_GOALSLADATETIME, cs.COL_DLINESLADATETIME, cs.COL_DATEEVENTVALUE
    FROM   TBL_CASECC cs
    WHERE  cs.col_id = v_CaseId
    )
    LOOP
        UPDATE TBL_CASE
        SET    col_activity = rec.col_activity,
               col_casefrom = rec.col_casefrom,
               col_caseid = rec.col_caseid,
               col_dateassigned = rec.col_dateassigned,
               col_dateclosed = rec.col_dateclosed,
               col_draft = rec.col_draft,
               col_extsysid = rec.col_extsysid,
               col_manualdateresolved = rec.col_manualdateresolved,
               col_manualworkduration = rec.col_manualworkduration,
               col_owner = rec.col_owner,
               col_processorname = rec.col_processorname,
               col_resolveby = rec.col_resolveby,
               col_statupdated = rec.col_statupdated,
               col_summary = rec.col_summary,
               col_workflow = rec.col_workflow,
               col_cw_workitemcase = rec.col_cw_workitemcccasecc,
               col_casecasecc = rec.col_id,
               col_casedict_casestate = rec.col_caseccdict_casestate,
               col_casedict_casesystype = rec.col_caseccdict_casesystype,
               col_caseppl_workbasket = rec.col_caseccppl_workbasket,
               col_defaultcasedocfolder = rec.col_defaultcaseccdocfoldercc,
               col_defaultmailcasedocfolder = rec.col_dfltmailcaseccdocfoldercc,
               col_defaultprtlcasedocfolder = rec.col_dfltprntcaseccdocfoldercc,
               col_int_integtargetcase = rec.col_int_integtargetcasecc,
               col_procedurecase = rec.col_procedurecasecc,
               col_stp_prioritycase = rec.col_stp_prioritycasecc,
               col_stp_resolutioncodecase = rec.col_stp_resolutioncodecasecc,
               COL_MILESTONEACTIVITY = rec.COL_MILESTONEACTIVITY,
               COL_CASEDICT_STATE = rec.COL_CaseCCDICT_State,
               COL_PrevMSActivity= rec.COL_PrevMSActivity, 
               COl_PrevCaseDICT_State=rec.COL_PrevCaseCCDICT_State,
               COL_GOALSLADATETIME = rec.COL_GOALSLADATETIME,
               COL_DLINESLADATETIME = rec.COL_DLINESLADATETIME,
               COL_DATEEVENTVALUE = rec.COL_DATEEVENTVALUE
        WHERE  coL_id = rec.col_casecccase;
    
    END LOOP;
    
    
    /*-- CASE STATE INITIATION*/
    FOR rec IN(
    SELECT mcst.col_id,
           mcst.col_assignprocessorcode,
           mcst.col_code,
           mcst.col_createdby,
           mcst.col_createddate,
           mcst.col_id2,
           mcst.col_lockedby,
           mcst.col_lockeddate,
           mcst.col_lockedexpdate,
           mcst.col_modifiedby,
           mcst.col_modifieddate,
           mcst.col_owner,
           mcst.col_processorcode,
           mcst.col_casestinitcccasestinit,
           mcst.col_casestateinitcc_casetype,
           mcst.col_casestateinitcc_initmtd,
           mcst.col_map_casestateinitcccasecc,
           mcst.col_map_csstinitcc_csst,
           mcst.col_map_csstateinitcctasktmpl
    FROM   TBL_MAP_CASESTATEINITCC mcst
    WHERE  mcst.col_id IN(
           SELECT col_id
           FROM   tbl_map_casestateinitiation
           WHERE  col_map_casestateinitcase = v_CaseId
           )
    )
    LOOP
        UPDATE TBL_MAP_CASESTATEINITIATION
        SET    col_assignprocessorcode = rec.col_assignprocessorcode,
               col_code = rec.col_code,
               col_id2 = rec.col_id2,
               col_owner = rec.col_owner,
               col_processorcode = rec.col_processorcode,
               col_casestinitcasestinitcc = rec.col_id,
               col_casestateinit_casesystype = rec.col_casestateinitcc_casetype,
               col_casestateinit_initmethod = rec.col_casestateinitcc_initmtd,
               col_map_casestateinitcase = rec.col_map_casestateinitcccasecc,
               col_map_csstinit_csst = rec.col_map_csstinitcc_csst,
               col_map_casestateinittasktmpl = rec.col_map_csstateinitcctasktmpl
        WHERE  col_id = rec.col_casestinitcccasestinit;
    
    END LOOP;
    
    
    /*--CASE DEPENDENCIES*/
    FOR rec IN(
    SELECT cd.col_id,
           cd.col_code,
           cd.col_createdby,
           cd.col_createddate,
           cd.col_lockedby,
           cd.col_lockeddate,
           cd.col_lockedexpdate,
           cd.col_modifiedby,
           cd.col_modifieddate,
           cd.col_owner,
           cd.col_processorcode,
           cd.col_type,
           cd.col_casedepcccasedep,
           cd.col_casedpchldcccasestinitcc,
           cd.col_casedpchldcctaskstinitcc,
           cd.col_casedpprntcccasestinitcc,
           cd.col_casedpprntcctaskstinitcc,
           cd.col_casedepccglobalevent
    FROM   TBL_CASEDEPENDENCYCC cd
    WHERE  cd.col_id IN(
           SELECT col_id
           FROM   tbl_casedependency
           WHERE (
                  col_casedpndchldcasestateinit IN(
                  SELECT col_id
                  FROM   tbl_map_casestateinitiation
                  WHERE  col_map_casestateinitcase = v_CaseId
                  )
                  )
                  AND
                  (
                  col_casedpndprntcasestateinit IN(
                  SELECT col_id
                  FROM   tbl_map_casestateinitiation
                  WHERE  col_map_casestateinitcase = v_CaseId
                  )
                  )
           )
    )
    LOOP
        UPDATE TBL_CASEDEPENDENCY
        SET    col_code = rec.col_code,
               col_owner = rec.col_owner,
               col_processorcode = rec.col_processorcode,
               col_type = rec.col_type,
               col_casedepcasedepcc = rec.col_id,
               col_casedependencyglobalevent = rec.col_casedepccglobalevent,
               col_casedpndchldcasestateinit = rec.col_casedpchldcccasestinitcc,
               col_casedpndchldtaskstateinit = rec.col_casedpchldcctaskstinitcc,
               col_casedpndprntcasestateinit = rec.col_casedpprntcccasestinitcc,
               col_casedpndprnttaskstateinit = rec.col_casedpprntcctaskstinitcc
        WHERE  col_id = rec.col_casedepcccasedep;
    
    END LOOP;
    
    
    /*--CASE EVENTS*/
    FOR rec IN(
    SELECT ce.col_id,
           ce.col_caseeventorder,
           ce.col_code,
           ce.col_createdby,
           ce.col_createddate,
           ce.col_lockedby,
           ce.col_lockeddate,
           ce.col_lockedexpdate,
           ce.col_modifiedby,
           ce.col_modifieddate,
           ce.col_owner,
           ce.col_processorcode,
           ce.col_caseeventcccaseevent,
           ce.col_caseeventcccasestinitcc,
           ce.col_taskeventmomntcaseeventcc,
           ce.col_taskeventsnctpcaseeventcc,
           ce.col_taskeventtypecaseeventcc
    FROM   TBL_CASEEVENTCC ce
    WHERE  ce.col_id IN(
           SELECT col_id
           FROM   tbl_caseevent
           WHERE  col_caseeventcasestateinit IN(
                  SELECT col_id
                  FROM   tbl_map_casestateinitiation
                  WHERE  col_map_casestateinitcase = v_CaseId
                  )
           )
    )
    LOOP
        UPDATE TBL_CASEEVENT
        SET    col_caseeventorder = rec.col_caseeventorder,
               col_code = rec.col_code,
               col_owner = rec.col_owner,
               col_processorcode = rec.col_processorcode,
               col_caseeventcaseeventcc = rec.col_id,
               col_caseeventcasestateinit = rec.col_caseeventcccasestinitcc,
               col_taskeventmomentcaseevent = rec.col_taskeventmomntcaseeventcc,
               col_taskeventtypecaseevent = rec.col_taskeventsnctpcaseeventcc,
               col_tskeventsynctypecaseevent = rec.col_taskeventtypecaseeventcc
        WHERE  col_id = rec.col_caseeventcccaseevent;
    
    END LOOP;
    
    
    /*--AUTO RULE PARAMETERS*/
    FOR rec IN(
    SELECT arp.col_id,
           arp.col_code,
           arp.col_createdby,
           arp.col_createddate,
           arp.col_issystem,
           arp.col_lockedby,
           arp.col_lockeddate,
           arp.col_lockedexpdate,
           arp.col_modifiedby,
           arp.col_modifieddate,
           arp.col_owner,
           arp.col_paramcode,
           arp.col_paramvalue,
           arp.col_autoruleparccautorulepar,
           arp.col_autoruleparccslaactioncc,
           arp.col_autoruleparamcccasedepcc,
           arp.col_autoruleparamcccasetype,
           arp.col_autoruleparamccparamconf,
           arp.col_autoruleparamcctaskcc,
           arp.col_autoruleparamcctaskdepcc,
           arp.col_caseeventccautoruleparcc,
           arp.col_ruleparcc_casestateinitcc,
           arp.col_ruleparcc_taskstateinitcc,
           arp.col_taskeventccautoruleparmcc,
           arp.col_tasksystypeautoruleparcc,
           arp.col_tasktemplateautoruleparcc,
           arp.col_ActionAutoRuleParCC,
           arp.col_AutoRulePrmCCCommonEvent,
           arp.col_AutoRulePrmCCDynamicTask
    FROM   TBL_AUTORULEPARAMCC arp
    WHERE  arp.col_id IN(
           /*--AUTO RULE PARAMETERS FOR CASE EVENTS*/
           (
           SELECT col_id
           FROM   tbl_autoruleparameter
           WHERE  col_caseeventautoruleparam IN(
                  SELECT col_id
                  FROM   tbl_caseevent
                  WHERE  col_caseeventcasestateinit IN(
                         SELECT col_id
                         FROM   tbl_map_casestateinitiation
                         WHERE  col_map_casestateinitcase = v_CaseId
                         )
                  )
           )
    
    UNION
          
          /*--SELECT ALL RULE PARAMETERS RELATED TO CASE STATE INITIATION*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_ruleparam_casestateinit IN(
                 SELECT col_id
                 FROM   tbl_map_casestateinitiation
                 WHERE  col_map_casestateinitcase = v_CaseId
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_ruleparam_taskstateinit IN(
                 SELECT col_id
                 FROM   tbl_map_taskstateinitiation
                 WHERE  col_map_taskstateinittask IN(
                        SELECT col_id
                        FROM   tbl_task
                        WHERE  col_casetask = v_CaseId
                        )
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULEPARAMETERS FOR TASK EVENTS*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_taskeventautoruleparam IN(
                 SELECT col_id
                 FROM   tbl_taskevent
                 WHERE  col_taskeventtaskstateinit IN(
                        SELECT col_id
                        FROM   tbl_map_taskstateinitiation
                        WHERE  col_map_taskstateinittask IN(
                               SELECT col_id
                               FROM   tbl_task
                               WHERE  col_casetask = v_CaseId
                               )
                        )
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_autoruleparametertask IN(
                 SELECT col_id
                 FROM   tbl_task
                 WHERE  col_casetask = v_CaseId
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULEPARAMETERS FOR TASK DEPENDENCIES*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_autoruleparamtaskdep IN(
                 SELECT col_id
                 FROM   tbl_taskdependency
                 WHERE  col_tskdpndprnttskstateinit IN(
                        SELECT col_id
                        FROM   tbl_map_taskstateinitiation
                        WHERE  col_map_taskstateinittask IN(
                               SELECT col_id
                               FROM   tbl_task
                               WHERE  col_casetask = v_CaseId
                               )
                        )
                        AND
                        col_tskdpndchldtskstateinit IN(
                        SELECT col_id
                        FROM   tbl_map_taskstateinitiation
                        WHERE  col_map_taskstateinittask IN(
                               SELECT col_id
                               FROM   tbl_task
                               WHERE  col_casetask = v_CaseId
                               )
                        )
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULE PARAMETERS RELATED TO SLA ACTIONS*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_AutoRuleParamSLAAction IN(
                 SELECT col_id
                 FROM   tbl_slaaction
                 WHERE  col_SLAActionSLAEvent IN(
                        SELECT col_id
                        FROM   tbl_slaevent
                        WHERE  col_SLAEventTask IN(
                               SELECT col_id
                               FROM   tbl_task
                               WHERE  col_casetask = v_CaseId
                               )
                        )
                 )
          ))
    )
    LOOP
        UPDATE TBL_AUTORULEPARAMETER
        SET    col_code = rec.col_code,
               col_issystem = rec.col_issystem,
               col_owner = rec.col_owner,
               col_paramcode = rec.col_paramcode,
               col_paramvalue = rec.col_paramvalue,
               col_actionautoruleparameter = rec.col_actionautoruleparcc,
               col_autoruleparautoruleparcc = rec.col_id,
               col_autoruleparamcasedep = rec.col_autoruleparamcccasedepcc,
               col_autoruleparamcasesystype = rec.col_autoruleparamcccasetype,
               col_autoruleparamcommonevent = rec.col_autoruleprmcccommonevent,
               col_autoruleparamdynamictask = rec.col_autoruleprmccdynamictask,
               col_autoruleparamparamconfig = rec.col_autoruleparamccparamconf,
               col_autoruleparamslaaction = rec.col_autoruleparccslaactioncc,
               col_autoruleparamtaskdep = rec.col_autoruleparamcctaskdepcc,
               col_autoruleparametertask = rec.col_autoruleparamcctaskcc,
               col_caseeventautoruleparam = rec.col_caseeventccautoruleparcc,
               col_ruleparam_casestateinit = rec.col_ruleparcc_casestateinitcc,
               col_ruleparam_taskstateinit = rec.col_ruleparcc_taskstateinitcc,
               col_ttautoruleparameter = rec.col_tasktemplateautoruleparcc,
               /*--???*/
               col_taskeventautoruleparam = rec.col_taskeventccautoruleparmcc,
               col_tasksystypeautoruleparam = rec.col_tasksystypeautoruleparcc
        WHERE  col_id = rec.col_autoruleparccautorulepar;
    
    END LOOP;
    
    
    /*--HISTORY*/
    FOR rec IN(
    SELECT h.col_id,
           h.col_activitytimedate,
           h.col_additionalinfo,
           h.col_createdby,
           h.col_createdbyname,
           h.col_createddate,
           h.col_description,
           h.col_historycreatedby,
           h.col_issystem,
           h.col_lockedby,
           h.col_lockeddate,
           h.col_lockedexpdate,
           h.col_modifiedby,
           h.col_modifieddate,
           h.col_owner,
           h.col_historycccasecc,
           h.col_historycchistory,
           h.col_historyccnextcasestate,
           h.col_historyccnexttaskstate,
           h.col_historyccprevcasestate,
           h.col_historyccprevtaskstate,
           h.col_historycctaskcc,
           h.col_messagetypehistorycc,
           h.col_HistCCDynamicTask
    FROM   TBL_HISTORYCC h
    WHERE  h.col_id IN(
           /*--HISTORY FOR CASE*/
           (
           SELECT col_id
           FROM   tbl_history
           WHERE  col_historycase = v_CaseId
           )
    
    UNION
          /*--HISTORY FOR TASKS IN CASE*/
          (
          SELECT col_id
          FROM   tbl_history
          WHERE  col_historytask IN(
                 SELECT col_id
                 FROM   tbl_task
                 WHERE  col_casetask = v_CaseId
                 )
          ))
    )
    LOOP
        UPDATE TBL_HISTORY
        SET    col_activitytimedate = rec.col_activitytimedate,
               col_additionalinfo = rec.col_additionalinfo,
               col_createdbyname = rec.col_createdbyname,
               col_description = rec.col_description,
               col_historycreatedby = rec.col_historycreatedby,
               col_issystem = rec.col_issystem,
               col_owner = rec.col_owner,
               col_historycase = rec.col_historycccasecc,
               col_historydynamictask = rec.col_histccdynamictask,
               col_historyhistorycc = rec.col_id,
               col_historynextcasestate = rec.col_historyccnextcasestate,
               col_historynexttaskstate = rec.col_historyccnexttaskstate,
               col_historyprevcasestate = rec.col_historyccprevcasestate,
               col_historyprevtaskstate = rec.col_historyccprevtaskstate,
               col_historytask = rec.col_historycctaskcc,
               col_messagetypehistory = rec.col_messagetypehistorycc
        WHERE  col_id = rec.col_historycchistory;
    
    END LOOP;
    
    
    /*--DATE EVENTS*/
    FOR rec IN(
    SELECT dte.col_id,
           dte.col_createdby,
           dte.col_createddate,
           dte.col_customdata,
           dte.col_datename,
           dte.col_datevalue,
           dte.col_lockedby,
           dte.col_lockeddate,
           dte.col_lockedexpdate,
           dte.col_modifiedby,
           dte.col_modifieddate,
           dte.col_owner,
           dte.col_performedby,
           dte.col_dateeventcccasecc,
           dte.col_dateeventccdateevent,
           dte.col_dateeventccppl_caseworker,
           dte.col_dateeventccppl_workbasket,
           dte.col_dateeventcctaskcc,
           dte.col_dateeventcc_dateeventtype,
           dte.COL_DateEventCCDICT_State
    FROM   TBL_DATEEVENTCC dte
    WHERE  dte.col_id IN(
           /*--DATE EVENTS FOR CASE*/
           (
           SELECT col_id
           FROM   tbl_dateevent
           WHERE  col_dateeventcase = v_CaseId
           )

           UNION

          /*--DATE EVENTS FOR TASKS IN CASE*/
          (
          SELECT col_id
          FROM   tbl_dateevent
          WHERE  col_dateeventtask IN(
                 SELECT col_id
                 FROM   tbl_task
                 WHERE  col_casetask = v_CaseId
                 )
          ))
    
    )
    LOOP
        UPDATE TBL_DATEEVENT
        SET    col_customdata = rec.col_customdata,
               col_datename = rec.col_datename,
               col_datevalue = rec.col_datevalue,
               col_owner = rec.col_owner,
               col_performedby = rec.col_performedby,
               col_dateeventcase = rec.col_dateeventcccasecc,
               col_dateeventdateeventcc = rec.col_id,
               col_dateeventppl_caseworker = rec.col_dateeventccppl_caseworker,
               col_dateeventppl_workbasket = rec.col_dateeventccppl_workbasket,
               col_dateeventtask = rec.col_dateeventcctaskcc,
               col_dateevent_dateeventtype = rec.col_dateeventcc_dateeventtype,
               COL_DATEEVENTDICT_STATE=rec.COL_DateEventCCDICT_State
        WHERE  col_id = rec.col_dateeventccdateevent;
    
    END LOOP;
    
       
    /*--TASKS*/
    FOR rec IN(
    SELECT tsk.col_id,
           tsk.col_createdby,
           tsk.col_createddate,
           tsk.col_customdata,
           tsk.col_dateassigned,
           tsk.col_dateclosed,
           tsk.col_datestarted,
           tsk.col_depth,
           tsk.col_description,
           tsk.col_draft,
           tsk.col_enabled,
           tsk.col_extsysid,
           tsk.col_hoursworked,
           tsk.col_icon,
           tsk.col_iconcls,
           tsk.col_id2,
           tsk.col_parentid2,
           tsk.col_leaf,
           tsk.col_lockedby,
           tsk.col_lockeddate,
           tsk.col_lockedexpdate,
           tsk.col_manualdateresolved,
           tsk.col_manualworkduration,
           tsk.col_modifiedby,
           tsk.col_modifieddate,
           tsk.col_name,
           tsk.col_owner,
           tsk.col_pagecode,
           tsk.col_perccomplete,
           tsk.col_processorname,
           tsk.col_required,
           tsk.col_resolutiondescription,
           tsk.col_statupdated,
           tsk.col_status,
           tsk.col_systemtype,
           tsk.col_systemtype2,
           tsk.col_taskid,
           tsk.col_taskorder,
           tsk.col_transactionid,
           tsk.col_type,
           tsk.COL_CASECCTASKCC,
           tsk.col_parentidcc,
           tsk.col_tw_workitemcctaskcc,
           tsk.col_taskccdict_customword,
           tsk.col_taskccdict_executionmtd,
           tsk.col_taskccdict_tasksystype,
           tsk.col_taskccppl_workbasket,
           tsk.col_taskccpreviousworkbasket,
           tsk.col_taskccprocedure,
           tsk.col_taskccresolcode_param,
           tsk.col_taskccstp_resolutioncode,
           tsk.col_taskcctask,
           tsk.col_taskccworkbasket_param,
           tsk.col_INT_IntegTargetTaskCC,
           tsk.col_TaskCCDICT_TaskState,
           tsk.col_PrevTaskCCDICT_TaskState,
           tsk.col_goalslaeventdate,
           tsk.col_dlineslaeventdate,
           tsk.COL_ISHIDDEN
    FROM   tbl_taskcc tsk
    WHERE  tsk.COL_id IN(
           SELECT col_id
           FROM   tbl_task
           WHERE  col_casetask = v_CaseId
           )
    )
    LOOP
        UPDATE tbl_task
        SET    col_customdata = rec.col_customdata,
               col_dateassigned = rec.col_dateassigned,
               col_dateclosed = rec.col_dateclosed,
               col_datestarted = rec.col_datestarted,
               col_depth = rec.col_depth,
               col_description = rec.col_description,
               col_draft = rec.col_draft,
               col_enabled = rec.col_enabled,
               col_extsysid = rec.col_extsysid,
               col_hoursworked = rec.col_hoursworked,
               col_icon = rec.col_icon,
               col_iconcls = rec.col_iconcls,
               col_id2 = rec.col_id2,
              col_parentid2 = rec.col_parentid2,
               col_leaf = rec.col_leaf,
               col_manualdateresolved = rec.col_manualdateresolved,
               col_manualworkduration = rec.col_manualworkduration,
               col_name = rec.col_name,
               col_owner = rec.col_owner,
               col_pagecode = rec.col_pagecode,
               col_perccomplete = rec.col_perccomplete,
               col_processorname = rec.col_processorname,
               col_required = rec.col_required,
               col_resolutiondescription = rec.col_resolutiondescription,
               col_statupdated = rec.col_statupdated,
               col_status = rec.col_status,
               /*--col_systemtype = rec.col_systemtype,*/
               col_systemtype2 = rec.col_systemtype2,
               col_taskid = rec.col_taskid,
               col_taskorder = rec.col_taskorder,
               col_transactionid = rec.col_transactionid,
               col_type = rec.col_type,
               col_casetask = rec.COL_CASECCTASKCC,
               col_int_integtargettask = rec.col_int_integtargettaskcc,
               col_parentid = rec.col_parentidcc,
               col_tw_workitemtask = rec.col_tw_workitemcctaskcc,
               col_taskdict_customword = rec.col_taskccdict_customword,
               col_taskdict_executionmethod = rec.col_taskccdict_executionmtd,
               col_taskdict_tasksystype = rec.col_taskccdict_tasksystype,
               col_taskppl_workbasket = rec.col_taskccppl_workbasket,
               col_taskpreviousworkbasket = rec.col_taskccpreviousworkbasket,
               col_taskprocedure = rec.col_taskccprocedure,
               col_taskresolutioncode_param = rec.col_taskccresolcode_param,
               col_taskstp_resolutioncode = rec.col_taskccstp_resolutioncode,
               col_tasktaskcc = rec.col_id,
               col_taskworkbasket_param = rec.col_taskccworkbasket_param,
               col_TaskDICT_TaskState = rec.col_TaskCCDICT_TaskState,
               col_PrevTaskDICT_TaskState = rec.col_PrevTaskCCDICT_TaskState,
               col_goalslaeventdate = rec.col_goalslaeventdate,
               col_dlineslaeventdate = rec.col_dlineslaeventdate,
               COL_ISHIDDEN=rec.COL_ISHIDDEN
        WHERE  col_id = rec.col_taskcctask;
    
    END LOOP;
    
    
    /*--TASK WORKITEMS*/
    FOR rec IN(
    SELECT twi.col_id,
           twi.col_activity,
           twi.col_createdby,
           twi.col_createddate,
           twi.col_holdexpdate,
           twi.col_holdsetdate,
           twi.col_instanceid,
           twi.col_instancetype,
           twi.col_isonhold,
           twi.col_lockedby,
           twi.col_lockeddate,
           twi.col_lockedexpdate,
           twi.col_modifiedby,
           twi.col_modifieddate,
           twi.col_notes,
           twi.col_owner,
           twi.col_prevactivity,
           twi.col_prevactivityname,
           twi.col_prevsubject,
           twi.col_prevsubjectname,
           twi.col_receiveddate,
           twi.col_refparentid,
           twi.col_subject,
           twi.col_workflow,
           twi.col_tw_workitemccdict_taskst,
           twi.col_tw_workitemccprevtaskst,
           twi.col_tw_workitemcctw_workitem
    FROM   TBL_TW_WORKITEMCC twi
    WHERE  twi.col_id IN(
           SELECT col_id
           FROM   tbl_tw_workitem
           WHERE  col_id IN(
                  SELECT col_tw_workitemtask
                  FROM   tbl_task
                  WHERE  col_casetask = v_CaseId
                  )
           )
    )
    LOOP
        UPDATE TBL_TW_WORKITEM
        SET    col_activity = rec.col_activity,
               col_holdexpdate = rec.col_holdexpdate,
               col_holdsetdate = rec.col_holdsetdate,
               col_instanceid = rec.col_instanceid,
               col_instancetype = rec.col_instancetype,
               col_isonhold = rec.col_isonhold,
               col_notes = rec.col_notes,
               col_owner = rec.col_owner,
               col_prevactivity = rec.col_prevactivity,
               col_prevactivityname = rec.col_prevactivityname,
               col_prevsubject = rec.col_prevsubject,
               col_prevsubjectname = rec.col_prevsubjectname,
               col_receiveddate = rec.col_receiveddate,
               col_refparentid = rec.col_refparentid,
               col_subject = rec.col_subject,
               col_workflow = rec.col_workflow,
               col_tw_workitemdict_taskstate = rec.col_tw_workitemccdict_taskst,
               col_tw_workitemprevtaskstate = rec.col_tw_workitemccprevtaskst,
               col_tw_workitemtw_workitemcc = rec.col_id
        WHERE  col_id = rec.col_tw_workitemcctw_workitem;
    
    END LOOP;
    
    
    
    /*--SLA EVENTS*/
    FOR rec IN(
    SELECT sla.col_id,
           sla.col_isrequired,
           sla.col_slaeventorder,
           sla.col_maxattempts,
           sla.col_id2,
           sla.col_attemptcount,
           sla.col_owner,
           sla.col_modifiedby,
           sla.col_lockedby,
           sla.col_intervalym,
           sla.col_intervalds,
           sla.col_createdby,
           sla.col_code,
           sla.col_modifieddate,
           sla.col_lockedexpdate,
           sla.col_lockeddate,
           sla.col_createddate,
           sla.col_slaeventcccasecc,
           sla.col_slaeventcctaskcc,
           sla.col_slaeventccslaevent,
           sla.col_slaeventcctasktemplate,
           sla.col_slaeventcc_dateeventtype,
           sla.col_slaeventcc_slaeventlevel,
           sla.col_slaeventcc_slaeventtype,
           sla.col_slaeventcc_tasksystype,
           sla.col_SLAEvtCCDynamicTask,
           sla.COL_FINISHDATEEVENTVALUE,
           sla.COL_SLAEVENTDATE,
           sla.COL_STARTDATEEVENTBY,
           sla.COL_STARTDATEEVENTVALUE           
    FROM   TBL_SLAEVENTCC sla
    WHERE  sla.col_id IN(
           SELECT col_id
           FROM   tbl_slaevent
           WHERE  col_slaeventtask IN(
                  SELECT col_id
                  FROM   tbl_task
                  WHERE  col_casetask = v_CaseId
                  )
           )
    )
    LOOP
        UPDATE TBL_SLAEVENT
        SET    col_owner = rec.col_owner,
               col_slaeventcase = rec.col_slaeventcccasecc,
               col_slaeventdict_slaeventtype = rec.col_slaeventcc_slaeventtype,
               col_slaeventtask = rec.col_slaeventcctaskcc,
               col_slaevent_dateeventtype = rec.col_slaeventcc_dateeventtype,
               col_slaevent_slaeventlevel = rec.col_slaeventcc_slaeventlevel,
               col_slaeventtasktemplate = rec.col_slaeventcctasktemplate,
               col_attemptcount = rec.col_attemptcount,
               col_maxattempts = rec.col_maxattempts,
               col_slaeventdict_tasksystype = rec.col_slaeventcc_tasksystype,
               col_isrequired = rec.col_isrequired,
               col_intervalds = rec.col_intervalds,
               col_intervalym = rec.col_intervalym,
               col_slaeventdynamictask = rec.col_slaevtccdynamictask,
               col_code = rec.col_code,
               col_slaeventorder = rec.col_slaeventorder,
               col_id2 = rec.col_id2,
               col_slaeventslaeventcc = rec.col_id,
               COL_FINISHDATEEVENTVALUE =rec.COL_FINISHDATEEVENTVALUE,
               COL_SLAEVENTDATE = rec.COL_SLAEVENTDATE,
               COL_STARTDATEEVENTBY=rec.COL_STARTDATEEVENTBY,
               COL_STARTDATEEVENTVALUE=rec.COL_STARTDATEEVENTVALUE
        WHERE  col_id = rec.col_slaeventccslaevent;
    
    END LOOP;
    
    
    /*--SLA ACTIONS*/
    FOR rec IN(
    SELECT sla.col_id,
           sla.col_processorcode,
           sla.col_owner,
           sla.col_name,
           sla.col_modifiedby,
           sla.col_lockedby,
           sla.col_createdby,
           sla.col_code,
           sla.col_modifieddate,
           sla.col_lockedexpdate,
           sla.col_lockeddate,
           sla.col_createddate,
           sla.col_actionorder,
           sla.col_description,
           sla.col_slaactionccslaeventcc,
           sla.col_slaactionccslaaction,
           sla.col_slaactioncc_slaeventlevel
    FROM   TBL_SLAACTIONCC sla
    WHERE  sla.col_id IN(
           SELECT col_id
           FROM   tbl_slaaction
           WHERE  col_slaactionslaevent IN(
                  SELECT col_id
                  FROM   tbl_slaevent
                  WHERE  col_slaeventtask IN(
                         SELECT col_id
                         FROM   tbl_task
                         WHERE  col_casetask = v_CaseId
                         )
                  )
           )
    )
    LOOP
        UPDATE TBL_SLAACTION
        SET    col_actionorder = rec.col_actionorder,
               col_code = rec.col_code,
               col_name = rec.col_name,
               col_owner = rec.col_owner,
               col_processorcode = rec.col_processorcode,
               col_slaactionslaevent = rec.col_slaactionccslaeventcc,
               col_slaaction_slaeventlevel = rec.col_slaactioncc_slaeventlevel,
               col_description = rec.col_description,
               col_slaactionslaactioncc = rec.col_id
        WHERE  col_id = rec.col_slaactionccslaaction;
    
    END LOOP;
    
    
    /*--TASK STATE INITIATION*/
    FOR rec IN(
    SELECT tsi.col_id,
           tsi.col_assignprocessorcode,
           tsi.col_code,
           tsi.col_createdby,
           tsi.col_createddate,
           tsi.col_id2,
           tsi.col_lockedby,
           tsi.col_lockeddate,
           tsi.col_lockedexpdate,
           tsi.col_modifiedby,
           tsi.col_modifieddate,
           tsi.col_owner,
           tsi.col_processorcode,
           tsi.col_routedby,
           tsi.col_routeddate,
           tsi.col_map_taskstinitcctasktmpl,
           tsi.col_map_taskstateinitcctaskcc,
           tsi.col_map_tskstinitcc_initmtd,
           tsi.col_map_tskstinitcc_tskst,
           tsi.col_taskstinitcctaskstinit,
           tsi.col_taskstateinitcc_tasktype,
           tsi.col_TaskStInitCCDynamicTask
    FROM   TBL_MAP_TASKSTATEINITCC tsi
    WHERE  tsi.col_id IN(
           SELECT col_id
           FROM   tbl_map_taskstateinitiation
           WHERE  col_map_taskstateinittask IN(
                  SELECT col_id
                  FROM   tbl_task
                  WHERE  col_casetask = v_CaseId
                  )
           )
    )
    LOOP
        UPDATE TBL_MAP_TASKSTATEINITIATION
        SET    col_assignprocessorcode = rec.col_assignprocessorcode,
               col_code = rec.col_code,
               col_id2 = rec.col_id2,
               col_owner = rec.col_owner,
               col_processorcode = rec.col_processorcode,
               col_routedby = rec.col_routedby,
               col_routeddate = rec.col_routeddate,
               col_map_taskstateinittask = rec.col_map_taskstateinitcctaskcc,
               col_map_taskstateinittasktmpl = rec.col_map_taskstinitcctasktmpl,
               col_map_tskstinit_initmtd = rec.col_map_tskstinitcc_initmtd,
               col_map_tskstinit_tskst = rec.col_map_tskstinitcc_tskst,
               col_taskstinittaskstinitcc = rec.col_id,
               col_taskstateinitdynamictask = rec.col_taskstinitccdynamictask,
               col_taskstateinit_tasksystype = rec.col_taskstateinitcc_tasktype
        WHERE  col_id = rec.col_taskstinitcctaskstinit;
    
    END LOOP;
    
    
    /*--TASK DEPENDENCIES*/
    FOR rec IN(
    SELECT td.col_id,
           td.col_code,
           td.col_createdby,
           td.col_createddate,
           td.col_id2,
           td.col_isdefault,
           td.col_lockedby,
           td.col_lockeddate,
           td.col_lockedexpdate,
           td.col_modifiedby,
           td.col_modifieddate,
           td.col_owner,
           td.col_processorcode,
           td.col_taskdependencyorder,
           td.col_type,
           td.col_taskdepcctaskdep,
           td.col_taskdpchldcctaskstinitcc,
           td.col_taskdpprntcctaskstinitcc
    FROM   TBL_TASKDEPENDENCYCC td
    WHERE  td.col_id IN(
           SELECT col_id
           FROM   tbl_taskdependency
           WHERE  col_tskdpndchldtskstateinit IN(
                  SELECT col_id
                  FROM   tbl_map_taskstateinitiation
                  WHERE  col_map_taskstateinittask IN(
                         SELECT col_id
                         FROM   tbl_task
                         WHERE  col_casetask = v_CaseId
                         )
                  )
                  AND
                  col_tskdpndprnttskstateinit IN(
                  SELECT col_id
                  FROM   tbl_map_taskstateinitiation
                  WHERE  col_map_taskstateinittask IN(
                         SELECT col_id
                         FROM   tbl_task
                         WHERE  col_casetask = v_CaseId
                         )
                  )
           )
    )
    LOOP
        UPDATE TBL_TASKDEPENDENCY
        SET    col_code = rec.col_code,
               col_id2 = rec.col_id2,
               col_isdefault = rec.col_isdefault,
               col_owner = rec.col_owner,
               col_processorcode = rec.col_processorcode,
               col_taskdependencyorder = rec.col_taskdependencyorder,
               col_type = rec.col_type,
               col_taskdeptaskdepcc = rec.col_id,
               col_tskdpndchldtskstateinit = rec.col_taskdpchldcctaskstinitcc,
               col_tskdpndprnttskstateinit = rec.col_taskdpprntcctaskstinitcc
        WHERE  col_id = rec.col_taskdepcctaskdep;
    
    END LOOP;
    
    
    /*--TASK EVENTS*/
    FOR rec IN(
    SELECT te.col_id,
           te.col_code,
           te.col_createdby,
           te.col_createddate,
           te.col_id2,
           te.col_lockedby,
           te.col_lockeddate,
           te.col_lockedexpdate,
           te.col_modifiedby,
           te.col_modifieddate,
           te.col_owner,
           te.col_processorcode,
           te.col_taskeventorder,
           te.col_taskeventcctaskevent,
           te.col_taskeventcctaskstinitcc,
           te.col_taskeventmomnttaskeventcc,
           te.col_taskeventsnctptaskeventcc,
           te.col_taskeventtypetaskeventcc
    FROM   TBL_TASKEVENTCC te
    WHERE  te.col_id IN(
           SELECT col_id
           FROM   tbl_taskevent
           WHERE  col_taskeventtaskstateinit IN(
                  SELECT col_id
                  FROM   tbl_map_taskstateinitiation
                  WHERE  col_map_taskstateinittask IN(
                         SELECT col_id
                         FROM   tbl_task
                         WHERE  col_casetask = v_CaseId
                         )
                  )
           )
    )
    LOOP
        UPDATE TBL_TASKEVENT
        SET    col_code = rec.col_code,
               col_id2 = rec.col_id2,
               col_owner = rec.col_owner,
               col_processorcode = rec.col_processorcode,
               col_taskeventorder = rec.col_taskeventorder,
               col_taskeventmomenttaskevent = rec.col_taskeventmomnttaskeventcc,
               col_taskeventtaskeventcc = rec.col_id,
               col_taskeventtaskstateinit = rec.col_taskeventcctaskstinitcc,
               col_taskeventtypetaskevent = rec.col_taskeventtypetaskeventcc,
               col_tskeventsynctypetaskevent = rec.col_taskeventsnctptaskeventcc
        WHERE  col_id = rec.col_taskeventcctaskevent;
    
    END LOOP;
    
    
    /*--CASE WORKITEMS*/
    FOR rec IN(SELECT cwi.col_id, cwi.col_activity, cwi.col_createdby,
                      cwi.col_createddate, cwi.col_holdexpdate, cwi.col_holdsetdate,
                      cwi.col_instanceid, cwi.col_instancetype, cwi.col_isonhold,
                      cwi.col_lockedby, cwi.col_lockeddate, cwi.col_lockedexpdate,
                      cwi.col_modifiedby, cwi.col_modifieddate, cwi.col_notes,
                      cwi.col_owner, cwi.col_prevactivity, cwi.col_prevactivityname,
                      cwi.col_prevsubject, cwi.col_prevsubjectname, cwi.col_receiveddate,
                      cwi.col_refparentid, cwi.col_subject, cwi.col_workflow,
                      cwi.col_cw_workitemcccw_workitem, cwi.col_cw_workitemccdict_casest,
                      cwi.col_cw_workitemccprevcasest,
                      cwi.col_MilestoneActivity, cwi.col_PrevMSActivity,
                      cwi.col_CWICCDICT_State, cwi.col_PrevCWICCDICT_State                      
    FROM   TBL_CW_WORKITEMCC cwi
    WHERE  cwi.col_cw_workitemcccw_workitem IS NULL
           AND
           cwi.col_id NOT IN(
           SELECT col_cw_workitemcase
           FROM   TBL_CASE
           WHERE  col_id = v_CaseId
           )
    )
    LOOP
      INSERT INTO TBL_CW_WORKITEM(col_id, col_activity, col_instanceid,
                                  col_instancetype, col_isonhold, col_notes,
                                  col_owner, col_prevactivity, col_prevactivityname,
                                  col_prevsubject, col_prevsubjectname,
                                  col_receiveddate, col_refparentid,
                                  col_subject, col_workflow,
                                  col_cw_workitemcw_workitemcc,
                                  col_cw_workitemdict_casestate,
                                  col_cw_workitemprevcasestate,
                                  col_MilestoneActivity, col_PrevMSActivity,
                                  col_CWIDICT_State, col_PrevCWIDICT_State)
                           VALUES(rec.col_id, rec.col_activity, rec.col_instanceid,
                                  rec.col_instancetype, rec.col_isonhold, rec.col_notes,
                                  rec.col_owner, rec.col_prevactivity, rec.col_prevactivityname,
                                  rec.col_prevsubject, rec.col_prevsubjectname,
                                  rec.col_receiveddate, rec.col_refparentid,
                                  rec.col_subject,rec. col_workflow,
                                  rec.col_id,
                                  rec.col_cw_workitemccdict_casest,
                                  rec.col_cw_workitemccprevcasest,
                                  rec.col_MilestoneActivity, rec.col_PrevMSActivity,
                                  rec.col_CWICCDICT_State, rec.col_PrevCWICCDICT_State);
      
      UPDATE TBL_CW_WORKITEMCC
      SET    col_cw_workitemcccw_workitem = rec.col_id
      WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--CASE*/
    FOR rec IN(SELECT cs.col_id, cs.col_activity, cs.col_casefrom, cs.col_caseid,
                      cs.col_createdby, cs.col_createddate, cs.col_customdata,
                      cs.col_dateassigned, cs.col_dateclosed, cs.col_description,
                      cs.col_draft, cs.col_extsysid, cs.col_lockedby, cs.col_lockeddate,
                      cs.col_lockedexpdate, cs.col_manualdateresolved,
                      cs.col_manualworkduration, cs.col_modifiedby,
                      cs.col_modifieddate, cs.col_owner, cs.col_processorname,
                      cs.col_resolutiondescription, cs.col_resolveby,
                      cs.col_statupdated, cs.col_summary, cs.col_workflow,
                      cs.col_cw_workitemcccasecc, cs.col_casecccase,
                      cs.col_caseccdict_casestate, cs.col_caseccdict_casesystype,
                      cs.col_caseccppl_workbasket, cs.col_defaultcaseccdocfoldercc,
                      cs.col_dfltmailcaseccdocfoldercc,
                      cs.col_dfltprntcaseccdocfoldercc,
                      cs.col_procedurecasecc, cs.col_stp_prioritycasecc,
                      cs.col_stp_resolutioncodecasecc,
                      cs.col_int_integtargetcasecc,
                      cs.col_MilestoneActivity, cs.col_PrevMSActivity,
                      cs.COL_CASECCDICT_STATE, cs.COL_PREVCASECCDICT_STATE,
                      cs.COL_GOALSLADATETIME, cs.COL_DLINESLADATETIME, cs.COL_DATEEVENTVALUE
                      
    FROM   TBL_CASECC cs
    WHERE  cs.col_casecccase IS NULL
           AND
           cs.col_id <> v_CaseId
    )
    LOOP
      INSERT INTO TBL_CASE (col_id, col_activity, col_casefrom, col_caseid,
                            col_dateassigned, col_dateclosed, col_draft,
                            col_extsysid, col_manualdateresolved, col_manualworkduration,
                            col_owner, col_processorname, col_resolveby, col_statupdated,
                            col_summary, col_workflow, col_cw_workitemcase,
                            col_casecasecc, col_casedict_casestate,
                            col_casedict_casesystype, col_caseppl_workbasket,
                            col_defaultcasedocfolder, col_defaultmailcasedocfolder,
                            col_defaultprtlcasedocfolder, col_int_integtargetcase,
                            col_procedurecase, col_stp_prioritycase, col_stp_resolutioncodecase,
                            COL_MILESTONEACTIVITY, COL_CASEDICT_STATE,
                            COL_PrevMSActivity, COl_PrevCaseDICT_State,
                            COL_GOALSLADATETIME, COL_DLINESLADATETIME, COL_DATEEVENTVALUE)
                     VALUES(rec.col_id, rec.col_activity, rec.col_casefrom,rec.col_caseid,
                            rec.col_dateassigned, rec.col_dateclosed, rec.col_draft,
                            rec.col_extsysid, rec.col_manualdateresolved, rec.col_manualworkduration,
                            rec.col_owner,rec.col_processorname, rec.col_resolveby, rec.col_statupdated,
                            rec.col_summary, rec.col_workflow, rec.col_cw_workitemcccasecc,
                            rec.col_id, rec.col_caseccdict_casestate,
                            rec.col_caseccdict_casesystype, rec.col_caseccppl_workbasket,
                            rec.col_defaultcaseccdocfoldercc, rec.col_dfltmailcaseccdocfoldercc,
                            rec.col_dfltprntcaseccdocfoldercc, rec.col_int_integtargetcasecc,
                            rec.col_procedurecasecc, rec.col_stp_prioritycasecc, rec.col_stp_resolutioncodecasecc,
                            rec.COL_MILESTONEACTIVITY, rec.COL_CaseCCDICT_State,
                            rec.COL_PrevMSActivity,  rec.COL_PREVCASECCDICT_STATE,
                            rec.COL_GOALSLADATETIME, rec.COL_DLINESLADATETIME, rec.COL_DATEEVENTVALUE);
        
        UPDATE tbl_casecc
        SET    col_casecccase = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--AUTO RULE PARAMETERS*/
    FOR rec IN(
    SELECT arp.col_id,
           arp.col_code,
           arp.col_createdby,
           arp.col_createddate,
           arp.col_issystem,
           arp.col_lockedby,
           arp.col_lockeddate,
           arp.col_lockedexpdate,
           arp.col_modifiedby,
           arp.col_modifieddate,
           arp.col_owner,
           arp.col_paramcode,
           arp.col_paramvalue,
           arp.col_autoruleparccautorulepar,
           arp.col_autoruleparccslaactioncc,
           arp.col_autoruleparamcccasedepcc,
           arp.col_autoruleparamcccasetype,
           arp.col_autoruleparamccparamconf,
           arp.col_autoruleparamcctaskcc,
           arp.col_autoruleparamcctaskdepcc,
           arp.col_caseeventccautoruleparcc,
           arp.col_ruleparcc_casestateinitcc,
           arp.col_ruleparcc_taskstateinitcc,
           arp.col_taskeventccautoruleparmcc,
           arp.col_tasksystypeautoruleparcc,
           arp.col_tasktemplateautoruleparcc,
           arp.col_ActionAutoRuleParCC,
           arp.col_AutoRulePrmCCCommonEvent,
           arp.col_AutoRulePrmCCDynamicTask
    FROM   TBL_AUTORULEPARAMCC arp
    WHERE  arp.col_autoruleparccautorulepar IS NULL
           AND
           arp.col_id NOT IN(
           /*--AUTO RULE PARAMETERS FOR CASE EVENTS*/
           (
           SELECT col_id
           FROM   tbl_autoruleparameter
           WHERE  col_caseeventautoruleparam IN(
                  SELECT col_id
                  FROM   tbl_caseevent
                  WHERE  col_caseeventcasestateinit IN(
                         SELECT col_id
                         FROM   tbl_map_casestateinitiation
                         WHERE  col_map_casestateinitcase = v_CaseId
                         )
                  )
           )
    
    UNION
          
          /*--SELECT ALL RULE PARAMETERS RELATED TO CASE STATE INITIATION*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_ruleparam_casestateinit IN(
                 SELECT col_id
                 FROM   tbl_map_casestateinitiation
                 WHERE  col_map_casestateinitcase = v_CaseId
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_ruleparam_casestateinit IN(
                 SELECT col_id
                 FROM   tbl_map_casestateinitiation
                 WHERE  col_map_casestateinitcase = v_CaseId
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULEPARAMETERS FOR TASK EVENTS*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_taskeventautoruleparam IN(
                 SELECT col_id
                 FROM   tbl_taskevent
                 WHERE  col_taskeventtaskstateinit IN(
                        SELECT col_id
                        FROM   tbl_map_taskstateinitiation
                        WHERE  col_map_taskstateinittask IN(
                               SELECT col_id
                               FROM   tbl_task
                               WHERE  col_casetask = v_CaseId
                               )
                        )
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_autoruleparametertask IN(
                 SELECT col_id
                 FROM   tbl_task
                 WHERE  col_casetask = v_CaseId
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULEPARAMETERS FOR TASK DEPENDENCIES*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_autoruleparamtaskdep IN(
                 SELECT col_id
                 FROM   tbl_taskdependency
                 WHERE  col_tskdpndprnttskstateinit IN(
                        SELECT col_id
                        FROM   tbl_map_taskstateinitiation
                        WHERE  col_map_taskstateinittask IN(
                               SELECT col_id
                               FROM   tbl_task
                               WHERE  col_casetask = v_CaseId
                               )
                        )
                        AND
                        col_tskdpndchldtskstateinit IN(
                        SELECT col_id
                        FROM   tbl_map_taskstateinitiation
                        WHERE  col_map_taskstateinittask IN(
                               SELECT col_id
                               FROM   tbl_task
                               WHERE  col_casetask = v_CaseId
                               )
                        )
                 )
          )
    
    UNION
          
          /*--SELECT ALL RULE PARAMETERS RELATED TO SLA ACTIONS*/
          (
          SELECT col_id
          FROM   tbl_autoruleparameter
          WHERE  col_AutoRuleParamSLAAction IN(
                 SELECT col_id
                 FROM   tbl_slaaction
                 WHERE  col_SLAActionSLAEvent IN(
                        SELECT col_id
                        FROM   tbl_slaevent
                        WHERE  col_SLAEventTask IN(
                               SELECT col_id
                               FROM   tbl_task
                               WHERE  col_casetask = v_CaseId
                               )
                        )
                 )
          ))
    )
    LOOP
        INSERT INTO TBL_AUTORULEPARAMETER
               (col_id,
                      col_code,
                      col_issystem,
                      col_owner,
                      col_paramcode,
                      col_paramvalue,
                      col_actionautoruleparameter,
                      col_autoruleparautoruleparcc,
                      col_autoruleparamcasedep,
                      col_autoruleparamcasesystype,
                      col_autoruleparamcommonevent,
                      col_autoruleparamdynamictask,
                      col_autoruleparamparamconfig,
                      col_autoruleparamslaaction,
                      col_autoruleparamtaskdep,
                      col_autoruleparametertask,
                      col_caseeventautoruleparam,
                      col_ruleparam_casestateinit,
                      col_ruleparam_taskstateinit,
                      col_ttautoruleparameter,
                      col_taskeventautoruleparam,
                      col_tasksystypeautoruleparam
               )
               VALUES
               (rec.col_id,
                      rec.col_code,
                      rec.col_issystem,
                      rec.col_owner,
                      rec.col_paramcode,
                      rec.col_paramvalue,
                      rec.col_actionautoruleparcc,
                      rec.col_id,
                      rec.col_autoruleparamcccasedepcc,
                      rec.col_autoruleparamcccasetype,
                      rec.col_autoruleprmcccommonevent,
                      rec.col_autoruleprmccdynamictask,
                      rec.col_autoruleparamccparamconf,
                      rec.col_autoruleparccslaactioncc,
                      rec.col_autoruleparamcctaskdepcc,
                      rec.col_autoruleparamcctaskcc,
                      rec.col_caseeventccautoruleparcc,
                      rec.col_ruleparcc_casestateinitcc,
                      rec.col_ruleparcc_taskstateinitcc,
                      rec.col_tasktemplateautoruleparcc,
                      rec.col_taskeventccautoruleparmcc,
                      rec.col_tasksystypeautoruleparcc
               ) ;
        
        UPDATE TBL_AUTORULEPARAMCC
        SET    col_autoruleparccautorulepar = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--CASE DEPENDENCIES*/
    FOR rec IN(
    SELECT cd.col_id,
           cd.col_code,
           cd.col_createdby,
           cd.col_createddate,
           cd.col_lockedby,
           cd.col_lockeddate,
           cd.col_lockedexpdate,
           cd.col_modifiedby,
           cd.col_modifieddate,
           cd.col_owner,
           cd.col_processorcode,
           cd.col_type,
           cd.col_casedepcccasedep,
           cd.col_casedpchldcccasestinitcc,
           cd.col_casedpchldcctaskstinitcc,
           cd.col_casedpprntcccasestinitcc,
           cd.col_casedpprntcctaskstinitcc,
           cd.col_casedepccglobalevent
    FROM   TBL_CASEDEPENDENCYCC cd
    WHERE (
           cd.col_casedepcccasedep IS NULL
           )
           AND
           cd.col_id NOT IN(
           SELECT col_id
           FROM   tbl_casedependency
           WHERE (
                  col_casedpndchldcasestateinit IN(
                  SELECT col_id
                  FROM   tbl_map_casestateinitiation
                  WHERE  col_map_casestateinitcase = v_CaseId
                  )
                  )
                  AND
                  (
                  col_casedpndprntcasestateinit IN(
                  SELECT col_id
                  FROM   tbl_map_casestateinitiation
                  WHERE  col_map_casestateinitcase = v_CaseId
                  )
                  )
           )
    )
    LOOP
        INSERT INTO TBL_CASEDEPENDENCY
               (col_id,
                      col_code,
                      col_owner,
                      col_processorcode,
                      col_type,
                      col_casedepcasedepcc,
                      col_casedependencyglobalevent,
                      col_casedpndchldcasestateinit,
                      col_casedpndchldtaskstateinit,
                      col_casedpndprntcasestateinit,
                      col_casedpndprnttaskstateinit
               )
               VALUES
               (rec.col_id,
                      rec.col_code,
                      rec.col_owner,
                      rec.col_processorcode,
                      rec.col_type,
                      rec.col_id,
                      rec.col_casedepccglobalevent,
                      rec.col_casedpchldcccasestinitcc,
                      rec.col_casedpchldcctaskstinitcc,
                      rec.col_casedpprntcccasestinitcc,
                      rec.col_casedpprntcctaskstinitcc
               ) ;
        
        UPDATE TBL_CASEDEPENDENCYCC
        SET    col_casedepcccasedep = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--CASE EVENTS*/
    FOR rec IN(
    SELECT ce.col_id,
           ce.col_caseeventorder,
           ce.col_code,
           ce.col_createdby,
           ce.col_createddate,
           ce.col_lockedby,
           ce.col_lockeddate,
           ce.col_lockedexpdate,
           ce.col_modifiedby,
           ce.col_modifieddate,
           ce.col_owner,
           ce.col_processorcode,
           ce.col_caseeventcccaseevent,
           ce.col_caseeventcccasestinitcc,
           ce.col_taskeventmomntcaseeventcc,
           ce.col_taskeventsnctpcaseeventcc,
           ce.col_taskeventtypecaseeventcc
    FROM   TBL_CASEEVENTCC ce
    WHERE  ce.col_caseeventcccaseevent IS NULL
           AND
           ce.col_id NOT IN(
           SELECT col_id
           FROM   tbl_caseevent
           WHERE  col_caseeventcasestateinit IN(
                  SELECT col_id
                  FROM   tbl_map_casestateinitiation
                  WHERE  col_map_casestateinitcase = v_CaseId
                  )
           )
    )
    LOOP
        INSERT INTO TBL_CASEEVENT
               (col_id,
                      col_caseeventorder,
                      col_code,
                      col_owner,
                      col_processorcode,
                      col_caseeventcaseeventcc,
                      col_caseeventcasestateinit,
                      col_taskeventmomentcaseevent,
                      col_taskeventtypecaseevent,
                      col_tskeventsynctypecaseevent
               )
               VALUES
               (rec.col_id,
                      rec.col_caseeventorder,
                      rec.col_code,
                      rec.col_owner,
                      rec.col_processorcode,
                      rec.col_id,
                      rec.col_caseeventcccasestinitcc,
                      rec.col_taskeventmomntcaseeventcc,
                      rec.col_taskeventsnctpcaseeventcc,
                      rec.col_taskeventtypecaseeventcc
               ) ;
        
        UPDATE TBL_CASEEVENTCC
        SET    col_caseeventcccaseevent = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*-- CASE STATE INITIATION*/
    FOR rec IN(
    SELECT mcst.col_id,
           mcst.col_assignprocessorcode,
           mcst.col_code,
           mcst.col_createdby,
           mcst.col_createddate,
           mcst.col_id2,
           mcst.col_lockedby,
           mcst.col_lockeddate,
           mcst.col_lockedexpdate,
           mcst.col_modifiedby,
           mcst.col_modifieddate,
           mcst.col_owner,
           mcst.col_processorcode,
           mcst.col_casestinitcccasestinit,
           mcst.col_casestateinitcc_casetype,
           mcst.col_casestateinitcc_initmtd,
           mcst.col_map_casestateinitcccasecc,
           mcst.col_map_csstinitcc_csst,
           mcst.col_map_csstateinitcctasktmpl
    FROM   TBL_MAP_CASESTATEINITCC mcst
    WHERE  mcst.col_casestinitcccasestinit IS NULL
           AND
           mcst.col_id NOT IN(
           SELECT col_id
           FROM   tbl_map_casestateinitiation
           WHERE  col_map_casestateinitcase = v_CaseId
           )
    )
    LOOP
        INSERT INTO TBL_MAP_CASESTATEINITIATION
               (col_id,
                      col_assignprocessorcode,
                      col_code,
                      col_id2,
                      col_owner,
                      col_processorcode,
                      col_casestinitcasestinitcc,
                      col_casestateinit_casesystype,
                      col_casestateinit_initmethod,
                      col_map_casestateinitcase,
                      col_map_csstinit_csst,
                      col_map_casestateinittasktmpl
               )
               VALUES
               (rec.col_id,
                      rec.col_assignprocessorcode,
                      rec.col_code,
                      rec.col_id2,
                      rec.col_owner,
                      rec.col_processorcode,
                      rec.col_id,
                      rec.col_casestateinitcc_casetype,
                      rec.col_casestateinitcc_initmtd,
                      rec.col_map_casestateinitcccasecc,
                      rec.col_map_csstinitcc_csst,
                      rec.col_map_csstateinitcctasktmpl
               ) ;
        
        UPDATE TBL_MAP_CASESTATEINITCC
        SET    col_casestinitcccasestinit = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    
    
    
    /*--HISTORY*/
    FOR rec IN(
    SELECT h.col_id,
           h.col_activitytimedate,
           h.col_additionalinfo,
           h.col_createdby,
           h.col_createdbyname,
           h.col_createddate,
           h.col_description,
           h.col_historycreatedby,
           h.col_issystem,
           h.col_lockedby,
           h.col_lockeddate,
           h.col_lockedexpdate,
           h.col_modifiedby,
           h.col_modifieddate,
           h.col_owner,
           h.col_historycccasecc,
           h.col_historycchistory,
           h.col_historyccnextcasestate,
           h.col_historyccnexttaskstate,
           h.col_historyccprevcasestate,
           h.col_historyccprevtaskstate,
           h.col_historycctaskcc,
           h.col_messagetypehistorycc,
           h.col_HistCCDynamicTask
    FROM   TBL_HISTORYCC h
    WHERE  h.col_historycchistory IS NULL
           AND
           /*--h.col_historycccasecc IS NOT NULL AND*/
           /*--h.col_historycctaskcc IS NULL  AND*/
           h.col_id NOT IN(
           /*--HISTORY FOR CASE*/
           (
           SELECT col_id
           FROM   TBL_HISTORY
           WHERE  col_historycase = v_CaseId
           )
    
    UNION
          
          /*--HISTORY FOR TASKS IN CASE*/
          (
          SELECT col_id
          FROM   TBL_HISTORY
          WHERE  col_historytask IN(
                 SELECT col_id
                 FROM   tbl_task
                 WHERE  col_casetask = v_CaseId
                 )
          ))
    )
    LOOP
        INSERT INTO TBL_HISTORY
               (col_id,
                      col_activitytimedate,
                      col_additionalinfo,
                      col_createdbyname,
                      col_description,
                      col_historycreatedby,
                      col_issystem,
                      col_owner,
                      col_historycase,
                      col_historydynamictask,
                      col_historyhistorycc,
                      col_historynextcasestate,
                      col_historynexttaskstate,
                      col_historyprevcasestate,
                      col_historyprevtaskstate,
                      col_historytask,
                      col_messagetypehistory
               )
               VALUES
               (rec.col_id,
                      rec.col_activitytimedate,
                      rec.col_additionalinfo,
                      rec.col_createdbyname,
                      rec.col_description,
                      rec.col_historycreatedby,
                      rec.col_issystem,
                      rec.col_owner,
                      rec.col_historycccasecc,
                      rec.col_histccdynamictask,
                      rec.col_id,
                      rec.col_historyccnextcasestate,
                      rec.col_historyccnexttaskstate,
                      rec.col_historyccprevcasestate,
                      rec.col_historyccprevtaskstate,
                      rec.col_historycctaskcc,
                      rec.col_messagetypehistorycc
               ) ;
        
        UPDATE TBL_HISTORYCC
        SET    col_historycchistory = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--DATE EVENTS*/
    FOR rec IN(
    SELECT dte.col_id,
           dte.col_createdby,
           dte.col_createddate,
           dte.col_customdata,
           dte.col_datename,
           dte.col_datevalue,
           dte.col_lockedby,
           dte.col_lockeddate,
           dte.col_lockedexpdate,
           dte.col_modifiedby,
           dte.col_modifieddate,
           dte.col_owner,
           dte.col_performedby,
           dte.col_dateeventcccasecc,
           dte.col_dateeventccdateevent,
           dte.col_dateeventccppl_caseworker,
           dte.col_dateeventccppl_workbasket,
           dte.col_dateeventcctaskcc,
           dte.col_dateeventcc_dateeventtype,
           dte.COL_DateEventCCDICT_State
    FROM   TBL_DATEEVENTCC dte
    WHERE  dte.col_dateeventccdateevent IS NULL
           AND
           /*--dte.col_dateeventcctaskcc IS NULL AND*/
           /*--dte.col_dateeventcccasecc IS NOT NULL AND*/
           dte.col_id NOT IN(
           /*--DATE EVENTS FOR CASE*/
           (
           SELECT col_id
           FROM   tbl_dateevent
           WHERE  col_dateeventcase = v_CaseId
           )

           UNION

          /*--DATE EVENTS FOR TASKS IN CASE*/
          (
          SELECT col_id
          FROM   tbl_dateevent
          WHERE  col_dateeventtask IN(
                 SELECT col_id
                 FROM   tbl_task
                 WHERE  col_casetask = v_CaseId
                 )
          ))
    )
    LOOP
        INSERT INTO TBL_DATEEVENT
               (col_id,
                      col_customdata,
                      col_datename,
                      col_datevalue,
                      col_owner,
                      col_performedby,
                      col_dateeventcase,
                      col_dateeventdateeventcc,
                      col_dateeventppl_caseworker,
                      col_dateeventppl_workbasket,
                      col_dateeventtask,
                      col_dateevent_dateeventtype,
                      COL_DATEEVENTDICT_STATE
               )
               VALUES
               (rec.col_id,
                      rec.col_customdata,
                      rec.col_datename,
                      rec.col_datevalue,
                      rec.col_owner,
                      rec.col_performedby,
                      rec.col_dateeventcccasecc,
                      rec.col_id,
                      rec.col_dateeventccppl_caseworker,
                      rec.col_dateeventccppl_workbasket,
                      rec.col_dateeventcctaskcc,
                      rec.col_dateeventcc_dateeventtype,
                      rec.COL_DateEventCCDICT_State
               ) ;
        
        UPDATE TBL_DATEEVENTCC
        SET    col_dateeventccdateevent = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    
    /*--TASK WORKITEMS*/
    FOR rec IN(
    SELECT twi.col_id,
           twi.col_activity,
           twi.col_createdby,
           twi.col_createddate,
           twi.col_holdexpdate,
           twi.col_holdsetdate,
           twi.col_instanceid,
           twi.col_instancetype,
           twi.col_isonhold,
           twi.col_lockedby,
           twi.col_lockeddate,
           twi.col_lockedexpdate,
           twi.col_modifiedby,
           twi.col_modifieddate,
           twi.col_notes,
           twi.col_owner,
           twi.col_prevactivity,
           twi.col_prevactivityname,
           twi.col_prevsubject,
           twi.col_prevsubjectname,
           twi.col_receiveddate,
           twi.col_refparentid,
           twi.col_subject,
           twi.col_workflow,
           twi.col_tw_workitemccdict_taskst,
           twi.col_tw_workitemccprevtaskst,
           twi.col_tw_workitemcctw_workitem
    FROM   TBL_TW_WORKITEMCC twi
    WHERE  twi.col_tw_workitemcctw_workitem IS NULL
           AND
           twi.col_id NOT IN(
           SELECT col_id
           FROM   tbl_tw_workitem
           WHERE  col_id IN(
                  SELECT col_tw_workitemtask
                  FROM   tbl_task
                  WHERE  col_casetask = v_CaseId
                  )
           )
    )
    LOOP
        INSERT INTO TBL_TW_WORKITEM
               (col_id,
                      col_activity,
                      col_holdexpdate,
                      col_holdsetdate,
                      col_instanceid,
                      col_instancetype,
                      col_isonhold,
                      col_notes,
                      col_owner,
                      col_prevactivity,
                      col_prevactivityname,
                      col_prevsubject,
                      col_prevsubjectname,
                      col_receiveddate,
                      col_refparentid,
                      col_subject,
                      col_workflow,
                      col_tw_workitemdict_taskstate,
                      col_tw_workitemprevtaskstate,
                      col_tw_workitemtw_workitemcc
               )
               VALUES
               (rec.col_id,
                      rec.col_activity,
                      rec.col_holdexpdate,
                      rec.col_holdsetdate,
                      rec.col_instanceid,
                      rec.col_instancetype,
                      rec.col_isonhold,
                      rec.col_notes,
                      rec.col_owner,
                      rec.col_prevactivity,
                      rec.col_prevactivityname,
                      rec.col_prevsubject,
                      rec.col_prevsubjectname,
                      rec.col_receiveddate,
                      rec.col_refparentid,
                      rec.col_subject,
                      rec.col_workflow,
                      rec.col_tw_workitemccdict_taskst,
                      rec.col_tw_workitemccprevtaskst,
                      rec.col_id
               ) ;
        
        UPDATE TBL_TW_WORKITEMCC
        SET    col_tw_workitemcctw_workitem = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--SLA ACTIONS*/
    FOR rec IN(
    SELECT sla.col_id,
           sla.col_processorcode,
           sla.col_owner,
           sla.col_name,
           sla.col_modifiedby,
           sla.col_lockedby,
           sla.col_createdby,
           sla.col_code,
           sla.col_modifieddate,
           sla.col_lockedexpdate,
           sla.col_lockeddate,
           sla.col_createddate,
           sla.col_actionorder,
           sla.col_description,
           sla.col_slaactionccslaeventcc,
           sla.col_slaactionccslaaction,
           sla.col_slaactioncc_slaeventlevel
    FROM   TBL_SLAACTIONCC sla
    WHERE  sla.col_slaactionccslaaction IS NULL
           AND
           sla.col_id NOT IN(
           SELECT col_id
           FROM   tbl_slaaction
           WHERE  col_slaactionslaevent IN(
                  SELECT col_id
                  FROM   tbl_slaevent
                  WHERE  col_slaeventtask IN(
                         SELECT col_id
                         FROM   tbl_task
                         WHERE  col_casetask = v_CaseId
                         )
                  )
           )
    )
    LOOP
        INSERT INTO TBL_SLAACTION
               (col_id,
                      col_actionorder,
                      col_code,
                      col_description,
                      col_name,
                      col_owner,
                      col_processorcode,
                      col_slaactionslaactioncc,
                      col_slaactionslaevent,
                      col_slaaction_slaeventlevel
               )
               VALUES
               (rec.col_id,
                      rec.col_actionorder,
                      rec.col_code,
                      rec.col_description,
                      rec.col_name,
                      rec.col_owner,
                      rec.col_processorcode,
                      rec.col_id,
                      rec.col_slaactionccslaeventcc,
                      rec.col_slaactioncc_slaeventlevel
               ) ;
        
        UPDATE TBL_SLAACTIONCC
        SET    col_slaactionccslaaction = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--SLA EVENTS*/
    FOR rec IN(
    SELECT sla.col_id,
           sla.col_isrequired,
           sla.col_slaeventorder,
           sla.col_maxattempts,
           sla.col_id2,
           sla.col_attemptcount,
           sla.col_owner,
           sla.col_modifiedby,
           sla.col_lockedby,
           sla.col_intervalym,
           sla.col_intervalds,
           sla.col_createdby,
           sla.col_code,
           sla.col_modifieddate,
           sla.col_lockedexpdate,
           sla.col_lockeddate,
           sla.col_createddate,
           sla.col_slaeventcccasecc,
           sla.col_slaeventcctaskcc,
           sla.col_slaeventccslaevent,
           sla.col_slaeventcctasktemplate,
           sla.col_slaeventcc_dateeventtype,
           sla.col_slaeventcc_slaeventlevel,
           sla.col_slaeventcc_slaeventtype,
           sla.col_slaeventcc_tasksystype,
           sla.col_SLAEvtCCDynamicTask,
           sla.COL_FINISHDATEEVENTVALUE,
           sla.COL_SLAEVENTDATE,
           sla.COL_STARTDATEEVENTBY,
           sla.COL_STARTDATEEVENTVALUE
    FROM   TBL_SLAEVENTCC sla
    WHERE  sla.col_slaeventccslaevent IS NULL
           AND
           sla.col_id NOT IN(
           SELECT col_id
           FROM   tbl_slaevent
           WHERE  col_slaeventtask IN(
                  SELECT col_id
                  FROM   tbl_task
                  WHERE  col_casetask = v_CaseId
                  )
           )
    )
    LOOP
        INSERT INTO TBL_SLAEVENT
               (col_id,
                col_attemptcount,
                col_code,
                col_id2,
                col_intervalds,
                col_intervalym,
                col_isrequired,
                col_maxattempts,
                col_owner,
                col_slaeventorder,
                col_slaeventcase,
                col_slaeventdict_slaeventtype,
                col_slaeventdict_tasksystype,
                col_slaeventdynamictask,
                col_slaeventslaeventcc,
                col_slaeventtask,
                col_slaeventtasktemplate,
                col_slaevent_dateeventtype,
                col_slaevent_slaeventlevel,
                COL_FINISHDATEEVENTVALUE,
                COL_SLAEVENTDATE,
                COL_STARTDATEEVENTBY,
                COL_STARTDATEEVENTVALUE
               )
               VALUES
               (rec.col_id,
                rec.col_attemptcount,
                rec.col_code,
                rec.col_id2,
                rec.col_intervalds,
                rec.col_intervalym,
                rec.col_isrequired,
                rec.col_maxattempts,
                rec.col_owner,
                rec.col_slaeventorder,
                rec.col_slaeventcccasecc,
                rec.col_slaeventcc_slaeventtype,
                rec.col_slaeventcc_tasksystype,
                rec.col_slaevtccdynamictask,
                rec.col_id,
                rec.col_slaeventcctaskcc,
                rec.col_slaeventcctasktemplate,
                rec.col_slaeventcc_dateeventtype,
                rec.col_slaeventcc_slaeventlevel,
                rec.COL_FINISHDATEEVENTVALUE,
                rec.COL_SLAEVENTDATE,
                rec.COL_STARTDATEEVENTBY,
                rec.COL_STARTDATEEVENTVALUE                      
               ) ;
        
        UPDATE TBL_SLAEVENTCC
        SET    col_slaeventccslaevent = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    
    
    
    
    /*--TASK EVENTS*/
    FOR rec IN(
    SELECT te.col_id,
           te.col_code,
           te.col_createdby,
           te.col_createddate,
           te.col_id2,
           te.col_lockedby,
           te.col_lockeddate,
           te.col_lockedexpdate,
           te.col_modifiedby,
           te.col_modifieddate,
           te.col_owner,
           te.col_processorcode,
           te.col_taskeventorder,
           te.col_taskeventcctaskevent,
           te.col_taskeventcctaskstinitcc,
           te.col_taskeventmomnttaskeventcc,
           te.col_taskeventsnctptaskeventcc,
           te.col_taskeventtypetaskeventcc
    FROM   TBL_TASKEVENTCC te
    WHERE  te.col_taskeventcctaskevent IS NULL
           AND
           te.col_id NOT IN(
           SELECT col_id
           FROM   tbl_taskevent
           WHERE  col_taskeventtaskstateinit IN(
                  SELECT col_id
                  FROM   tbl_map_taskstateinitiation
                  WHERE  col_map_taskstateinittask IN(
                         SELECT col_id
                         FROM   tbl_task
                         WHERE  col_casetask = v_CaseId
                         )
                  )
           )
    )
    LOOP
        INSERT INTO TBL_TASKEVENT
               (col_id,
                      col_code,
                      col_id2,
                      col_owner,
                      col_processorcode,
                      col_taskeventorder,
                      col_taskeventmomenttaskevent,
                      col_taskeventtaskeventcc,
                      col_taskeventtaskstateinit,
                      col_taskeventtypetaskevent,
                      col_tskeventsynctypetaskevent
               )
               VALUES
               (rec.col_id,
                      rec.col_code,
                      rec.col_id2,
                      rec.col_owner,
                      rec.col_processorcode,
                      rec.col_taskeventorder,
                      rec.col_taskeventmomnttaskeventcc,
                      rec.col_id,
                      rec.col_taskeventcctaskstinitcc,
                      rec.col_taskeventtypetaskeventcc,
                      rec.col_taskeventsnctptaskeventcc
               ) ;
        
        UPDATE TBL_TASKEVENTCC
        SET    col_taskeventcctaskevent = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--TASK DEPENDENCIES*/
    FOR rec IN(
    SELECT td.col_id,
           td.col_code,
           td.col_createdby,
           td.col_createddate,
           td.col_id2,
           td.col_isdefault,
           td.col_lockedby,
           td.col_lockeddate,
           td.col_lockedexpdate,
           td.col_modifiedby,
           td.col_modifieddate,
           td.col_owner,
           td.col_processorcode,
           td.col_taskdependencyorder,
           td.col_type,
           td.col_taskdepcctaskdep,
           td.col_taskdpchldcctaskstinitcc,
           td.col_taskdpprntcctaskstinitcc
    FROM   TBL_TASKDEPENDENCYCC td
    WHERE  td.col_taskdepcctaskdep IS NULL
           AND
           td.col_id NOT IN(
           SELECT col_id
           FROM   tbl_taskdependency
           WHERE  col_tskdpndchldtskstateinit IN(
                  SELECT col_id
                  FROM   tbl_map_taskstateinitiation
                  WHERE  col_map_taskstateinittask IN(
                         SELECT col_id
                         FROM   tbl_task
                         WHERE  col_casetask = v_CaseId
                         )
                  )
                  AND
                  col_tskdpndprnttskstateinit IN(
                  SELECT col_id
                  FROM   tbl_map_taskstateinitiation
                  WHERE  col_map_taskstateinittask IN(
                         SELECT col_id
                         FROM   tbl_task
                         WHERE  col_casetask = v_CaseId
                         )
                  )
           )
    )
    LOOP
        INSERT INTO TBL_TASKDEPENDENCY
               (col_id,
                      Col_code,
                      col_id2,
                      col_isdefault,
                      col_owner,
                      col_processorcode,
                      col_taskdependencyorder,
                      col_type,
                      col_taskdeptaskdepcc,
                      col_tskdpndchldtskstateinit,
                      col_tskdpndprnttskstateinit
               )
               VALUES
               (rec.col_id,
                      rec.col_code,
                      rec.col_id2,
                      rec.col_isdefault,
                      rec.col_owner,
                      rec.col_processorcode,
                      rec.col_taskdependencyorder,
                      rec.col_type,
                      rec.col_id,
                      rec.col_taskdpchldcctaskstinitcc,
                      rec.col_taskdpprntcctaskstinitcc
               ) ;
        
        UPDATE TBL_TASKDEPENDENCYCC
        SET    col_taskdepcctaskdep = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--TASK STATE INITIATION*/
    FOR rec IN(
    SELECT tsi.col_id,
           tsi.col_assignprocessorcode,
           tsi.col_code,
           tsi.col_createdby,
           tsi.col_createddate,
           tsi.col_id2,
           tsi.col_lockedby,
           tsi.col_lockeddate,
           tsi.col_lockedexpdate,
           tsi.col_modifiedby,
           tsi.col_modifieddate,
           tsi.col_owner,
           tsi.col_processorcode,
           tsi.col_routedby,
           tsi.col_routeddate,
           tsi.col_map_taskstinitcctasktmpl,
           tsi.col_map_taskstateinitcctaskcc,
           tsi.col_map_tskstinitcc_initmtd,
           tsi.col_map_tskstinitcc_tskst,
           tsi.col_taskstinitcctaskstinit,
           tsi.col_taskstateinitcc_tasktype,
           tsi.col_TaskStInitCCDynamicTask
    FROM   TBL_MAP_TASKSTATEINITCC tsi
    WHERE  tsi.col_taskstinitcctaskstinit IS NULL
           AND
           tsi.col_ID NOT IN(
           SELECT col_id
           FROM   tbl_map_taskstateinitiation
           WHERE  col_map_taskstateinittask IN(
                  SELECT col_id
                  FROM   tbl_task
                  WHERE  col_casetask = v_CaseId
                  )
           )
    )
    LOOP
        INSERT INTO TBL_MAP_TASKSTATEINITIATION
               (col_id,
                      col_assignprocessorcode,
                      col_code,
                      col_id2,
                      col_owner,
                      col_processorcode,
                      col_routedby,
                      col_routeddate,
                      col_map_taskstateinittask,
                      col_map_taskstateinittasktmpl,
                      col_map_tskstinit_initmtd,
                      col_map_tskstinit_tskst,
                      col_taskstinittaskstinitcc,
                      col_taskstateinitdynamictask,
                      col_taskstateinit_tasksystype
               )
               VALUES
               (rec.col_id,
                      rec.col_assignprocessorcode,
                      rec.col_code,
                      rec.col_id2,
                      rec.col_owner,
                      rec.col_processorcode,
                      rec.col_routedby,
                      rec.col_routeddate,
                      rec.col_map_taskstateinitcctaskcc,
                      rec.col_map_taskstinitcctasktmpl,
                      rec.col_map_tskstinitcc_initmtd,
                      rec.col_map_tskstinitcc_tskst,
                      rec.col_id,
                      rec.col_taskstinitccdynamictask,
                      rec.col_taskstateinitcc_tasktype
               ) ;
        
        UPDATE TBL_MAP_TASKSTATEINITCC
        SET    col_taskstinitcctaskstinit = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;
    
    
    /*--TASKS*/
    FOR rec IN(
    SELECT tsk.col_id,
           tsk.col_createdby,
           tsk.col_createddate,
           tsk.col_customdata,
           tsk.col_dateassigned,
           tsk.col_dateclosed,
           tsk.col_datestarted,
           tsk.col_depth,
           tsk.col_description,
           tsk.col_draft,
           tsk.col_enabled,
           tsk.col_extsysid,
           tsk.col_hoursworked,
           tsk.col_icon,
           tsk.col_iconcls,
           tsk.col_id2,
           tsk.col_leaf,
           tsk.col_lockedby,
           tsk.col_lockeddate,
           tsk.col_lockedexpdate,
           tsk.col_manualdateresolved,
           tsk.col_manualworkduration,
           tsk.col_modifiedby,
           tsk.col_modifieddate,
           tsk.col_name,
           tsk.col_owner,
           tsk.col_pagecode,
           tsk.col_perccomplete,
           tsk.col_processorname,
           tsk.col_required,
           tsk.col_resolutiondescription,
           tsk.col_statupdated,
           tsk.col_status,
           tsk.col_systemtype,
           tsk.col_systemtype2,
           tsk.col_taskid,
           tsk.col_taskorder,
           tsk.col_transactionid,
           tsk.col_type,
           tsk.COL_CASECCTASKCC,
           tsk.col_parentidcc,
           tsk.col_tw_workitemcctaskcc,
           tsk.col_taskccdict_customword,
           tsk.col_taskccdict_executionmtd,
           tsk.col_taskccdict_tasksystype,
           tsk.col_taskccppl_workbasket,
           tsk.col_taskccpreviousworkbasket,
           tsk.col_taskccprocedure,
           tsk.col_taskccresolcode_param,
           tsk.col_taskccstp_resolutioncode,
           tsk.col_taskcctask,
           tsk.col_taskccworkbasket_param,
           tsk.col_INT_IntegTargetTaskCC,
           tsk.col_isadhoc,
           tsk.col_TaskCCDICT_TaskState,
           tsk.col_PrevTaskCCDICT_TaskState,
           tsk.col_goalslaeventdate,
           tsk.col_dlineslaeventdate,
           tsk.COL_ISHIDDEN
           
    FROM   tbl_taskcc tsk
    WHERE  tsk.col_taskcctask IS NULL
           AND
           tsk.col_id NOT IN(
           SELECT col_id
           FROM   tbl_task
           WHERE  col_casetask = v_CaseId
           )
    )
    LOOP
        INSERT INTO TBL_TASK
               (col_id,
                      col_customdata,
                      col_dateassigned,
                      col_dateclosed,
                      col_datestarted,
                      col_depth,
                      col_description,
                      col_draft,
                      col_enabled,
                      col_extsysid,
                      col_hoursworked,
                      col_icon,
                      col_iconcls,
                      col_id2,
                      col_leaf,
                      col_manualdateresolved,
                      col_manualworkduration,
                      col_name,
                      col_owner,
                      col_pagecode,
                      col_perccomplete,
                      col_processorname,
                      col_required,
                      col_resolutiondescription,
                      col_statupdated,
                      col_status, /*col_systemtype,*/
                      col_systemtype2,
                      col_taskid,
                      col_taskorder,
                      col_transactionid,
                      col_type,
                      col_casetask,
                      col_int_integtargettask,
                      col_parentid,
                      col_tw_workitemtask,
                      col_taskdict_customword,
                      col_taskdict_executionmethod,
                      col_taskdict_tasksystype,
                      col_taskppl_workbasket,
                      col_taskpreviousworkbasket,
                      col_taskprocedure,
                      col_taskresolutioncode_param,
                      col_taskstp_resolutioncode,
                      col_tasktaskcc,
                      col_taskworkbasket_param,
                      col_isadhoc,
                      col_TaskDICT_TaskState,
                      col_PrevTaskDICT_TaskState,
                      col_goalslaeventdate,
                      col_dlineslaeventdate,
                      COL_ISHIDDEN
               )
               VALUES
               (rec.col_id,
                      rec.col_customdata,
                      rec.col_dateassigned,
                      rec.col_dateclosed,
                      rec.col_datestarted,
                      rec.col_depth,
                      rec.col_description,
                      rec.col_draft,
                      rec.col_enabled,
                      rec.col_extsysid,
                      rec.col_hoursworked,
                      rec.col_icon,
                      rec.col_iconcls,
                      rec.col_id2,
                      rec.col_leaf,
                      rec.col_manualdateresolved,
                      rec.col_manualworkduration,
                      rec.col_name,
                      rec.col_owner,
                      rec.col_pagecode,
                      rec.col_perccomplete,
                      rec.col_processorname,
                      rec.col_required,
                      rec.col_resolutiondescription,
                      rec.col_statupdated,
                      rec.col_status, /*rec.col_systemtype,*/
                      rec.col_systemtype2,
                      rec.col_taskid,
                      rec.col_taskorder,
                      rec.col_transactionid,
                      rec.col_type,
                      rec.COL_CASECCTASKCC,
                      rec.col_int_integtargettaskcc,
                      rec.col_parentidcc,
                      rec.col_tw_workitemcctaskcc,
                      rec.col_taskccdict_customword,
                      rec.col_taskccdict_executionmtd,
                      rec.col_taskccdict_tasksystype,
                      rec.col_taskccppl_workbasket,
                      rec.col_taskccpreviousworkbasket,
                      rec.col_taskccprocedure,
                      rec.col_taskccresolcode_param,
                      rec.col_taskccstp_resolutioncode,
                      rec.col_id,
                      rec.col_taskccworkbasket_param,
                      rec.col_isadhoc,
                      rec.col_TaskCCDICT_TaskState,
                      rec.col_PrevTaskCCDICT_TaskState,
                      rec.col_goalslaeventdate,
                      rec.col_dlineslaeventdate,
                      rec.COL_ISHIDDEN
               ) ;
        
        UPDATE tbl_taskcc
        SET    col_taskcctask = rec.col_id
        WHERE  col_id = rec.col_id;
    
    END LOOP;


END;