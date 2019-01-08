SELECT p.col_id AS Id,
       p.col_code AS Code,
       p.col_name AS Name,
       p.col_description AS Description,
       NVL(p.col_allowMultiple, 0) AS AllowMultiple,
       -------------------------------------------
       f_getNameFromAccessSubject(p.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(p.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_modifiedDate) AS ModifiedDuration
  -------------------------------------------
  FROM tbl_dict_assocpagetype p
 WHERE (:UsedFor IS NULL
        OR (:UsedFor IS NOT NULL
            AND (   :UsedFor = 'CASETYPE' AND p.col_code IN ('NEW', 'PORTAL_NEW', 'FULL_PAGE_CASE_DETAIL', 'FULL_PAGE_PORTALCASE_DETAIL')
                 OR (:UsedFor = 'TASKTYPE' AND p.col_code IN ('NEW', 'PORTAL_NEW', 'FULL_PAGE_TASK_DETAIL', 'FULL_PAGE_PORTALTASK_DETAIL'))
                 OR (:UsedFor = 'PARTYTYPE' AND p.col_code IN ('NEW', 'FULL_PAGE_PARTY_DETAIL'))
                 OR (:UsedFor = 'WORKACTIVITYTYPE' AND p.col_code IN ('NEW')))))
<%=Sort("@SORT@","@DIR@")%>