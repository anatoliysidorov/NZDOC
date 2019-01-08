SELECT tdb.col_id AS Id,
       tdb.col_code AS Code,
       tdb.col_name AS Name,
       tdb.col_isdeleted AS IsDeleted,
       ----------------------------
       f_getNameFromAccessSubject(tdb.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(tdb.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(tdb.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(tdb.col_modifiedDate) AS ModifiedDuration
       ----------------------------
  FROM tbl_dict_businessobject tdb LEFT JOIN vw_users users ON (tdb.col_createdby = users.AccessSubjectCode)
 WHERE (:Object_Id IS NULL OR (:Object_Id IS NOT NULL AND tdb.col_id = :Object_Id))
<%=Sort("@SORT@","@DIR@")%>