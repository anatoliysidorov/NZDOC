SELECT tdb.col_id AS Id,
       tdb.col_code AS Code,
       tdb.col_name AS Name,
       tdb.col_isdeleted AS IsDeleted,
       tdb.col_description AS Description,
       -------------------------------------------
       f_getNameFromAccessSubject(tdb.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(tdb.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(tdb.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(tdb.col_modifiedDate) AS ModifiedDuration
  -------------------------------------------
  FROM tbl_dict_datatype tdb
 WHERE (:DataType_Id IS NULL OR (:DataType_Id IS NOT NULL AND tdb.col_id = :DataType_Id))
<%=Sort("@SORT@","@DIR@")%>