SELECT col_id AS Id,
       col_code AS Code,
       col_name AS Name,
       col_description AS Description,
       col_isdeleted AS IsDeleted,
       f_getNameFromAccessSubject(col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(col_modifiedDate) AS ModifiedDuration
  FROM tbl_dict_slaeventlevel
 WHERE (:Id IS NULL OR col_id = :Id) AND (:IsDeleted IS NULL OR NVL(col_isdeleted, 0) = :IsDeleted)
<%=Sort("@SORT@","@DIR@")%>