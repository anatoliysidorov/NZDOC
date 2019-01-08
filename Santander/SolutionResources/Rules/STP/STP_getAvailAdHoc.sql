SELECT adhoc.col_Id AS Id,
       CASE WHEN adhoc.COL_TASKSYSTYPE IS NOT NULL THEN 'Task Type' WHEN adhoc.COL_PROCEDURE IS NOT NULL THEN 'Procedure' END AS TargetType_NAME,
       CASE WHEN adhoc.COL_TASKSYSTYPE IS NOT NULL THEN 'TASKSYSTYPE' WHEN adhoc.COL_PROCEDURE IS NOT NULL THEN 'PROCEDURE' END AS TargetType,
       NVL(tdt.COL_NAME, tp.COL_NAME) AS TargetName,
       NVL(tdt.COL_ID, tp.COL_ID) AS TargetId,
       ----------------------------------------------------------------
       f_getNameFromAccessSubject(adhoc.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(adhoc.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(adhoc.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(adhoc.col_modifiedDate) AS ModifiedDuration
       ------------------------------------------------------------------
  FROM tbl_STP_AvailableAdHoc adhoc
       LEFT JOIN TBL_DICT_TASKSYSTYPE tdt
          ON adhoc.COL_TASKSYSTYPE = tdt.COL_ID
       LEFT JOIN TBL_PROCEDURE tp
          ON adhoc.COL_PROCEDURE = tp.COL_ID
 WHERE     (:CaseSysType IS NULL OR adhoc.COL_CASESYSTYPE = :CaseSysType)
       AND (:AdHoc_Id IS NULL OR adhoc.col_id = :AdHoc_Id)
       AND (:IsDeleted IS NULL OR NVL(adhoc.col_isDeleted, 0) = :IsDeleted)
<%=Sort("@SORT@","@DIR@")%>