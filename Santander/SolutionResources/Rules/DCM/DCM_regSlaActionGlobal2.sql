declare
  v_result number;
begin
  for rec in
      (select sa.col_id as SlaActionId, sel.SlaEventId as SlaEventId, sel.CaseId as CaseId
         from tbl_slaaction sa
         inner join tbl_slaevent se on sa.col_slaactionslaevent = se.col_id
         inner join vw_DCM_SlaEventListExt sel on sa.col_slaactionslaevent = sel.SlaEventId
         inner join tbl_task tsk on sel.TaskId = tsk.col_id
         inner join tbl_dict_tasksystype tst on tsk.col_taskdict_tasksystype = tst.col_id
         inner join tbl_dateevent des on sel.TaskId = des.col_dateeventtask
                                      and se.col_slaevent_dateeventtype = des.col_dateevent_dateeventtype
         where sel.SlaPassed = 'Passed'
         and sel.CaseStateActivity <> f_dcm_getCaseClosedState2(StateConfigId => (select col_stateconfigcasesystype from tbl_dict_casesystype where col_id = 
                                       (select col_casedict_casesystype from tbl_case where col_id =
                                       (select col_casetask from tbl_task where col_id = tsk.col_id))))
         and sel.TaskStateActivity <> f_dcm_getTaskClosedState2(StateConfigId => tst.col_stateconfigtasksystype)
         and des.col_datevalue = (select max (col_datevalue) from tbl_dateevent where col_dateeventtask = sel.TaskId and col_dateevent_dateeventtype = se.col_slaevent_dateeventtype)
         and se.col_attemptcount < se.col_maxattempts
         and sa.col_id not in (select saq.col_slaactionqueueslaaction
                              from tbl_slaactionqueue saq
                              inner join tbl_slaaction sa on saq.col_slaactionqueueslaaction = sa.col_id
                              inner join vw_DCM_SlaEventList sel on sa.col_slaactionslaevent = sel.SlaEventId
                              where sel.SlaPassed = 'Passed'))
  loop
    v_result := f_dcm_invalidatecase(CaseId => rec.CaseId);
  end loop;
end;