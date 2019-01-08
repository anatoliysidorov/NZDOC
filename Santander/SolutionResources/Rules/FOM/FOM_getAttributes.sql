SELECT p.col_id AS Id,
       p.COL_COLUMNNAME AS ColumnName,
       p.col_code AS Code,
       p.col_name AS Name,
       p.COL_FOM_ATTRIBUTEFOM_OBJECT AS OBJECT_ID,
       p.col_isdeleted AS IsDeleted,
       -------------------------------------------
       f_getNameFromAccessSubject(p.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(p.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
  FROM tbl_fom_attribute p
 WHERE (:Attribute_Id IS NULL OR (:Attribute_Id IS NOT NULL AND p.col_id = :Attribute_Id))
       AND (:Object_Id IS NULL OR (:Object_Id IS NOT NULL AND p.COL_FOM_ATTRIBUTEFOM_OBJECT = :Object_Id))
<%=Sort("@SORT@","@DIR@")%>