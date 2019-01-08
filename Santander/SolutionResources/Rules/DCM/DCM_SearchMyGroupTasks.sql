SELECT
--DATA FROM VIEW
 tv.*,
 --CALC SLAs AND OTHER DURATIONS
 F_util_getdrtnfrmnow(tv.GoalSlaDateTime) AS GoalSlaDuration,
 F_util_getdrtnfrmnow(tv.DLineSlaDateTime) AS DLineSlaDuration,
 F_getnamefromaccesssubject(tv.createdby) AS createdby_name,
 F_util_getdrtnfrmnow(tv.createddate) AS createdduration,
 F_getnamefromaccesssubject(tv.MODIFIEDBY) AS modifiedby_name,
 F_util_getdrtnfrmnow(tv.MODIFIEDDATE) AS modifiedduration
  FROM vw_dcm_fulltasksla tv
 WHERE tv.WORKBASKET_ID IN
       (SELECT COL_ID AS WB_ID
          FROM TBL_PPL_WORKBASKET
         WHERE COL_WORKBASKETTEAM IN
               (SELECT COL_TBL_PPL_TEAM
                  FROM TBl_CASEWORKERTEAM
                 WHERE COL_TM_PPL_CASEWORKER = (SELECT id FROM vw_ppl_caseworkersusers WHERE accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')))
        UNION
        SELECT COL_MAP_WB_TM_WORKBASKET AS WB_ID
          FROM TBL_MAP_WORKBASKETTEAM
         WHERE COL_MAP_WB_TM_TEAM IN
               (SELECT COL_TBL_PPL_TEAM
                  FROM TBl_CASEWORKERTEAM
                 WHERE COL_TM_PPL_CASEWORKER = (SELECT id FROM vw_ppl_caseworkersusers WHERE accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')))
        --get the workbaskets of skills caseworker is part of
        UNION
        SELECT COL_ID AS WB_ID
          FROM TBL_PPL_WORKBASKET
         WHERE COL_WORKBASKETSKILL IN
               (SELECT COL_TBL_PPL_SKILL
                  FROM TBl_CASEWORKERSKILL
                 WHERE COL_SK_PPL_CASEWORKER = (SELECT id FROM vw_ppl_caseworkersusers WHERE accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')))
        UNION
        SELECT COL_MAP_WS_WORKBASKET AS WB_ID
          FROM TBL_MAP_WORKBASKETSKILL
         WHERE COL_MAP_WS_SKILL IN
               (SELECT COL_TBL_PPL_SKILL
                  FROM TBl_CASEWORKERSKILL
                 WHERE COL_SK_PPL_CASEWORKER = (SELECT id FROM vw_ppl_caseworkersusers WHERE accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')))
        UNION
        --get the workbaskets of business roles caseworker is part of
        SELECT COL_ID AS WB_ID
          FROM TBL_PPL_WORKBASKET
         WHERE COL_WORKBASKETBUSINESSROLE IN
               (SELECT COL_TBL_PPL_BUSINESSROLE
                  FROM TBl_CASEWORKERBUSINESSROLE
                 WHERE COL_BR_PPL_CASEWORKER = (SELECT id FROM vw_ppl_caseworkersusers WHERE accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')))
        UNION
        SELECT COL_MAP_WB_BR_WORKBASKET AS WB_ID
          FROM TBL_MAP_WORKBASKETBUSNESSROLE
         WHERE COL_MAP_WB_WR_BUSINESSROLE IN
               (SELECT COL_TBL_PPL_BUSINESSROLE
                  FROM TBl_CASEWORKERBUSINESSROLE
                 WHERE COL_BR_PPL_CASEWORKER = (SELECT id FROM vw_ppl_caseworkersusers WHERE accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')))
        --get the workbaskets tied to a caseworker's shared baskets
        UNION
        SELECT COL_MAP_WB_CW_WORKBASKET AS WB_ID
          FROM TBL_MAP_WORKBASKETCASEWORKER
         WHERE COL_MAP_WB_CW_CASEWORKER = (SELECT id FROM vw_ppl_caseworkersusers WHERE accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')))
   AND tv.parentid > 0
   AND NVL(tv.TASKSTATE_ISFINISH, 0) = 0

	--BY TASK
	<%=IfNotNull(":TASK_ID", "AND tv.ID = :TASK_ID")%>
	<%=IfNotNull(":TASKID", "AND lower(tv.TITLE) LIKE f_UTIL_toWildcards(:TASKID)")%>
	<%=IfNotNull(":TASKTYPE_IDS", "AND tv.TASKSYSTYPE_ID in (SELECT to_number(regexp_substr(:TASKTYPE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:TASKTYPE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
	<%=IfNotNull(":TASK_NAME", "AND LOWER(tv.NAME) LIKE f_UTIL_toWildcards(:TASK_NAME)")%>
	<%=IfNotNull(":TASK_DESCRIPTION", "AND LOWER(tv.DESCRIPTION) LIKE f_UTIL_toWildcards(:TASK_DESCRIPTION)")%>
	<%=IfNotNull(":RESOLUTIONCODE_IDS", "AND tv.RESOLUTIONCODE_ID in (SELECT to_number(regexp_substr(:RESOLUTIONCODE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:RESOLUTIONCODE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
	<%=IfNotNull(":CREATED_START", "AND trunc(tv.Createddate) >= trunc(to_date(:CREATED_START))")%>
	<%=IfNotNull(":CREATED_END", "AND trunc(tv.Createddate) <= trunc(to_date(:CREATED_END))")%>
    <%=IfNotNull(":TASKSTATE_IDS", " AND tv.TASKSTATE_ID IN (SELECT to_number(regexp_substr(:TASKSTATE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:TASKSTATE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
 	<%=IfNotNull(":TASKWORKBASKET_IDS", "AND tv.WORKBASKET_ID IN (SELECT to_number(regexp_substr(:TASKWORKBASKET_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:TASKWORKBASKET_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>

	--BY CASE
	<%=IfNotNull(":CASEID", "AND lower(tv.CASE_TITLE) LIKE f_UTIL_toWildcards(:CASEID)")%>
    <%=IfNotNull(":CASETYPE_IDS", "AND tv.CASESYSTYPE_ID in (SELECT to_number(regexp_substr(:CASETYPE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:CASETYPE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
	<%=IfNotNull(":CASE_SUMMARY", "AND LOWER(tv.CASE_SUMMARY) LIKE f_UTIL_toWildcards(:CASE_SUMMARY)")%>
    <%=IfNotNull(":CASEWORKBASKET_IDS", "AND tv.CASE_WORKBASKETID IN (SELECT to_number(regexp_substr(:CASEWORKBASKET_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:CASEWORKBASKET_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
	-- CHECK ON ACTIVE CASEWORKER
	AND (f_DCM_getActiveCaseWorkerIdFn > 0)

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>