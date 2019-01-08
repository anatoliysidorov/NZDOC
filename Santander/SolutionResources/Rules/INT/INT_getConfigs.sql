SELECT i.col_id AS Id,
       i.col_code AS Code,
       i.col_config AS Config,
       i.col_name AS Name,
       i.col_isdeleted AS IsDeleted,
       -------------------------------------------
       f_getNameFromAccessSubject(i.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(i.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(i.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(i.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
  FROM tbl_int_integtarget i
 WHERE (:pId IS NULL OR i.col_id = :pId) AND (:name IS NULL OR LOWER(i.col_name) = LOWER(:name))
<%=Sort("@SORT@","@DIR@")%>