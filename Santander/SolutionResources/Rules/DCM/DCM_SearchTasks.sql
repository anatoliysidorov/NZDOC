SELECT
	   --DATA FROM VIEW
	   tv.*,
	   tv.TaskName as CalcName,
	   case
			  when(1 in(select Allowed
					 from    table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE',p_PermissionCode =>'VIEW'))
					 where   CaseTypeId = (SELECT COL_CASEDICT_CASESYSTYPE FROM TBL_CASE WHERE COL_ID = tv.CASEID))) then 1 else 0
	   end as PERM_CASETYPE_VIEW,
	   
	   --CALC SLAs AND OTHER DURATIONS
	   F_util_getdrtnfrmnow(tv.GoalSlaDateTime) AS GoalSlaDuration,
	   F_util_getdrtnfrmnow(tv.DLineSlaDateTime) AS DLineSlaDuration,
	   F_getnamefromaccesssubject(tv.createdby) AS createdby_name,
	   F_util_getdrtnfrmnow(tv.createddate) AS createdduration,
	   F_getnamefromaccesssubject(tv.MODIFIEDBY) AS modifiedby_name,
	   F_util_getdrtnfrmnow(tv.MODIFIEDDATE) AS modifiedduration,
	   
	   -- calculate Parentid
	   DECODE(NVL(:Parent_Id,0),0,tv.parentid, DECODE(:Parent_Id, tv.id,0,tv.parentid)) AS CalcParentId,

	   -- PAGE INFORMATION
	   <%=IfNotNull(":Task_Id", " f_dcm_getpageid(entity_id => tv.ID, entity_type => 'task') AS DesignerPage_Id, ")%>

	   -- calculate BO Type
	   DECODE(NVL(:Parent_Id,0),0,'CASE','TASK') AS CalcObjType 

FROM  (with tsk2 as
            (select tsk.col_id as ID, tsk.col_parentid as parentid, tsk.col_casetask as CaseId
             from    tbl_task tsk
             where   1 = 1 AND NVL(tsk.COL_ISHIDDEN,0)=0
             <%=IfNotNull(":Case_Id", " and (tsk.col_casetask = :Case_Id)")%>),

            tsk3 as
            (select stps.*
             from vw_dcm_simpletasksla stps
             where 1 = 1 AND NVL(stps.IsHidden,0)=0           
             <%=IfNotNull(":Case_Id", " and (stps.CaseId= :Case_Id)")%>)

            select s2.*
            from
            (select tsk2.id
             from    tsk2
             start with(:Parent_Id IS NULL AND tsk2.parentid = 0)
                     OR(:Parent_Id IS NOT NULL AND tsk2.id = :Parent_Id)
             connect by prior tsk2.Id = tsk2.parentId) s1
             inner JOIN (select tsk3.* from tsk3) s2 on s1.id = s2.id
              ) tv

WHERE 1 = 1

     AND tv.caseid = :Case_Id

  --BY TASK	
  <%=IfNotNull(":Task_Id", " AND tv.id = :Task_Id")%>
  <%=IfNotNull(":TaskId", " AND lower(tv.taskid) LIKE f_UTIL_toWildcards(:TaskId)")%>	
  <%=IfNotNull(":TASKTYPE_ID", " AND tv.TaskSysType in (SELECT to_number(regexp_substr(:TASKTYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:TASKTYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
  <%=IfNotNull(":Name", " AND LOWER(tv.NAME) LIKE f_UTIL_toWildcards(:Name)")%>
  <%=IfNotNull(":Description", " AND LOWER(tv.DESCRIPTION) LIKE f_UTIL_toWildcards(:Description)")%>
  <%=IfNotNull(":ResolutionDescription", " AND LOWER(tv.RESOLUTIONDESCRIPTION) LIKE f_UTIL_toWildcards(:ResolutionDescription)")%>
  <%=IfNotNull(":Created_Start", " AND trunc(tv.Createddate) >= trunc(to_date(:Created_Start))")%>
  <%=IfNotNull(":Created_End", " AND trunc(tv.Createddate) <= trunc(to_date(:Created_End))")%>
  <%=IfNotNull(":Draft", " AND NVL(tv.DRAFT, 0) = :Draft")%>
  <%=IfNotNull(":TASKSTATE_ISFINISH", " AND NVL(tv.TASKSTATE_ISFINISH, 0) = :TASKSTATE_ISFINISH")%>
  --BY CASE
  <%=IfNotNull(":Case_Id", " AND tv.caseid = :Case_Id")%>
  <%=IfNotNull(":CASETYPE_ID", " AND tv.CaseSysType in (SELECT to_number(regexp_substr(:CASETYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:CASETYPE_ID, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
  <%=IfNotNull(":Summary", " AND LOWER(tv.SUMMARY) LIKE f_UTIL_toWildcards(:Summary)")%>
  <%=IfNotNull(":CaseId_Name", " AND LOWER(tv.CASEID_NAME) LIKE f_UTIL_toWildcards(:CaseId_Name)")%>
  <%=IfNotNull(":Case_Description", " AND LOWER(tv.CASE_DESCRIPTION) LIKE f_UTIL_toWildcards(:Case_Description)")%>
  <%=IfNotNull(":Workbasket_Id", " AND tv.WORKBASKET_ID in (SELECT to_number(regexp_substr(:Workbasket_Id, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:Workbasket_Id, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>
  <%=IfNotNull(":CaseWorkbasket_Id", " AND tv.CASEWORKBASKET_ID in (SELECT to_number(regexp_substr(:CaseWorkbasket_Id, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:CaseWorkbasket_Id, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>

  <%=IfNotNull(":TASKSTATEIDS", " AND (tv.TaskState_id IN (SELECT to_number(regexp_substr(:TASKSTATEIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:TASKSTATEIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) OR lower(tv.TaskName) = 'root')")%>
  <%=IfNotNull(":NotRoot", " AND (lower(tv.TaskID) <> 'root')")%>
  
  -- check on Active Caseworker
  AND (f_DCM_getActiveCaseWorkerIdFn > 0)
    
  <%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>

