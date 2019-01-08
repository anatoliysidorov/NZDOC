DECLARE
    v_caseid            INTEGER;
    v_result            NUMBER;
    v_stateconfigid     INTEGER;
BEGIN
    v_caseid :=:caseid;
	
    BEGIN
        SELECT col_stateconfigcasesystype
        INTO v_stateconfigid
        FROM tbl_dict_casesystype
        WHERE
            col_id = (
                SELECT col_casedict_casesystype
                FROM tbl_case
                WHERE col_id = v_caseid
            );

    EXCEPTION
        WHEN no_data_found THEN
            v_stateconfigid := NULL;
    END;

    BEGIN
        INSERT INTO tbl_slaactionqueue (
            col_slaactionqueueslaaction,
            col_slaactionqueueprocstatus,
            col_slaactionqueueslaevent
        )
		(SELECT
			sa.col_id,
			(
				SELECT col_id
				FROM tbl_dict_processingstatus
				WHERE lower(col_code) = 'new'
			),
			sel.slaeventid
		  FROM
			tbl_slaaction sa
			INNER JOIN tbl_slaevent se ON sa.col_slaactionslaevent = se.col_id
			INNER JOIN (
				SELECT
					sel.taskid,
					sel.caseid,
					sel.slaeventid,
					sel.slapassed,
					ts.col_activity AS taskstateactivity,
					cst.col_activity AS casestateactivity
				FROM
					TABLE ( f_dcm_caseslaeventlist(caseid => v_caseid) ) sel
					INNER JOIN tbl_tw_workitem twi ON sel.taskworkitemid = twi.col_id
					INNER JOIN tbl_dict_taskstate ts ON twi.col_tw_workitemdict_taskstate = ts.col_id
					INNER JOIN tbl_case cs ON sel.caseid = cs.col_id
					INNER JOIN tbl_cw_workitem cwi ON cs.col_cw_workitemcase = cwi.col_id
					INNER JOIN tbl_dict_casestate cst ON cwi.col_cw_workitemdict_casestate = cst.col_id
			) sel ON sa.col_slaactionslaevent = sel.slaeventid
			INNER JOIN tbl_task tsk ON sel.taskid = tsk.col_id
			INNER JOIN tbl_case cs ON tsk.col_casetask = cs.col_id
			INNER JOIN tbl_dict_tasksystype tst ON tsk.col_taskdict_tasksystype = tst.col_id
			INNER JOIN tbl_dict_casesystype cst ON cs.col_casedict_casesystype = cst.col_id
			INNER JOIN tbl_dateevent des ON sel.taskid = des.col_dateeventtask
											AND se.col_slaevent_dateeventtype = des.col_dateevent_dateeventtype
		  WHERE
			sel.caseid = v_caseid
			AND   lower(sel.slapassed) = 'passed'
			AND   sel.casestateactivity <> f_DCM_getCaseClosedState2(stateconfigid => cst.col_stateconfigcasesystype)--'root_CS_Status_CLOSED'
			AND   sel.taskstateactivity <> f_dcm_gettaskclosedstate2(stateconfigid => tst.col_stateconfigtasksystype)
			AND   des.col_datevalue = (
				SELECT MAX(col_datevalue)
				FROM tbl_dateevent
				WHERE col_dateeventtask = sel.taskid AND col_dateevent_dateeventtype = se.col_slaevent_dateeventtype
			)
			AND   se.col_attemptcount < se.col_maxattempts
			AND   sa.col_id NOT IN (
				SELECT
					saq.col_slaactionqueueslaaction
				FROM
					tbl_slaactionqueue saq
					INNER JOIN tbl_slaaction sa ON saq.col_slaactionqueueslaaction = sa.col_id
					INNER JOIN TABLE ( f_dcm_caseslaeventlist(caseid => v_caseid) ) sel ON sa.col_slaactionslaevent = sel.slaeventid
				WHERE
					sel.caseid = v_caseid
					AND   lower(sel.slapassed) = 'passed'
			)
		);

    EXCEPTION
        WHEN dup_val_on_index THEN
            RETURN -1;
    END;

    v_result := f_dcm_slaactionqueueproc(caseid => v_caseid);
END;