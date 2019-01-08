SELECT    h.col_additionalinfo AS AdditionalInfo,
          h.col_description AS Description,
          h.col_id AS Id,
          h.col_historycase AS Case_Id,
          h.col_historytask AS Task_Id,
          F_getnamefromaccesssubject(h.col_historyCreatedBy) AS CreatedBy_Name,
          F_util_getdrtnfrmnow(h.col_activitytimedate) AS CreatedDuration,
          h.col_historyprevtaskstate AS Task_PrevState,
          h.col_historynexttaskstate AS Task_NextState,
          h.col_historyprevcasestate AS Case_PrevState,
          h.col_historynextcasestate AS Case_NextState,
          mt.col_id AS MessageType_Id,
          mt.col_code AS MessageType_Code,
          mt.col_name AS MessageType_Name,
          mt.col_colortheme AS MessageType_ColorTheme,
          --TASK INFO
          tv.col_name AS TASK_NAME,
          tv.col_TaskId AS TASK_TASKID,
          tv.col_taskorder AS TASK_TASKORDER,
          em.col_code AS TASK_EXECUTION,
          tv.col_depth AS TASK_DEPTH,
          tv.col_leaf AS TASK_LEAF,
          tv.col_icon AS TASKICON,
          NVL(tv.col_parentid,0) AS CALCPARENTID
FROM     (
          --If CASE ID AND TASK ID is present, get only direct Case history
          SELECT  col_id,
                  col_historyCreatedBy,
                  col_activitytimedate,
                  col_additionalinfo,
                  col_description,
                  col_historycase,
                  col_historytask,
                  col_historyprevtaskstate,
                  col_historynexttaskstate,
                  col_historyprevcasestate,
                  col_historynextcasestate,
                  COL_MESSAGETYPEHISTORY
          FROM    tbl_history
          WHERE   :Task_Id > 0
                  AND col_historycase = :Case_Id
                  AND(col_historytask IS NULL
                  OR col_historytask = 0)
          --If CASE ID is present but TASK ID is not, get all Case hsitory with all Task history
          UNION ALL
          SELECT col_id,
                 col_historyCreatedBy,
                 col_activitytimedate,
                 col_additionalinfo,
                 col_description,
                 col_historycase,
                 col_historytask,
                 col_historyprevtaskstate,
                 col_historynexttaskstate,
                 col_historyprevcasestate,
                 col_historynextcasestate,
                 COL_MESSAGETYPEHISTORY
          FROM   tbl_history
          WHERE (:Task_Id IS NULL OR :Task_Id = 0)
                 AND col_historycase = :Case_Id
          UNION ALL
          SELECT col_id,
                 col_historyCreatedBy,
                 col_activitytimedate,
                 col_additionalinfo,
                 col_description,
                 col_historycase,
                 col_historytask,
                 col_historyprevtaskstate,
                 col_historynexttaskstate,
                 col_historyprevcasestate,
                 col_historynextcasestate,
                 COL_MESSAGETYPEHISTORY
          FROM   tbl_history
          WHERE (:Task_Id IS NULL OR :Task_Id = 0)
                 AND(col_historytask IN(SELECT COL_ID
                 FROM    TBL_TASK
                 WHERE   COL_CASETASK = :Case_Id))
          --If TASK ID is present, get all direct Task history
          UNION ALL
          SELECT col_id,
                 col_historyCreatedBy,
                 col_activitytimedate,
                 col_additionalinfo,
                 col_description,
                 col_historycase,
                 col_historytask,
                 col_historyprevtaskstate,
                 col_historynexttaskstate,
                 col_historyprevcasestate,
                 col_historynextcasestate,
                 COL_MESSAGETYPEHISTORY
          FROM   tbl_history
          WHERE  col_historytask = :Task_Id) h
LEFT JOIN TBL_TASK tv                 ON(tv.col_id = h.col_historytask)
LEFT JOIN TBL_DICT_executionMethod em ON em.col_id = tv.col_taskdict_executionmethod
LEFT JOIN tbl_DICT_MessageType mt     ON(mt.col_id = h.COL_MESSAGETYPEHISTORY)
ORDER BY  h.col_activitytimedate DESC