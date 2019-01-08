SELECT
	   --DATA FROM VIEW
	   tv.*,
	   tv.TITLE as TaskId,
	   tv.Name as CalcName,
	   tv.Name as TaskName,
	   case
			  when(1 in(select Allowed
					 from    table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE',p_PermissionCode =>'VIEW'))
					 where   CaseTypeId = tv.CASESYSTYPE_ID)) then 1 else 0
	   end as PERM_CASETYPE_VIEW,
	   
	   --CALC SLAs AND OTHER DURATIONS
	   F_util_getdrtnfrmnow(tv.GoalSlaDateTime) AS GoalSlaDuration,
	   F_util_getdrtnfrmnow(tv.DLineSlaDateTime) AS DLineSlaDuration,
	   F_getnamefromaccesssubject(tv.createdby) AS createdby_name,
	   F_util_getdrtnfrmnow(tv.createddate) AS createdduration,
	   F_getnamefromaccesssubject(tv.MODIFIEDBY) AS modifiedby_name,
	   F_util_getdrtnfrmnow(tv.MODIFIEDDATE) AS modifiedduration,

	   tv.CASE_TITLE  as CASEID_NAME,
	   tv.CASE_SUMMARY as SUMMARY,

	   -- calculate Parentid
	   tv.parentid AS CalcParentId
FROM vw_dcm_fulltasksla tv
WHERE 
	tv.WORKBASKET_ID = f_DCM_getMyPersonalWorkbasket()
	AND tv.parentid > 0
    AND NVL(tv.TASKSTATE_ISFINISH, 0) = 0

	--BY TASK
	<%=IfNotNull(":Created_Start", "AND (trunc(tv.Createddate) >= trunc(to_date(:Created_Start)))")%>
	<%=IfNotNull(":Created_End", "AND (trunc(tv.Createddate) <= trunc(to_date(:Created_End)))")%>
	<%=IfNotNull(":Description", "AND (LOWER(tv.DESCRIPTION) LIKE f_UTIL_toWildcards(:Description))")%>
	<%=IfNotNull(":TaskId", "AND lower(tv.TITLE) LIKE f_UTIL_toWildcards(:TaskId)")%>	
	<%=IfNotNull(":Name", "AND LOWER(tv.Name) LIKE f_UTIL_toWildcards(:Name)")%>
	<%=IfNotNull(":TASKSTATEIDS", " AND tv.TaskState_id IN (SELECT to_number(regexp_substr(:TASKSTATEIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:TASKSTATEIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>

	--BY CASE
	<%=IfNotNull(":Case_Id", "AND tv.CASE_ID = :Case_Id")%>
	<%=IfNotNull(":CASETYPE_ID", "AND tv.CASESYSTYPE_ID in (SELECT to_number(regexp_substr(:CASETYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:CASETYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
	<%=IfNotNull(":Summary", "AND LOWER(tv.CASE_SUMMARY) LIKE f_UTIL_toWildcards(:Summary)")%>
		
	-- check on Active Caseworker
	AND (f_DCM_getActiveCaseWorkerIdFn > 0)
        
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>