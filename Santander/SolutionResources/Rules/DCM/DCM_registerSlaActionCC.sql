declare
  v_CaseId Integer;
  v_result number;  
  v_StateConfigId Integer;
  v_geLinkedCacheRecords NUMBER;
  
begin
  v_CaseId := :CaseId;
  v_geLinkedCacheRecords := :geLinkedCacheRecords;
  
  begin
    select col_stateconfigcasesystype into v_StateConfigId 
    from tbl_dict_casesystype 
    where col_id = (select col_casedict_casesystype 
                    from tbl_case 
                    where col_id = v_CaseId);
    exception
    when NO_DATA_FOUND then
    v_StateConfigId := null;
  end;
    
  begin
    insert into tbl_slaactionqueue(col_slaactionqueueslaaction,
                                   col_slaactionqueueprocstatus, 
                                   col_slaactionqueueslaevent)
      (select sa.col_id, 
        (select col_id 
         from tbl_dict_processingstatus 
         where col_code = 'NEW'), 
         sel.SlaEventId
         from tbl_slaactioncc sa
         inner join tbl_slaeventcc se on sa.col_slaactionccslaeventcc = se.col_id
         inner join (select count(*), sel.TaskId, sel.CaseId, sel.SlaEventId, sel.SlaPassed, ts.col_activity as TaskStateActivity, cst.col_activity as CaseStateActivity
                     from table(f_DCM_caseCCSlaEventList(CaseId => v_CaseId, geLinkedCacheRecords=>v_geLinkedCacheRecords)) sel
                     inner join tbl_tw_workitemcc twi on sel.taskworkitemid = twi.col_id
                     inner join tbl_dict_taskstate ts on twi.col_tw_workitemccdict_taskst = ts.col_id
                     inner join tbl_casecc cs on sel.caseid = cs.col_id
                     inner join tbl_cw_workitemcc cwi on cs.col_cw_workitemcccasecc = cwi.col_id
                     inner join tbl_dict_casestate cst on cwi.col_cw_workitemccdict_casest = cst.col_id
                     group by sel.TaskId, sel.CaseId, sel.SlaEventId, sel.SlaPassed, ts.col_activity, cst.col_activity
                    ) sel on sa.col_slaactionccslaeventcc = sel.SlaEventId
         inner join tbl_taskcc tsk on sel.TaskId = tsk.col_id
         INNER JOIN tbl_casecc cs1 ON tsk.col_casecctaskcc = cs1.col_id
         inner join tbl_dict_tasksystype tst1 on tsk.col_taskccdict_tasksystype = tst1.col_id
         INNER JOIN tbl_dict_casesystype cst1 ON cs1.col_caseccdict_casesystype = cst1.col_id
         left join (select count(*), des.col_dateeventcctaskcc, des.col_dateeventcc_dateeventtype 
                    from tbl_dateeventcc des
                    group by des.col_dateeventcctaskcc, des.col_dateeventcc_dateeventtype) subs
                    on sel.TaskId = subs.col_dateeventcctaskcc and se.col_slaeventcc_dateeventtype = subs.col_dateeventcc_dateeventtype
         /*
         inner join tbl_dateeventcc des on sel.TaskId = des.col_dateeventcctaskcc
                                      and se.col_slaeventcc_dateeventtype = des.col_dateeventcc_dateeventtype
         */
         where sel.CaseId = v_CaseId
         and sel.SlaPassed = 'Passed'
         and sel.CaseStateActivity <> f_DCM_getCaseClosedState2(stateconfigid => cst1.col_stateconfigcasesystype)--'root_CS_Status_CLOSED' 
         and sel.TaskStateActivity <> f_dcm_getTaskClosedState2(StateConfigId => tst1.col_stateconfigtasksystype)
         /*
         and des.col_datevalue = (select max (col_datevalue) 
                                  from tbl_dateeventcc 
                                  where col_dateeventcctaskcc = sel.TaskId 
                                  and col_dateeventcc_dateeventtype = se.col_slaeventcc_dateeventtype)
         */
         and se.col_attemptcount < se.col_maxattempts
         and sa.col_id not in (select saq.col_slaactionqueueslaaction
                              from tbl_slaactionqueue saq
                              inner join tbl_slaactioncc sa on saq.col_slaactionqueueslaaction = sa.col_id
                              inner join table(f_DCM_caseCCSlaEventList(CaseId => v_CaseId, geLinkedCacheRecords=>v_geLinkedCacheRecords)) sel on sa.col_slaactionccslaeventcc = sel.SlaEventId
                              where saq.col_slaactionqueueprocstatus = (select col_id from tbl_dict_processingstatus where col_code = 'NEW')
                              and sel.CaseId = v_CaseId
                              and sel.SlaPassed = 'Passed'));
     exception
       when DUP_VAL_ON_INDEX then
         return -1;
  end;
  v_result := f_DCM_slaActionCCQueueProc(CaseId => v_CaseId);
end;