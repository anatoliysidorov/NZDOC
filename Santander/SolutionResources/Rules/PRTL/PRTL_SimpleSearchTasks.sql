SELECT 
    --DATA FROM VIEW   
    tv.*,

    case when (1 in (select Allowed from table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE',p_PermissionCode =>'VIEW')) where CaseTypeId = tv.casesystype)) then 1
         else 0 end as PERM_CASETYPE_VIEW,
    
    --CUSTOM DATA (return only when loading a specific task)
    CASE
        WHEN NVL(:Task_Id,0) = 0 THEN NULL
        ELSE dbms_xmlgen.CONVERT(F_dcm_gettaskcustomdata(tv.id))
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
    
   (SELECT COUNT(*) FROM vw_DCM_MyPersonalTasks mpt WHERE mpt.ID = tv.ID) AS isCaseViewable,
    
    -- PAGE INFORMATION
    CASE
        WHEN :Task_Id IS NULL THEN NULL
        ELSE f_dcm_getpageid(entity_id => tv.id, entity_type => 'task')
    END AS DesignerPage_Id
    
FROM vw_dcm_simpletask tv 
WHERE 1=1

    --BY TASK
    <%=IfNotNull(":Task_Id", "AND (tv.id = :Task_Id)")%>
    --BY CASE
    <%=IfNotNull(":Case_Id", "AND (tv.caseid = :Case_Id)")%>   
    -- check on Active Caseworker
    AND (f_DCM_getActiveCaseWorkerIdFn > 0)
    -- root Task is excluded
    <%=IfNotNull(":NotRoot", "AND (lower(tv.TaskID) <> 'root')")%>
   
 start with (:Parent_Id IS NULL AND tv.parentid = 0) OR (:Parent_Id IS NOT NULL AND tv.id = :Parent_Id)
connect by prior tv.id = tv.parentid AND (:TASKSTATEIDS IS NULL OR tv.TaskState_id IN (select TO_NUMBER(regexp_substr(:TASKSTATEIDS,'[[:'||'alnum:]_]+', 1, level)) as id from dual connect by dbms_lob.getlength(regexp_substr(:TASKSTATEIDS, '[[:'||'alnum:]_]+', 1, level)) > 0))
