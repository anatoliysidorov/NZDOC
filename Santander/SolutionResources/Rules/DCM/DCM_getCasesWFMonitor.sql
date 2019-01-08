SELECT --DATA FROM VIEW
       CV.ID,
       CV.CaseId,
       CV.Summary,
       CV.Draft,
       CV.CaseSysType_ColorCode,
       CV.CaseSysType_IconCode,
       CV.CaseSysType_Name,
       CV.Workbasket_Id,
       CV.Workbasket_Name,
       CV.Workbasket_Type_Code,
       (SELECT assigneename FROM TABLE(f_DCM_getCaseOwnerProxy2(CaseId => CV.Id))) AS AssigneeName,
       CV.Owner_Caseworker_Name,
       CV.CaseState_Id,
       CV.CaseState_Name,
       CV.CaseState_ISSTART,
       CV.CaseState_ISRESOLVE,
       CV.CaseState_ISFINISH,
       CV.CaseState_ISASSIGN,
       CV.CaseState_ISFIX,
       CV.CaseState_ISINPROCESS,
       CV.CaseState_ISDEFAULTONCREATE,
       CV.StateConfig_id,
       CV.StateConfig_Name,
       CV.StateConfig_IsDefault,
       CV.CreatedBy,
       CV.CreatedDate,
       --MILESTONE
       CV.ms_stateid   AS MS_StateId,
       CV.ms_statename AS MS_StateName,
       --Goal SLA
       CV.GoalSlaEventTypeId, CV.GoalSlaEventTypeCode, CV.GoalSlaEventTypeName, CV.GoalSlaDateTime,
       F_util_getdrtnfrmnow(CV.GoalSlaDateTime)     AS GoalSlaDuration,
       --DeadLine (DLine) SLA
       CV.DLineSlaEventTypeId, CV.DLineSlaEventTypeCode, CV.DLineSlaEventTypeName, CV.DLineSlaDateTime,
       F_util_getdrtnfrmnow(CV.DLineSlaDateTime)    AS DLineSlaDuration,
       --ADDITIONAL DATA AND CALCULATED DATA
       f_getNameFromAccessSubject(CV.createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(CV.createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(CV.modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(CV.modifiedDate) AS ModifiedDuration
  FROM vw_DCM_SimpleCaseAC CV
 WHERE     1 = 1
       AND (:ID IS NULL OR CV.ID = :ID)
       AND (:CaseId IS NULL OR (LOWER(CV.caseid) LIKE f_UTIL_toWildcards(:CaseId)))
       AND (:summary IS NULL OR (LOWER(CV.summary) LIKE f_UTIL_toWildcards(:summary)))
       AND (:workbasket_name IS NULL OR (LOWER(CV.workbasket_name) LIKE f_UTIL_toWildcards(:workbasket_name)))
       AND (:CREATED_START IS NULL OR (TRUNC(CV.CREATEDDATE) >= TRUNC(TO_DATE(:CREATED_START))))
       AND (:CREATED_END IS NULL OR (TRUNC(CV.CREATEDDATE) <= TRUNC(TO_DATE(:CREATED_END))))
       AND (:CaseSysType_Code IS NULL OR (LOWER(CV.casesystype_code) IN (SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:CaseSysType_Code, ',')))))
       AND (:MilestoneIds IS NULL OR (cv.MS_StateId IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM TABLE(asf_splitclob(REPLACE(:MilestoneIds, '''', ''), ',')))))
       --ADD CRITERIA FOR WORKBASKETS FROM CASE
       AND (:WorkbasketIds IS NULL OR CV.Workbasket_Id IN (SELECT TO_NUMBER(COLUMN_VALUE) AS c2 FROM TABLE(asf_splitclob(:WorkbasketIds, ','))))
       --ADD CRITERIA FOR CASESYSTYPES FROM CASE
       AND (:CaseSysTypeIds IS NULL OR CV.CaseSysType_Id IN (SELECT TO_NUMBER(COLUMN_VALUE) AS c2 FROM TABLE(asf_splitclob(:CaseSysTypeIds, ','))))
       --ADD CRITERIA FOR CASESTATE FROM CASE
       AND (:STATECONFIGIDS IS NULL OR (CV.StateConfig_id IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM TABLE(asf_splitclob(:STATECONFIGIDS, ',')))))
       AND (:CaseStateIds IS NULL OR CV.CaseState_Id IN (SELECT TO_NUMBER(COLUMN_VALUE) AS c2 FROM TABLE(asf_splitclob(:CaseStateIds, ','))))
<%=Sort("@SORT@","@DIR@")%>