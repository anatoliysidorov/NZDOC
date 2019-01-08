DECLARE
    v_result NUMBER;
    v_geLinkedCacheRecords NUMBER;
    v_CaseId Integer;
BEGIN
    v_CaseId := :CaseId;
    v_geLinkedCacheRecords := :geLinkedCacheRecords;
    FOR rec IN(SELECT    se.col_id as slaeventid, tsk.col_id as TaskId
    FROM       tbl_slaeventcc se
    INNER JOIN(SELECT    sell.taskid,
                          sell.caseid,
                          sell.slaeventid,
                          sell.slapassed,
                          ts.col_activity AS taskstateactivity,
                          cst.col_activity AS casestateactivity
               FROM       TABLE(f_DCM_caseCCSlaEventList(caseid => caseid,geLinkedCacheRecords=>v_geLinkedCacheRecords)) sell
               INNER JOIN tbl_tw_workitemcc twi  ON sell.taskworkitemid = twi.col_id
               INNER JOIN tbl_dict_taskstate ts  ON twi.col_tw_workitemccdict_taskst = ts.col_id
               INNER JOIN tbl_casecc cs          ON sell.caseid = cs.col_id
               INNER JOIN tbl_cw_workitemcc cwi  ON cs.col_cw_workitemcccasecc = cwi.col_id
               INNER JOIN tbl_dict_casestate cst ON cwi.col_cw_workitemccdict_casest = cst.col_id) sel ON se.col_id = sel.slaeventid
    INNER JOIN tbl_taskcc tsk                    ON sel.taskid = tsk.col_id
    INNER JOIN tbl_casecc cs                     ON tsk.col_casecctaskcc = cs.col_id
    INNER JOIN tbl_dict_tasksystype tst          ON tsk.col_taskccdict_tasksystype = tst.col_id
    INNER JOIN tbl_dict_casesystype cst          ON cs.col_caseccdict_casesystype = cst.col_id
    INNER JOIN tbl_dateeventcc des               ON sel.taskid = des.col_dateeventcctaskcc AND se.col_slaeventcc_dateeventtype = des.col_dateeventcc_dateeventtype
    WHERE      sel.caseid = v_CaseId
               AND lower(sel.slapassed) = 'passed'
               AND sel.casestateactivity <> f_DCM_getCaseClosedState2(stateconfigid => cst.col_stateconfigcasesystype) --'root_CS_Status_CLOSED'
               AND sel.taskstateactivity <> f_dcm_getTaskClosedState2(stateconfigid => tst.col_stateconfigtasksystype)
               AND des.col_datevalue =(SELECT MAX(col_datevalue)
               FROM    tbl_dateeventcc
               WHERE   col_dateeventcctaskcc = sel.taskid
                       AND col_dateeventcc_dateeventtype = se.col_slaeventcc_dateeventtype)
               AND se.col_attemptcount < se.col_maxattempts)
    LOOP
        v_result := f_HIST_createHistoryContextFn(additionalinfo => NULL,
                                           issystem => 0,
                                           message => NULL,
                                           messagecode => 'sla_TaskPassed',
                                           targetid => rec.slaeventid,
                                           targettype => 'slaevent',
										   AttachTargetId => rec.TaskId,
										   AttachTargetType => 'task'
										   );
        NULL;
    END LOOP;
END;