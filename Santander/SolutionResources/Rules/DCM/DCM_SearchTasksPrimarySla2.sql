SELECT 
    --DATA FROM VIEW   
    tv.*,

    case when (1 in (select Allowed from table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE',p_PermissionCode =>'VIEW')) where CaseTypeId = tv.casesystype)) then 1
         else 0 end as PERM_CASETYPE_VIEW,
    
    --CUSTOM DATA (return only when loading a specific task)
    CASE
        WHEN NVL(:Task_Id,0) = 0 THEN NULL
        ELSE F_dcm_gettaskcustomdata(tv.id)
    END AS customdata,
    
    --CALC SLAs AND OTHER DURATIONS
    F_util_getdrtnfrmnow(tv.PREVSLADATETIME)     AS SLA_PrevDuration, 
    F_util_getdrtnfrmnow(tv.NEXTSLADATETIME)     AS SLA_NextDuration,    
    F_util_getdrtnfrmnow(tv.GoalSlaDateTime)     AS GoalSlaDuration,
    F_util_getdrtnfrmnow(tv.DLineSlaDateTime)    AS DLineSlaDuration,
    F_getnamefromaccesssubject(tv.createdby) AS createdby_name,
    F_util_getdrtnfrmnow(tv.createddate)     AS createdduration,
    F_getnamefromaccesssubject(tv.MODIFIEDBY)AS modifiedby_name,
    F_util_getdrtnfrmnow(tv.MODIFIEDDATE)    AS modifiedduration,
    
    -- calculate Parentid
    DECODE(NVL(:Parent_Id,0),0, tv.parentid, DECODE(:Parent_Id, tv.id, 0, tv.parentid)) AS CalcParentId,
    -- calculate BO Type
    DECODE(NVL(:Parent_Id,0),0, 'CASE', 'TASK') AS CalcObjType,
    
    -- PAGE INFORMATION
    CASE
        WHEN :Task_Id IS NULL THEN NULL
        ELSE f_dcm_getpageid(entity_id => tv.id, entity_type => 'task')
    END AS DesignerPage_Id

FROM (select tv.*  /*, s1.col_customdata*/
           from
           ((select tsk.col_id /*, tsk.col_customdata*/
              from tbl_task tsk
              where 1=1
              <%=IfNotNull(":Case_Id", " and (tsk.col_casetask = :Case_Id)")%>
              <%=IfNotNull(":Task_Id", " and (tsk.col_id = :Task_Id)")%>
              start with (:Parent_Id IS NULL AND tsk.col_parentid = 0) OR (:Parent_Id IS NOT NULL AND tsk.col_id = :Parent_Id)
               --start with tsk.col_parentid = nvl(:Parent_Id,0)
               connect by prior tsk.col_id = tsk.col_parentid
               ) s1
            inner join
            (select tv.* from vw_dcm_simpletaskprimarysla tv
             where 1 = 1
             <%=IfNotNull(":Case_Id", " and (tv.CaseId = :Case_Id)")%>
            ) tv on s1.col_id = tv.id)) tv
WHERE 1=1

    --BY TASK	
    <%=IfNotNull(":Task_Id", "AND (tv.id = :Task_Id)")%>
    <%=IfNotNull(":TaskId", "AND lower(tv.taskid) LIKE f_UTIL_toWildcards(:TaskId)")%>	
    <%=IfNotNull(":TASKTYPE_ID", "AND (tv.TaskSysType in (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(:TASKTYPE_ID, ','))))")%>
    <%=IfNotNull(":Name", "AND (LOWER(tv.NAME) LIKE f_UTIL_toWildcards(:Name))")%>
    <%=IfNotNull(":Description", "AND (LOWER(tv.DESCRIPTION) LIKE f_UTIL_toWildcards(:Description))")%>
    <%=IfNotNull(":ResolutionDescription", "AND (LOWER(tv.RESOLUTIONDESCRIPTION) LIKE f_UTIL_toWildcards(:ResolutionDescription))")%>
    <%=IfNotNull(":Created_Start", "AND (trunc(tv.Createddate) >= trunc(to_date(:Created_Start)))")%>
    <%=IfNotNull(":Created_End", "AND (trunc(tv.Createddate) <= trunc(to_date(:Created_End)))")%>
    <%=IfNotNull(":Draft", "AND (NVL(tv.DRAFT, 0) = :Draft)")%>
    <%=IfNotNull(":TASKSTATE_ISFINISH", "AND (NVL(tv.TASKSTATE_ISFINISH, 0) = :TASKSTATE_ISFINISH)")%>
    --BY CASE
    <%=IfNotNull(":Case_Id", "AND (tv.caseid = :Case_Id)")%>
    <%=IfNotNull(":CASETYPE_ID", "AND (tv.CaseSysType in (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(:CASETYPE_ID, ','))))")%>
    <%=IfNotNull(":Summary", "AND (LOWER(tv.SUMMARY) LIKE f_UTIL_toWildcards(:Summary))")%>
    <%=IfNotNull(":CaseId_Name", "AND (LOWER(tv.CASEID_NAME) LIKE f_UTIL_toWildcards(:CaseId_Name))")%>
    <%=IfNotNull(":Case_Description", "AND (LOWER(tv.CASE_DESCRIPTION) LIKE f_UTIL_toWildcards(:Case_Description))")%>
    <%=IfNotNull(":Workbasket_Id", "AND tv.WORKBASKET_ID in (select to_number(column_value) as c2 from table(asf_splitclob(:Workbasket_Id,',')))")%>
    <%=IfNotNull(":CaseWorkbasket_Id", "AND tv.CASEWORKBASKET_ID in (select to_number(column_value) as c2 from table(asf_splitclob(:CaseWorkbasket_Id,',')))")%>
		
    -- check on Active Caseworker
    AND (f_DCM_getActiveCaseWorkerIdFn > 0)
    -- root Task is excluded
    <%=IfNotNull(":NotRoot", "AND (lower(tv.TaskID) <> 'root')")%>

<%=IFNOTNULL("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>

