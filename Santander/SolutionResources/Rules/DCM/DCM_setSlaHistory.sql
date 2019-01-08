DECLARE
    v_result NUMBER;
BEGIN
    FOR rec IN(SELECT    se.col_id as slaeventid
    FROM       tbl_slaevent se
    INNER JOIN(SELECT    sell.taskid,
                          sell.caseid,
                          sell.slaeventid,
                          sell.slapassed,
                          ts.col_activity AS taskstateactivity,
                          cst.col_activity AS casestateactivity
               FROM       TABLE(f_dcm_caseslaeventlist(caseid => :caseid)) sell
               INNER JOIN tbl_tw_workitem twi    ON sell.taskworkitemid = twi.col_id
               INNER JOIN tbl_dict_taskstate ts  ON twi.col_tw_workitemdict_taskstate = ts.col_id
               INNER JOIN tbl_case cs            ON sell.caseid = cs.col_id
               INNER JOIN tbl_cw_workitem cwi    ON cs.col_cw_workitemcase = cwi.col_id
               INNER JOIN tbl_dict_casestate cst ON cwi.col_cw_workitemdict_casestate = cst.col_id) sel ON se.col_id = sel.slaeventid
    INNER JOIN tbl_task tsk                      ON sel.taskid = tsk.col_id
    INNER JOIN tbl_case cs                       ON tsk.col_casetask = cs.col_id
    INNER JOIN tbl_dict_tasksystype tst          ON tsk.col_taskdict_tasksystype = tst.col_id
    INNER JOIN tbl_dict_casesystype cst          ON cs.col_casedict_casesystype = cst.col_id
    INNER JOIN tbl_dateevent des                 ON sel.taskid = des.col_dateeventtask AND se.col_slaevent_dateeventtype = des.col_dateevent_dateeventtype
    WHERE      sel.caseid = :caseid
               AND lower(sel.slapassed) = 'passed'
               AND sel.casestateactivity <> f_dcm_getcaseclosedstate2(stateconfigid => cst.col_stateconfigcasesystype) --'root_CS_Status_CLOSED'
               AND sel.taskstateactivity <> f_dcm_gettaskclosedstate2(stateconfigid => tst.col_stateconfigtasksystype)
               AND des.col_datevalue =(SELECT MAX(col_datevalue)
               FROM    tbl_dateevent
               WHERE   col_dateeventtask = sel.taskid
                       AND col_dateevent_dateeventtype = se.col_slaevent_dateeventtype)
               AND se.col_attemptcount < se.col_maxattempts)
    LOOP
        v_result := f_hist_createhistoryfn(additionalinfo => NULL,
                                           issystem => 0,
                                           message => NULL,
                                           messagecode => 'sla_TaskPassed',
                                           targetid => rec.slaeventid,
                                           targettype => 'slaevent');
        NULL;
    END LOOP;
END;