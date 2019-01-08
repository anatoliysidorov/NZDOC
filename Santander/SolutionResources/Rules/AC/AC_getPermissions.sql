SELECT p.COL_ID AS ID,
       p.COL_NAME AS NAME,
       p.COL_CODE AS CODE,
       p.COL_DESCRIPTION AS DESCRIPTION,
       p.COL_DEFAULTACL AS DEFAULTACL,
       p.COL_ORDERACL AS ORDERACL,
       f_getNameFromAccessSubject (p.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow (p.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject (p.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow (p.col_modifiedDate) AS ModifiedDuration
  FROM    TBL_AC_PERMISSION p
       LEFT JOIN
          (SELECT col_id AS objectTypeId
             FROM TBL_AC_ACCESSOBJECTTYPE
            WHERE col_code = 'PAGE_ELEMENT') ot
       ON 1 = 1
       LEFT JOIN
          (SELECT col_id AS objectTypeId
             FROM TBL_AC_ACCESSOBJECTTYPE
            WHERE col_code = 'DASHBOARD_ELEMENT') otd
       ON 1 = 1
 WHERE     1 = 1
       AND (:TypeId IS NULL OR (:TypeId IS NOT NULL AND p.COL_PERMISSIONACCESSOBJTYPE = :TypeId))
       AND (:Id IS NULL OR (:Id IS NOT NULL AND p.COL_ID = :Id))
       AND (:IsPageElement IS NULL OR (:IsPageElement IS NOT NULL AND p.COL_PERMISSIONACCESSOBJTYPE = ot.objectTypeId))
       AND (:IsDashboardElement IS NULL OR (:IsDashboardElement IS NOT NULL AND p.COL_PERMISSIONACCESSOBJTYPE = otd.objectTypeId))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>