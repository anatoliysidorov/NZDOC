SELECT 
    t.*,
    F_util_getdrtnfrmnow(t.GoalSlaDateTime)     AS GoalSlaDuration,
    F_util_getdrtnfrmnow(t.DLineSlaDateTime)    AS DLineSlaDuration,
    F_dcm_gettaskcustomdata(t.id)             AS customdata,
    F_getnamefromaccesssubject(t.modifiedby)  AS MODIFIEDBY_NAME, 
    F_util_getdrtnfrmnow(t.modifieddate)      AS MODIFIEDDURATION, 
    F_getnamefromaccesssubject(t.createdby)   AS CREATEDBY_NAME, 
    F_util_getdrtnfrmnow(t.createddate)       AS CREATEDDURATION,
    CASE
        WHEN (f_PRTL_isCaseViewableFn(t.CaseID ,sys_context('CLIENTCONTEXT', 'AccessSubject')) = 1 OR sys_context('CLIENTCONTEXT', 'AccessSubject') = t.CASE_CREATEDBY) THEN 1
        ELSE 0
    END AS isCaseViewable,
    
    -- PAGE INFORMATION
    CASE
        WHEN :Task_Id IS NULL THEN NULL
        ELSE f_dcm_getpageid(entity_id => t.id, entity_type => 'portaltask')
    END AS DesignerPage_Id
    
FROM   vw_DCM_MyPersonalTasks t 
WHERE
    --(f_prtl_ismytask(TaskId => t.ID) = 1) AND
    (NVL(:OnlyOpen, 0) = 0 OR (:OnlyOpen = 1 AND f_DCM_isTaskClosedFn(t.id) = 0))
    AND (lower(t.TaskID) <> 'root')
    AND (:Task_Id IS NULL OR (:Task_Id IS NOT NULL AND t.id = :Task_Id ))
    AND (:Summary IS NULL OR (:Summary  IS NOT NULL AND LOWER(t.Summary) LIKE f_UTIL_toWildcards(:Summary)))
    AND (:Id IS NULL OR (:Id IS NOT NULL AND t.caseid  = :Id)) 
    AND (:CaseId IS NULL OR (:CaseId IS NOT NULL AND lower(t.caseid_name) LIKE f_UTIL_toWildcards(:CaseId)))
    AND (:Description IS NULL OR (:Description  IS NOT NULL AND LOWER(t.case_Description) LIKE f_UTIL_toWildcards(Description)))
    AND (:CreatedDate_Start IS NULL OR (:CreatedDate_Start  IS NOT NULL AND trunc(t.Createddate) >= trunc(to_date(:CreatedDate_Start))))
    AND (:CreatedDate_End IS NULL OR (:CreatedDate_End IS NOT NULL AND trunc(t.Createddate) <= trunc(to_date(:CreatedDate_End))))
    AND (:CASESYSTYPE IS NULL OR (t.CaseSysType in (select TO_NUMBER(regexp_substr(:CASESYSTYPE,'[[:'||'alnum:]_]+', 1, level)) as id from dual connect by dbms_lob.getlength(regexp_substr(:CASESYSTYPE, '[[:'||'alnum:]_]+', 1, level)) > 0)))
    AND (:CASESYSTYPE_CODE IS NULL OR (lower(t.CaseSysType_Code) in (select lower(to_char(regexp_substr(:CASESYSTYPE_CODE,'[[:'||'alnum:]_]+', 1, level))) as code from dual connect by dbms_lob.getlength(regexp_substr(:CASESYSTYPE_CODE, '[[:'||'alnum:]_]+', 1, level)) > 0)))
    AND (:Workbasket_Id is null OR t.WORKBASKET_ID in (select TO_NUMBER(regexp_substr(:Workbasket_Id,'[[:'||'alnum:]_]+', 1, level)) as id from dual connect by dbms_lob.getlength(regexp_substr(:Workbasket_Id, '[[:'||'alnum:]_]+', 1, level)) > 0))
    AND (:CaseWorkbasket_Id is null OR t.CASEWORKBASKET_ID in (select TO_NUMBER(regexp_substr(:CaseWorkbasket_Id,'[[:'||'alnum:]_]+', 1, level)) as id from dual connect by dbms_lob.getlength(regexp_substr(:CaseWorkbasket_Id, '[[:'||'alnum:]_]+', 1, level)) > 0))
    AND (:Name IS NULL OR (LOWER(t.NAME) LIKE f_UTIL_toWildcards(:Name)))
    AND (:ResolutionDescription IS NULL OR (LOWER(t.RESOLUTIONDESCRIPTION) LIKE f_UTIL_toWildcards(:ResolutionDescription)))
    AND (:TASKTYPE_ID IS NULL OR (t.TaskSysType in (select TO_NUMBER(regexp_substr(:TASKTYPE_ID,'[[:'||'alnum:]_]+', 1, level)) as id from dual connect by dbms_lob.getlength(regexp_substr(:TASKTYPE_ID, '[[:'||'alnum:]_]+', 1, level)) > 0)))

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>