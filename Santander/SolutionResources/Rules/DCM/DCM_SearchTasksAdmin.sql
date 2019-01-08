SELECT
    --DATA FROM VIEW
    tv.*,
    tv.TaskName AS CalcName,
    
    --CALC SLAs AND OTHER DURATIONS
    F_util_getdrtnfrmnow(tv.GoalSlaDateTime) AS GoalSlaDuration,
    F_util_getdrtnfrmnow(tv.DLineSlaDateTime) AS DLineSlaDuration,
    F_getnamefromaccesssubject(tv.createdby) AS createdby_name,
    F_util_getdrtnfrmnow(tv.createddate) AS createdduration,
    F_getnamefromaccesssubject(tv.MODIFIEDBY) AS modifiedby_name,
    F_util_getdrtnfrmnow(tv.MODIFIEDDATE) AS modifiedduration,
    
    --GET CASE INFO
    cse.COL_CASEID AS CASEID_NAME,
    cse.COL_CASEDICT_CASESYSTYPE AS CASESYSTYPE_ID,
    cst.COL_NAME AS CASESYSTYPE_NAME,
    cst.COL_COLORCODE AS CASESYSTYPE_COLORCODE,
    cst.COL_ICONCODE AS CASESYSTYPE_ICONCODE,
    cwb.COL_NAME AS CASE_WORKBASKETNAME,
    tv.TASKTYPE_NAME AS TASKSYSTYPE_NAME,
    
    -- calculate Parentid
    tv.parentid AS CalcParentId

FROM vw_dcm_simpletasksla tv
    LEFT JOIN tbl_case cse             ON cse.col_id = tv.CASEID
    LEFT JOIN TBL_DICT_CASESYSTYPE cst ON cst.COL_ID = cse.COL_CASEDICT_CASESYSTYPE
    LEFT JOIN TBL_PPL_WORKBASKET cwb   ON cwb.col_id = cse.COL_CASEPPL_WORKBASKET
WHERE tv.parentid > 0
		--BY TASK
		<%=IfNotNull(":Task_Id", "AND tv.id = :Task_Id")%>
		<%=IfNotNull(":TaskId", "AND lower(tv.taskid) LIKE f_UTIL_toWildcards(:TaskId)")%>
		<%=IfNotNull(":TASKTYPE_ID", "AND tv.TaskSysType in (SELECT to_number(regexp_substr(:TASKTYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:TASKTYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
		<%=IfNotNull(":Name", "AND LOWER(tv.NAME) LIKE f_UTIL_toWildcards(:Name)")%>
		<%=IfNotNull(":Description", "AND LOWER(tv.DESCRIPTION) LIKE f_UTIL_toWildcards(:Description)")%>
		<%=IfNotNull(":ResolutionDescription", "AND LOWER(tv.RESOLUTIONDESCRIPTION) LIKE f_UTIL_toWildcards(:ResolutionDescription)")%>
		<%=IfNotNull(":Created_Start", "AND trunc(tv.Createddate) >= trunc(to_date(:Created_Start))")%>
		<%=IfNotNull(":Created_End", "AND trunc(tv.Createddate) <= trunc(to_date(:Created_End))")%>
		<%=IfNotNull(":Draft", "AND NVL(tv.DRAFT, 0) = :Draft")%>
		<%=IfNotNull(":TASKSTATE_ISFINISH", "AND NVL(tv.TASKSTATE_ISFINISH, 0) = :TASKSTATE_ISFINISH")%>
		<%=IfNotNull(":TASKSTATEIDS", " AND tv.TaskState_id IN (SELECT to_number(regexp_substr(:TASKSTATEIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:TASKSTATEIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
		--BY CASE
		<%=IfNotNull(":Case_Id", "AND tv.caseid = :Case_Id")%>
		<%=IfNotNull(":CASETYPE_ID", "AND tv.CaseSysType in (SELECT to_number(regexp_substr(:CASETYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:CASETYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
		<%=IfNotNull(":Summary", "AND LOWER(tv.SUMMARY) LIKE f_UTIL_toWildcards(:Summary)")%>
		<%=IfNotNull(":CaseId_Name", "AND LOWER(cse.COL_CASEID) LIKE f_UTIL_toWildcards(:CaseId_Name)")%>
		<%=IfNotNull(":Case_Description", "AND LOWER(tv.CASE_DESCRIPTION) LIKE f_UTIL_toWildcards(:Case_Description)")%>
		<%=IfNotNull(":Workbasket_Id", "AND tv.WORKBASKET_ID in (SELECT to_number(regexp_substr(:Workbasket_Id, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:Workbasket_Id, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
		<%=IfNotNull(":CaseWorkbasket_Id", "AND cse.COL_CASEPPL_WORKBASKET in (SELECT to_number(regexp_substr(:CaseWorkbasket_Id, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:CaseWorkbasket_Id, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>