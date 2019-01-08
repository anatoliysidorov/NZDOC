SELECT --DATA FROM VIEW
       cv.*,
       --ADDITIONAL DATA AND CALCULATED DATA
       F_getnamefromaccesssubject(CV.createdby) AS createdby_name,
       F_util_getdrtnfrmnow(CV.createddate) AS createdduration,
       F_getnamefromaccesssubject(CV.modifiedby) AS modifiedby_name,
       F_util_getdrtnfrmnow(CV.modifieddate) AS modifiedduration,
       dbms_xmlgen.CONVERT(F_dcm_getcasecustomdata(CV.id)) AS customdata,
       F_util_getdrtnfrmnow(CV.GoalSlaDateTime)     AS GoalSlaDuration,
       F_util_getdrtnfrmnow(CV.DLineSlaDateTime)    AS DLineSlaDuration,
       --INPUT RETURN
       NVL(:Task_Id, NULL) AS TASK_ID,

       -- PAGE INFORMATION
       CASE
          WHEN :Case_Id IS NULL THEN NULL
          ELSE f_dcm_getpageid(entity_id => cv.id, entity_type => 'portalcase')
       END AS DesignerPage_Id,

       -- Permissions
       f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = cv.CASESYSTYPE_ID), permissioncode => 'DETAIL') AS PERM_CASETYPE_DETAIL,
       f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = cv.CASESYSTYPE_ID), permissioncode => 'MODIFY') AS PERM_CASETYPE_MODIFY
  FROM vw_dcm_simplecase cv
WHERE
   (f_PRTL_isCaseViewableFn(cv.ID ,sys_context('CLIENTCONTEXT', 'AccessSubject')) = 1 OR sys_context('CLIENTCONTEXT', 'AccessSubject') = cv.createdby) AND
  (NVL(:Task_Id, 0) = 0 OR (NVL(:Task_Id, 0) > 0 AND cv.id = (select col_casetask from tbl_task where col_id  = :Task_Id) )) AND
  (NVL(:Case_Id, 0) = 0 OR (NVL(:Case_Id, 0) > 0 AND cv.id = :Case_Id )) AND
  (:CaseId IS NULL OR (lower(cv.caseid) LIKE f_UTIL_toWildcards(:CaseId))) AND
  (:summary IS NULL OR (LOWER(cv.summary) LIKE f_UTIL_toWildcards(:summary))) AND
  (:workbasket_name IS NULL OR (LOWER(cv.workbasket_name) LIKE f_UTIL_toWildcards(:workbasket_name))) AND
  (:DESCRIPTION IS NULL OR (LOWER(cv.DESCRIPTION) LIKE f_UTIL_toWildcards(:DESCRIPTION))) AND
  (:CREATED_START IS NULL OR (trunc(cv.CREATEDDATE) >= trunc(to_date(:CREATED_START)))) AND
  (:CREATED_END IS NULL OR (trunc(cv.CREATEDDATE) <= trunc(to_date(:CREATED_END)))) AND
  (:CaseSysType_Code IS NULL OR (lower(cv.casesystype_code) in (SELECT lower(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:CaseSysType_Code, ','))))) AND
  (:MilestoneIds IS NULL OR (cv.MS_StateId IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(REPLACE(:MilestoneIds, '''', ''), ',')))))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>