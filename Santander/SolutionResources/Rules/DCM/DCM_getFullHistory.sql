DECLARE
    --input
    v_case_id integer;
    v_task_id integer;
BEGIN
    --input
    v_task_id := :task_Id;
    v_case_id := NVL(:case_Id,f_DCM_getCaseIdByTaskId(v_task_id));
    --system
    :ErrorCode := 0;
    :ErrorMessage := '';
    --calculate root task node if no task id was passed in
    IF NVL(v_task_id,0) = 0 THEN
        BEGIN
            SELECT col_id
            INTO
                   v_task_id
            FROM   tbl_task
            WHERE  col_casetask = v_case_id
                   AND Nvl(col_parentid,0) = 0;
        
        EXCEPTION
        WHEN no_data_found THEN
            v_task_id := NULL;
        WHEN too_many_rows THEN
            v_task_id := NULL;
        END;
    END IF;
    --GET CASE INFO
    OPEN :CUR_CASE FOR
    SELECT c.id as ID,
           c.caseid as CASEID,
           c.SUMMARY as SUMMARY,
           c.CaseState_name AS CaseState_name,
           c.CaseState_ISSTART AS CaseState_ISSTART,
           c.CaseState_ISRESOLVE AS CaseState_ISRESOLVE,
           c.CaseState_ISFINISH AS CaseState_ISFINISH,
           c.CaseState_ISASSIGN AS CaseState_ISASSIGN,
           c.CaseState_ISFIX AS CaseState_ISFIX,
           c.CaseState_ISINPROCESS as CaseState_ISINPROCESS,
           c.CaseState_ISDEFAULTONCREATE as CaseState_ISDEFAULTONCREATE,
           c.ResolutionCode_Name as ResolutionCode_Name,
           F_getnamefromaccesssubject(c.createdby) AS CreatedBy_Name,
           F_util_getdrtnfrmnow(c.createddate) AS CreatedDuration
    FROM   vw_DCM_SimpleCaseAC c
    WHERE  c.id = v_case_id;
    
    --GET TASKS INFO
    OPEN :CUR_TASKS FOR
    SELECT    tv.col_id AS ID,
              tv.col_name AS NAME,
              tv.col_taskorder AS TASKORDER,
              em.col_name AS EXECUTIONMETHOD_NAME,
              em.col_code AS EXECUTIONMETHOD_CODE,
              tv.col_depth AS DEPTH,
              tv.col_leaf AS LEAF,
              dts.col_name AS TASKSTATE_NAME,
              dts.col_isdefaultoncreate AS TASKSTATE_ISDEFAULTONCREATE,
              dts.col_isstart AS TASKSTATE_ISSTART,
              dts.col_isresolve AS TASKSTATE_ISRESOLVE,
              dts.col_isfinish AS TASKSTATE_ISFINISH,
              rt.col_name AS RESOLUTIONCODE_NAME,
              tv.col_icon AS TASKICON,
              tv.col_parentid AS CALCPARENTID,
              F_getnamefromaccesssubject(tv.col_createdby) AS CreatedBy_Name,
              F_util_getdrtnfrmnow(tv.col_createddate) AS CreatedDuration
    FROM      TBL_TASK tv
    LEFT JOIN tbl_tw_workitem tw          ON tv.col_tw_workitemtask = tw.col_id
    LEFT JOIN tbl_dict_taskstate dts      ON tw.col_tw_workitemdict_taskstate = dts.col_id
    LEFT JOIN TBL_DICT_executionMethod em ON em.col_id = tv.col_taskdict_executionmethod
    LEFT JOIN tbl_stp_resolutioncode rt   ON tv.col_taskstp_resolutioncode = rt.col_id
    WHERE     tv.col_id = v_task_id
              OR tv.col_parentid = v_task_id;
    
    --GET HISTORY FOR ALL RELEVANT TASKS AND CASE
    OPEN :CUR_FULLHISTORY FOR
    SELECT    h.col_additionalinfo AS AdditionalInfo,
              h.col_description AS Description,
              h.col_id AS Id,
              h.col_historycase AS Case_Id,
              h.col_historytask AS Task_Id,
              F_getnamefromaccesssubject(h.col_historyCreatedBy) AS CreatedBy_Name,
              F_util_getdrtnfrmnow(h.col_ActivityTimeDate) AS CreatedDuration,
              --task states
              ts1.col_id AS PTState_ID,
              ts1.col_name AS PTState_NAME,
              ts1.col_isstart AS PTState_ISSTART,
              ts1.col_isfinish AS PTState_ISFINISH,
              ts1.col_isassign AS PTState_ISASSIGN,
              ts1.col_isresolve AS PTState_ISRESOLVE,
              ts1.col_isdefaultoncreate AS PTState_ISDEFAULTONCREATE,
              ts1.col_isdefaultoncreate2 AS PTState_ISINPROCESS,
              ts2.col_id AS NTState_ID,
              ts2.col_name AS NTState_NAME,
              ts2.col_isstart AS NTState_ISSTART,
              ts2.col_isfinish AS NTState_ISFINISH,
              ts2.col_isassign AS NTState_ISASSIGN,
              ts2.col_isresolve AS NTState_ISRESOLVE,
              ts2.col_isdefaultoncreate AS NTState_ISDEFAULTONCREATE,
              ts2.col_isdefaultoncreate2 AS NTState_ISINPROCESS,
              --case states
              cs1.col_id AS PCState_ID,
              cs1.col_name AS PCState_NAME,
              ms1.col_id AS PMilestone_ID,
              ms1.col_name AS PMilestone_NAME,
              cs1.col_isstart AS PCState_ISSTART,
              cs1.col_isfinish AS PCState_ISFINISH,
              cs1.col_isassign AS PCState_ISASSIGN,
              cs1.col_isresolve AS PCState_ISRESOLVE,
              cs1.col_isfix AS PCState_ISFIX,
              cs1.col_isdefaultoncreate AS PCState_ISDEFAULTONCREATE,
              cs1.col_isdefaultoncreate2 AS PCState_ISINPROCESS,
              cs2.col_id AS NCState_ID,
              cs2.col_name AS NCState_NAME,
              ms2.col_id AS NMilestone_ID,
              ms2.col_name AS NMilestone_NAME,
              cs2.col_isstart AS NCState_ISSTART,
              cs2.col_isfinish AS NCState_ISFINISH,
              cs2.col_isassign AS NCState_ISASSIGN,
              cs2.col_isresolve AS NCState_ISRESOLVE,
              cs2.col_isfix AS NCState_ISFIX,
              cs2.col_isdefaultoncreate AS NCState_ISDEFAULTONCREATE,
              cs2.col_isdefaultoncreate2 AS NCState_ISINPROCESS
    FROM     (SELECT col_id,
                      col_historyCreatedBy,
                      col_ActivityTimeDate,
                      col_additionalinfo,
                      col_description,
                      col_historycase,
                      col_historytask,
                      col_historyprevtaskstate,
                      col_historynexttaskstate,
                      col_historyprevcasestate,
                     col_historynextcasestate,
                     col_historyprevstate,
                     col_historynextstate
              FROM    tbl_history
              WHERE   col_historycase = v_case_id
              UNION ALL
              SELECT col_id,
                     col_historyCreatedBy,
                     col_ActivityTimeDate,
                     col_additionalinfo,
                     col_description,
                     col_historycase,
                     col_historytask,
                     col_historyprevtaskstate,
                     col_historynexttaskstate,
                     col_historyprevcasestate,
                     col_historynextcasestate,
                     col_historyprevstate,
                     col_historynextstate
              FROM   tbl_history
              WHERE  col_historytask = v_task_id
              UNION ALL
              SELECT col_id,
                     col_historyCreatedBy,
                     col_ActivityTimeDate,
                     col_additionalinfo,
                     col_description,
                     col_historycase,
                     col_historytask,
                     col_historyprevtaskstate,
                     col_historynexttaskstate,
                     col_historyprevcasestate,
                     col_historynextcasestate,
                     col_historyprevstate,
                     col_historynextstate
              FROM   tbl_history
              WHERE  col_historytask IN(SELECT col_id
                     FROM    tbl_task
                     WHERE   col_parentid = v_task_id)) h
    left join tbl_task t             ON(t.col_id = h.col_historytask)
    left join tbl_dict_taskstate ts1 ON(ts1.col_id = h.col_historyprevtaskstate)
    left join tbl_dict_taskstate ts2 ON(ts2.col_id = h.col_historynexttaskstate)
    left join tbl_dict_casestate cs1 ON(cs1.col_id = h.col_historyprevcasestate)
    left join tbl_dict_casestate cs2 ON(cs2.col_id = h.col_historynextcasestate)
    left join tbl_dict_state ms1 ON(ms1.col_id = h.col_historyprevstate)
    left join tbl_dict_state ms2 ON(ms2.col_id = h.col_historynextstate)
    WHERE    (h.col_historycase = v_case_id
              OR t.col_id = v_task_id
              OR t.col_parentid = v_task_id)
              AND((h.col_historytask IS NOT NULL
              AND col_historyprevtaskstate != col_historynexttaskstate)
              OR(h.col_historycase IS NOT NULL
              AND col_historyprevcasestate != col_historynextcasestate))
    ORDER BY  h.col_ActivityTimeDate ASC;

END;