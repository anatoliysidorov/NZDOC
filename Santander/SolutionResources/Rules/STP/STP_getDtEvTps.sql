SELECT col_id AS Id,
       col_code AS Code,
       col_name AS Name,
       col_description AS Description,
       col_isdeleted AS IsDeleted,
       col_canoverwrite AS IsOverwrite,
       col_multipleallowed AS IsAllowMultiply,
       col_isslastart AS IsSLAStart,
       col_isslaend AS IsSLAEnd,
       col_isstate AS IsState,
       col_type AS TYPE,
       f_getNameFromAccessSubject(col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(col_modifiedDate) AS ModifiedDuration
  FROM TBL_DICT_DATEEVENTTYPE
 WHERE (:Id IS NULL OR col_id = :Id) AND (:IsDeleted IS NULL OR NVL(col_isdeleted, 0) = :IsDeleted)
<%=Sort("@SORT@","@DIR@")%>