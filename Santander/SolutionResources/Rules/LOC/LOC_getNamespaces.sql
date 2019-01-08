SELECT tbl.col_id AS Id,
       tbl.col_name AS Name,
       tbl.col_description AS Description,
       f_getNameFromAccessSubject(tbl.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(tbl.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(tbl.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(tbl.col_modifiedDate) AS ModifiedDuration
FROM tbl_LOC_Namespace tbl
WHERE (:Id IS NULL OR tbl.col_id = :Id)
<%=Sort("@SORT@","@DIR@")%>