declare
  v_CaseId Integer;
  v_result number;
  v_result2 number;
begin
  v_CaseId := :CaseId;

  update tbl_tw_workitem twi set col_activity = (select col_activity from tbl_tw_workitemcc twicc where twicc.col_id = twi.col_id),
  col_tw_workitemprevtaskstate = (select col_tw_workitemccprevtaskst from tbl_tw_workitemcc twicc where twicc.col_id = twi.col_id),
  col_tw_workitemdict_taskstate = (select col_tw_workitemccdict_taskst from tbl_tw_workitemcc twicc where twicc.col_id = twi.col_id)
  where col_id in (select col_tw_workitemtask from tbl_task where col_casetask = v_CaseId);

  update tbl_map_taskstateinitiation tsi set col_routedby = (select col_routedby from tbl_map_taskstateinitcc tsicc where tsicc.col_id = tsi.col_id),
  col_routeddate = (select col_routeddate from tbl_map_taskstateinitcc tsicc where tsicc.col_id = tsi.col_id)
  where col_map_taskstateinittask in (select col_id from tbl_task where col_casetask = v_CaseId);

  update tbl_task tsk set col_datestarted = (select col_datestarted from tbl_taskcc tskcc where tskcc.col_id = tsk.col_id),
  col_dateassigned = (select col_dateassigned from tbl_taskcc tskcc where tskcc.col_id = tsk.col_id),
  col_dateclosed = (select col_dateclosed from tbl_taskcc tskcc where tskcc.col_id = tsk.col_id),
  col_taskpreviousworkbasket = (select col_taskccpreviousworkbasket from tbl_taskcc tskcc where tskcc.col_id = tsk.col_id),
  col_taskppl_workbasket = (select col_taskccppl_workbasket from tbl_taskcc tskcc where tskcc.col_id = tsk.col_id),
  col_taskstp_resolutioncode = (select col_taskccstp_resolutioncode from tbl_taskcc tskcc where tskcc.col_id = tsk.col_id),
  col_taskworkbasket_param = (select col_taskccworkbasket_param from tbl_taskcc tskcc where tskcc.col_id = tsk.col_id),
  col_taskresolutioncode_param = (select col_taskccresolcode_param from tbl_taskcc tskcc where tskcc.col_id = tsk.col_id)
  where col_casetask = v_CaseId;
  
  /*VV* prevent a copy of existing records of tasks*/
  v_result :=0;

  BEGIN
    select COUNT(1) INTO v_result
    from tbl_task
    where (col_casetask = v_CaseId and col_taskprocedure is not NULL) OR
    /*VV*/  (col_casetask = v_CaseId and col_taskprocedure is NULL AND NVL(COL_LEAF,0)=1);
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_result := 0;
  END;
  /*VV*/
  
  -------------------------------------------------------------------------------------------------------------------------------------------------------
  for rec in (select col_id as AdhocTaskId, col_id2, col_createdby, col_createddate, col_modifiedby, col_modifieddate, col_owner,
              col_type, col_parentidcc, col_description, col_name, col_taskid, col_depth, col_iconcls, col_icon, col_leaf, col_taskorder, col_required,
              col_casecctaskcc, col_taskccdict_tasksystype, col_processorname, col_taskccdict_executionmtd, col_pagecode,
              /*VV*/col_tw_workitemcctaskcc
              from tbl_taskcc
              where ((col_casecctaskcc = v_CaseId and col_taskccprocedure is not NULL) OR
              /*VV*/  (col_casecctaskcc = v_CaseId and col_taskccprocedure is NULL AND NVL(COL_LEAF,0)=1)) AND
              /*VV*/ v_result=0
              order by col_taskorder)
  loop
    insert into tbl_task (col_id2, col_createdby, col_createddate, col_modifiedby, col_modifieddate, col_owner, col_type, col_parentid, col_description,
                 col_name, col_taskid, col_depth, col_iconcls, col_icon, col_leaf, col_taskorder, col_required, col_casetask, col_taskdict_tasksystype,
                 col_processorname, col_taskdict_executionmethod, col_pagecode, col_tasktaskcc)
      values (rec.col_id2, rec.col_createdby, rec.col_createddate, rec.col_modifiedby, rec.col_modifieddate, rec.col_owner,
              rec.col_type, rec.col_parentidcc, rec.col_description, rec.col_name, rec.col_taskid, rec.col_depth, rec.col_iconcls, rec.col_icon, rec.col_leaf,
              rec.col_taskorder, rec.col_required, rec.col_casecctaskcc, rec.col_taskccdict_tasksystype, rec.col_processorname, rec.col_taskccdict_executionmtd, rec.col_pagecode, rec.AdhocTaskId);
    select gen_tbl_task.currval into v_result from dual;
    --update tbl_taskcc set col_taskcctask = v_result where col_id = rec.AdhocTaskId;
    update tbl_taskcc set col_taskcctask = (select min(col_id) from tbl_task where col_tasktaskcc = rec.AdhocTaskId) where col_id = rec.AdhocTaskId;
    update tbl_task set col_parentid = (select tsk2.col_id from tbl_taskcc tcc1
                                        inner join tbl_taskcc tcc2 on tcc1.col_parentidcc = tcc2.col_id
                                        inner join tbl_task tsk1 on tcc1.col_taskcctask = tsk1.col_id
                                        inner join tbl_task tsk2 on tcc2.col_taskcctask = tsk2.col_id
                                        where tcc1.col_id = rec.AdhocTaskId)
    where col_id = (select col_taskcctask from tbl_taskcc where col_id = rec.AdhocTaskId);
    /*VV*/
    IF rec.col_tw_workitemcctaskcc IS NOT NULL THEN
    /*VV*/
    insert into tbl_tw_workitem(col_workflow, col_activity, col_tw_workitemdict_taskstate, col_instanceid, col_owner, col_createdby, col_createddate, col_instancetype, col_tw_workitemtw_workitemcc)
      (select col_workflow, col_activity, col_tw_workitemccdict_taskst, col_instanceid, col_owner, col_createdby, col_createddate, col_instancetype, col_id
      from tbl_tw_workitemcc where col_id = (select col_tw_workitemcctaskcc from tbl_taskcc where col_id = rec.AdhocTaskId));
    select gen_tbl_tw_workitem.currval into v_result2 from dual;
    update tbl_tw_workitemcc set col_tw_workitemcctw_workitem =
    (select twi.col_id from tbl_taskcc tskcc
                 inner join tbl_tw_workitemcc twicc on tskcc.col_tw_workitemcctaskcc = twicc.col_id
                 inner join tbl_task tsk on tskcc.col_taskcctask = tsk.col_id
                 inner join tbl_tw_workitem twi on twicc.col_id = twi.col_tw_workitemtw_workitemcc
                      where tsk.col_tasktaskcc = rec.AdhocTaskId)
    where col_id = (select col_tw_workitemcctaskcc from tbl_taskcc where col_id = rec.AdhocTaskId);
    /*VV*/
    END IF;
    /*VV*/
    --update tbl_task set col_tw_workitemtask = v_result2 where col_id = v_result;
    update tbl_task set col_tw_workitemtask = (select twi.col_id from tbl_taskcc tskcc
                                               inner join tbl_tw_workitemcc twicc on tskcc.col_tw_workitemcctaskcc = twicc.col_id and tskcc.col_id = rec.AdhocTaskId
                                               inner join tbl_task tsk on tskcc.col_taskcctask = tsk.col_id
                                               inner join tbl_tw_workitem twi on twicc.col_tw_workitemcctw_workitem = twi.col_id)
    where col_id = (select col_taskcctask from tbl_taskcc where col_id = rec.AdhocTaskId);
    insert into tbl_map_taskstateinitiation(col_map_taskstateinittask,col_processorcode,col_assignprocessorcode,col_map_tskstinit_initmtd,col_map_tskstinit_tskst,
                                           col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner,col_taskstinittaskstinitcc)
        (select (select tsk.col_id from tbl_task tsk inner join tbl_taskcc tskcc on tsk.col_tasktaskcc = tskcc.col_id where tskcc.col_id = rec.AdhocTaskId),
                                           col_processorcode,col_assignprocessorcode,col_map_tskstinitcc_initmtd,col_map_tskstinitcc_tskst,
                                           col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner,col_id
         from tbl_map_taskstateinitcc where col_map_taskstateinitcctaskcc = rec.AdhocTaskId);
    update tbl_map_taskstateinitcc tsi2 set col_taskstinitcctaskstinit =
      (select tsi.col_id
      from tbl_taskcc tskcc
      inner join tbl_map_taskstateinitcc tsicc on tskcc.col_id = tsicc.col_map_taskstateinitcctaskcc
      inner join tbl_task tsk on tskcc.col_taskcctask = tsk.col_id and tskcc.col_id = rec.AdhocTaskId
      inner join tbl_map_taskstateinitiation tsi on tsicc.col_id = tsi.col_taskstinittaskstinitcc
      where tsi2.col_map_tskstinitcc_tskst = tsicc.col_map_tskstinitcc_tskst and tsicc.col_map_tskstinitcc_tskst = tsi.col_map_tskstinit_tskst)
    where tsi2.col_map_taskstateinitcctaskcc = rec.AdhocTaskId;
  end loop;

  for rec in (select td.col_id as AdhocTaskDepId, td.col_id2, td.col_createdby, td.col_createddate, td.col_modifiedby, td.col_modifieddate, td.col_owner,
              td.col_taskdpchldcctaskstinitcc as AdhocTaskDepChildId, td.col_taskdpprntcctaskstinitcc as AdhocTaskDepParentId, td.col_type as TaskDepType,
              td.col_processorcode as ProcessorCode, td.col_taskdependencyorder, td.col_isdefault
              from tbl_taskdependencycc td
              inner join tbl_map_taskstateinitcc tsi on td.col_taskdpchldcctaskstinitcc = tsi.col_id
              inner join tbl_taskcc tsk on tsi.col_map_taskstateinitcctaskcc = tsk.col_id
              where tsk.col_casecctaskcc = v_CaseId and tsk.col_taskccprocedure is not null
              order by td.col_taskdependencyorder)
  loop
    insert into tbl_taskdependency(col_id2, col_createdby, col_createddate, col_modifiedby, col_modifieddate, col_owner,
                                   col_tskdpndchldtskstateinit, col_tskdpndprnttskstateinit, col_type, col_processorcode, col_taskdependencyorder, col_isdefault, col_taskdeptaskdepcc)
    values (rec.col_id2, rec.col_createdby, rec.col_createddate, rec.col_modifiedby, rec.col_modifieddate, rec.col_owner,
            (select tsic.col_id from tbl_taskdependencycc tdcc
             inner join tbl_map_taskstateinitcc tsiccc on tdcc.col_taskdpchldcctaskstinitcc = tsiccc.col_id
             inner join tbl_map_taskstateinitiation tsic on tsiccc.col_taskstinitcctaskstinit = tsic.col_id
             where tdcc.col_id = rec.AdhocTaskDepId),
             (select tsip.col_id from tbl_taskdependencycc tdcc
             inner join tbl_map_taskstateinitcc tsiccp on tdcc.col_taskdpprntcctaskstinitcc = tsiccp.col_id
             inner join tbl_map_taskstateinitiation tsip on tsiccp.col_taskstinitcctaskstinit = tsip.col_id
             where tdcc.col_id = rec.AdhocTaskDepId),
             rec.TaskDepType, rec.ProcessorCode, rec.col_taskdependencyorder, rec.col_isdefault, rec.AdhocTaskDepId);
    update tbl_taskdependencycc set col_taskdepcctaskdep = (select col_id from tbl_taskdependency where col_taskdeptaskdepcc = rec.AdhocTaskDepId)
    where col_id = rec.AdhocTaskDepId;
  end loop;
  
  for rec in (select se.col_id, se.col_attemptcount, se.col_code, se.col_createdby, se.col_createddate, se.col_id2, se.col_intervalds, se.col_intervalym, se.col_isrequired, se.col_maxattempts,
              se.col_modifiedby, se.col_modifieddate, se.col_owner, se.col_slaeventcccasecc, se.col_slaeventcctaskcc, se.col_slaeventcctasktemplate, se.col_slaeventcc_dateeventtype,
              se.col_slaeventcc_slaeventlevel, se.col_slaeventcc_slaeventtype, se.col_slaeventcc_tasksystype, se.col_slaeventorder, tsk.col_taskcctask
              from tbl_slaeventcc se
              inner join tbl_taskcc tsk on se.col_slaeventcctaskcc = tsk.col_id
              where tsk.col_casecctaskcc = v_CaseId and tsk.col_taskccprocedure is not null
              order by se.col_slaeventorder)
  loop
    insert into tbl_slaevent(col_slaeventslaeventcc, col_attemptcount, col_code, col_createdby, col_createddate, col_id2, col_intervalds, col_intervalym, col_isrequired, col_maxattempts,
                             col_modifiedby, col_modifieddate, col_owner, col_slaeventtask, col_slaeventtasktemplate, col_slaevent_dateeventtype,
                             col_slaevent_slaeventlevel, col_slaeventdict_slaeventtype, col_slaeventdict_tasksystype, col_slaeventorder)
    values (rec.col_id, rec.col_attemptcount, rec.col_code, rec.col_createdby, rec.col_createddate, rec.col_id2, rec.col_intervalds, rec.col_intervalym, rec.col_isrequired, rec.col_maxattempts,
            rec.col_modifiedby, rec.col_modifieddate, rec.col_owner, rec.col_taskcctask, rec.col_slaeventcctasktemplate, rec.col_slaeventcc_dateeventtype,
            rec.col_slaeventcc_slaeventlevel, rec.col_slaeventcc_slaeventtype, rec.col_slaeventcc_tasksystype, rec.col_slaeventorder);
    update tbl_slaeventcc set col_slaeventccslaevent = (select col_id from tbl_slaevent where col_slaeventslaeventcc = rec.col_id)
    where col_id = rec.col_id;
    for rec2 in (select col_actionorder, col_code, col_createdby, col_createddate, col_description, col_id, col_modifiedby, col_modifieddate, col_name, col_processorcode,
                 col_slaactioncc_slaeventlevel
                 from tbl_slaactioncc
                 where col_slaactionccslaeventcc = rec.col_id)
    loop
      insert into tbl_slaaction(col_actionorder, col_code, col_createdby, col_createddate, col_description, col_modifiedby, col_modifieddate, col_name, col_processorcode,
                 col_slaaction_slaeventlevel, col_slaactionslaevent, col_slaactionslaactioncc)
      values (rec2.col_actionorder, rec2.col_code, rec2.col_createdby, rec2.col_createddate, rec2.col_description, rec2.col_modifiedby, rec2.col_modifieddate,
              rec2.col_name, rec2.col_processorcode, rec2.col_slaactioncc_slaeventlevel, (select col_slaeventccslaevent from tbl_slaeventcc where col_id = rec.col_id), rec2.col_id);
      update tbl_slaactioncc set col_slaactionccslaaction = (select col_id from tbl_slaaction where col_slaactionslaactioncc = rec2.col_id)
      where col_id = rec2.col_id;
    end loop;
  end loop;

  for rec in (select te.col_id, te.col_id2, te.col_taskeventcctaskstinitcc, te.col_taskeventmomnttaskeventcc, te.col_processorcode, te.col_taskeventorder, te.col_taskeventsnctptaskeventcc,
              te.col_taskeventcctaskevent, te.col_taskeventtypetaskeventcc, te.col_code, te.col_createdby, te.col_createddate, te.col_modifiedby, te.col_modifieddate, te.col_owner
              from tbl_taskeventcc te
              inner join tbl_map_taskstateinitcc tsi on te.col_taskeventcctaskstinitcc = tsi.col_id
              inner join tbl_taskcc tsk on tsi.col_map_taskstateinitcctaskcc = tsk.col_id
              where tsk.col_casecctaskcc = v_CaseId and tsk.col_taskccprocedure is not null
              order by te.col_taskeventorder)
  loop
    insert into tbl_taskevent(col_code, col_createdby, col_createddate, col_id2, col_modifiedby, col_modifieddate, col_owner, col_processorcode,
                              col_taskeventmomenttaskevent, col_taskeventorder, col_taskeventtaskeventcc, col_taskeventtaskstateinit,
                              col_taskeventtypetaskevent, col_tskeventsynctypetaskevent)
    values (rec.col_code, rec.col_createdby, rec.col_createddate, rec.col_id2, rec.col_modifiedby, rec.col_modifieddate, rec.col_owner, rec.col_processorcode,
            rec.col_taskeventmomnttaskeventcc, rec.col_taskeventorder, rec.col_id,
            (select col_taskstinitcctaskstinit from tbl_map_taskstateinitcc where col_id = rec.col_taskeventcctaskstinitcc),
            rec.col_taskeventtypetaskeventcc, rec.col_taskeventsnctptaskeventcc);
    update tbl_taskeventcc set col_taskeventcctaskevent = (select col_id from tbl_taskevent where col_taskeventtaskeventcc = rec.col_id)
    where col_id = rec.col_id;
  end loop;

  --AUTORULEPARAMETERS FOR TASKSTATEINITIATION RULES
  for rec in (select arp.col_autoruleparamcccasedepcc, arp.col_autoruleparamcccasetype, arp.col_autoruleparamccparamconf, arp.col_autoruleparamcctaskcc, arp.col_autoruleparamcctaskdepcc,
                     arp.col_autoruleparccautorulepar, arp.col_autoruleparccslaactioncc, arp.col_caseeventccautoruleparcc,
                     arp.col_code, arp.col_createdby, arp.col_createddate, arp.col_id, arp.col_issystem, arp.col_modifiedby, arp.col_modifieddate, arp.col_owner,
                     arp.col_paramcode, arp.col_paramvalue,
                     arp.col_ruleparcc_casestateinitcc, arp.col_ruleparcc_taskstateinitcc, arp.col_taskeventccautoruleparmcc, arp.col_tasksystypeautoruleparcc,
                     arp.col_tasktemplateautoruleparcc
                     from tbl_autoruleparamcc arp
                     inner join tbl_map_taskstateinitcc tsi on arp.col_ruleparcc_taskstateinitcc = tsi.col_id
                     inner join tbl_taskcc tsk on tsi.col_map_taskstateinitcctaskcc = tsk.col_id
                     where tsk.col_casecctaskcc = v_CaseId and tsk.col_taskccprocedure is not null and arp.col_taskeventccautoruleparmcc is null)
  loop
    insert into tbl_autoruleparameter(col_code, col_createdby, col_createddate, col_modifiedby, col_modifieddate, col_owner, col_paramcode, col_paramvalue,
                                      col_ruleparam_taskstateinit, col_autoruleparautoruleparcc)
    values (rec.col_code, rec.col_createdby, rec.col_createddate, rec.col_modifiedby, rec.col_modifieddate, rec.col_owner, rec.col_paramcode, rec.col_paramvalue,
            (select col_taskstinitcctaskstinit from tbl_map_taskstateinitcc where col_id = rec.col_ruleparcc_taskstateinitcc), rec.col_id);
    update tbl_autoruleparamcc set col_autoruleparccautorulepar = (select col_id from tbl_autoruleparameter where col_autoruleparautoruleparcc = rec.col_id)
    where col_id = rec.col_id;
  end loop;

  --AUTORULEPARAMETERS FOR TASKEVENT RULES
  for rec in (select arp.col_autoruleparamcccasedepcc, arp.col_autoruleparamcccasetype, arp.col_autoruleparamccparamconf, arp.col_autoruleparamcctaskcc, arp.col_autoruleparamcctaskdepcc,
                     arp.col_autoruleparccautorulepar, arp.col_autoruleparccslaactioncc, arp.col_caseeventccautoruleparcc,
                     arp.col_code, arp.col_createdby, arp.col_createddate, arp.col_id, arp.col_issystem, arp.col_modifiedby, arp.col_modifieddate, arp.col_owner,
                     arp.col_paramcode, arp.col_paramvalue,
                     arp.col_ruleparcc_casestateinitcc, arp.col_ruleparcc_taskstateinitcc, arp.col_taskeventccautoruleparmcc, arp.col_tasksystypeautoruleparcc,
                     arp.col_tasktemplateautoruleparcc
                     from tbl_autoruleparamcc arp
                     inner join tbl_taskeventcc te on arp.col_taskeventccautoruleparmcc = te.col_id
                     inner join tbl_map_taskstateinitcc tsi on te.col_taskeventcctaskstinitcc = tsi.col_id
                     inner join tbl_taskcc tsk on tsi.col_map_taskstateinitcctaskcc = tsk.col_id
                     where tsk.col_casecctaskcc = v_CaseId and tsk.col_taskccprocedure is not null)
  loop
    insert into tbl_autoruleparameter(col_code, col_createdby, col_createddate, col_modifiedby, col_modifieddate, col_owner, col_paramcode, col_paramvalue,
                                      col_taskeventautoruleparam, col_autoruleparautoruleparcc)
    values (rec.col_code, rec.col_createdby, rec.col_createddate, rec.col_modifiedby, rec.col_modifieddate, rec.col_owner, rec.col_paramcode, rec.col_paramvalue,
            (select col_taskeventcctaskevent from tbl_taskeventcc where col_id = rec.col_taskeventccautoruleparmcc), rec.col_id);
    update tbl_autoruleparamcc set col_autoruleparccautorulepar = (select col_id from tbl_autoruleparameter where col_autoruleparautoruleparcc = rec.col_id)
    where col_id = rec.col_id;
  end loop;
                     
  --AUTORULEPARAMETERS FOR TASK DEPENDENCY RULES
  for rec in (select arp.col_autoruleparamcccasedepcc, arp.col_autoruleparamcccasetype, arp.col_autoruleparamccparamconf, arp.col_autoruleparamcctaskcc, arp.col_autoruleparamcctaskdepcc,
                     arp.col_autoruleparccautorulepar, arp.col_autoruleparccslaactioncc, arp.col_caseeventccautoruleparcc,
                     arp.col_code, arp.col_createdby, arp.col_createddate, arp.col_id, arp.col_issystem, arp.col_modifiedby, arp.col_modifieddate, arp.col_owner,
                     arp.col_paramcode, arp.col_paramvalue,
                     arp.col_ruleparcc_casestateinitcc, arp.col_ruleparcc_taskstateinitcc, arp.col_taskeventccautoruleparmcc, arp.col_tasksystypeautoruleparcc,
                     arp.col_tasktemplateautoruleparcc
                     from tbl_autoruleparamcc arp
                     inner join tbl_taskdependencycc td on arp.col_autoruleparamcctaskdepcc = td.col_id
                     inner join tbl_map_taskstateinitcc tsic on td.col_taskdpchldcctaskstinitcc = tsic.col_id
                     inner join tbl_map_taskstateinitcc tsip on td.col_taskdpprntcctaskstinitcc = tsip.col_id
                     inner join tbl_taskcc tskc on tsic.col_map_taskstateinitcctaskcc = tskc.col_id
                     inner join tbl_taskcc tskp on tsip.col_map_taskstateinitcctaskcc = tskp.col_id
                     where tskc.col_casecctaskcc = v_CaseId and tskc.col_taskccprocedure is not null
                     and tskp.col_casecctaskcc = v_CaseId and tskp.col_taskccprocedure is not null)
  loop
    insert into tbl_autoruleparameter(col_code, col_createdby, col_createddate, col_modifiedby, col_modifieddate, col_owner, col_paramcode, col_paramvalue,
                                      col_autoruleparamtaskdep, col_autoruleparautoruleparcc)
    values (rec.col_code, rec.col_createdby, rec.col_createddate, rec.col_modifiedby, rec.col_modifieddate, rec.col_owner, rec.col_paramcode, rec.col_paramvalue,
            (select col_taskdepcctaskdep from tbl_taskdependencycc where col_id = rec.col_autoruleparamcctaskdepcc), rec.col_id);
    update tbl_autoruleparamcc set col_autoruleparccautorulepar = (select col_id from tbl_autoruleparameter where col_autoruleparautoruleparcc = rec.col_id)
    where col_id = rec.col_id;
  end loop;

  --AUTORULEPARAMETERS FOR SLA ACTION RULES
  for rec in (select arp.col_autoruleparamcccasedepcc, arp.col_autoruleparamcccasetype, arp.col_autoruleparamccparamconf, arp.col_autoruleparamcctaskcc, arp.col_autoruleparamcctaskdepcc,
                     arp.col_autoruleparccautorulepar, arp.col_autoruleparccslaactioncc, arp.col_caseeventccautoruleparcc,
                     arp.col_code, arp.col_createdby, arp.col_createddate, arp.col_id, arp.col_issystem, arp.col_modifiedby, arp.col_modifieddate, arp.col_owner,
                     arp.col_paramcode, arp.col_paramvalue,
                     arp.col_ruleparcc_casestateinitcc, arp.col_ruleparcc_taskstateinitcc, arp.col_taskeventccautoruleparmcc, arp.col_tasksystypeautoruleparcc,
                     arp.col_tasktemplateautoruleparcc
                     from tbl_autoruleparamcc arp
                     inner join tbl_slaactioncc sa on arp.col_autoruleparccslaactioncc = sa.col_id
                     inner join tbl_slaeventcc se on sa.col_slaactionccslaeventcc = se.col_id
                     inner join tbl_taskcc tsk on se.col_slaeventcctaskcc = tsk.col_id
                     where tsk.col_casecctaskcc = v_CaseId and tsk.col_taskccprocedure is not null)
  loop
    insert into tbl_autoruleparameter(col_code, col_createdby, col_createddate, col_modifiedby, col_modifieddate, col_owner, col_paramcode, col_paramvalue,
                                      col_autoruleparamslaaction, col_autoruleparautoruleparcc)
    values (rec.col_code, rec.col_createdby, rec.col_createddate, rec.col_modifiedby, rec.col_modifieddate, rec.col_owner, rec.col_paramcode, rec.col_paramvalue,
            (select col_slaactionccslaaction from tbl_slaactioncc where col_id = rec.col_autoruleparccslaactioncc), rec.col_id);
    update tbl_autoruleparamcc set col_autoruleparccautorulepar = (select col_id from tbl_autoruleparameter where col_autoruleparautoruleparcc = rec.col_id)
    where col_id = rec.col_id;
  end loop;
  -------------------------------------------------------------------------------------------------------------------------------------------------------


  update tbl_cw_workitem cwi set col_activity = (select col_activity from tbl_cw_workitemcc cwicc where cwicc.col_id = cwi.col_id),
  col_cw_workitemprevcasestate = (select col_cw_workitemccprevcasest from tbl_cw_workitemcc cwicc where cwicc.col_id = cwi.col_id),
  col_cw_workitemdict_casestate = (select col_cw_workitemccdict_casest from tbl_cw_workitemcc cwicc where cwicc.col_id = cwi.col_id)
  where col_id = (select col_cw_workitemcase from tbl_case where col_id = v_CaseId);

  update tbl_case cs set col_dateassigned = (select col_dateassigned from tbl_casecc cscc where cscc.col_id = cs.col_id),
  col_dateclosed = (select col_dateclosed from tbl_casecc cscc where cscc.col_id = cs.col_id),
  col_caseppl_workbasket = (select col_caseccppl_workbasket from tbl_casecc cscc where cscc.col_id = cs.col_id),
  col_stp_resolutioncodecase = (select col_stp_resolutioncodecasecc from tbl_casecc cscc where cscc.col_id = cs.col_id),
  col_activity = (select col_activity from tbl_casecc cscc where cscc.col_id = cs.col_id),
  col_workflow = (select col_workflow from tbl_casecc cscc where cscc.col_id = cs.col_id),
  col_casedict_casestate = (select col_caseccdict_casestate from tbl_casecc cscc where cscc.col_id = cs.col_id)
  where col_id = v_CaseId;

  delete from tbl_history where col_historytask in (select col_id from tbl_task where col_casetask = v_CaseId);
  insert into tbl_history(col_lockedexpdate,col_owner,col_description,col_createddate,col_historytask,col_historyprevtaskstate,col_historyprevcasestate,
                            col_historycase,col_lockeddate,col_additionalinfo,col_historynextcasestate,col_createdbyname,col_modifiedby,col_modifieddate,
                            col_issystem,col_historynexttaskstate,col_createdby,col_lockedby,col_activitytimedate, COL_MESSAGETYPEHISTORY, col_historyCreatedBy)
                    (select col_lockedexpdate,col_owner,col_description,col_createddate,col_historycctaskcc,col_historyccprevtaskstate,col_historyccprevcasestate,
                            col_historycccasecc,col_lockeddate,col_additionalinfo,col_historyccnextcasestate,col_createdbyname,col_modifiedby,col_modifieddate,
                            col_issystem,col_historyccnexttaskstate,col_createdby,col_lockedby,col_activitytimedate, COL_MESSAGETYPEHISTORYCC, col_historyCreatedBy
                     from tbl_historycc
                     where col_historycctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId));

  delete from tbl_dateevent where col_dateeventtask in (select col_id from tbl_task where col_casetask = v_CaseId);
  insert into tbl_dateevent(col_datevalue,col_lockedexpdate,col_customdata,col_owner,col_createddate,col_performedby,col_dateeventcase,col_lockeddate,col_datename,col_modifiedby,
                              col_dateeventppl_workbasket,col_dateevent_dateeventtype,col_modifieddate,col_dateeventppl_caseworker,col_dateeventtask,col_createdby,col_lockedby)
                      (select col_datevalue,col_lockedexpdate,col_customdata,col_owner,col_createddate,col_performedby,col_dateeventcccasecc,col_lockeddate,col_datename,col_modifiedby,
                              col_dateeventccppl_workbasket,col_dateeventcc_dateeventtype,col_modifieddate,col_dateeventccppl_caseworker,col_dateeventcctaskcc,col_createdby,col_lockedby
                        from tbl_dateeventcc
                        where col_dateeventcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId));
end;
