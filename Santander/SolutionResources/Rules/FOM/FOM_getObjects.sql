SELECT p.col_id AS Id,
       p.col_tablename AS TableName,
       p.col_code AS Code,
       p.col_name AS Name,
       p.col_isdeleted AS IsDeleted,
       -------------------------------------------
       f_getNameFromAccessSubject(p.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(p.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
  FROM tbl_fom_object p
 WHERE (:Object_Id IS NULL OR (:Object_Id IS NOT NULL AND p.col_id = :Object_Id))
<%=Sort("@SORT@","@DIR@")%>