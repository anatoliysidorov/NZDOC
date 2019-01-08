SELECT tbl.col_id AS Id,
	   tbl.col_Description AS Description,
	   tbl.col_IsDraft AS IsDraft,
	   tbl.col_KeyID AS KeyID,
	   tbl.col_LangID AS LangID,
	   tbl.col_PluralForm AS PluralForm,
	   tbl.col_Value AS Value,
       f_getNameFromAccessSubject(tbl.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(tbl.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(tbl.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(tbl.col_modifiedDate) AS ModifiedDuration
FROM tbl_LOC_Translation tbl
WHERE (:Id IS NULL OR tbl.col_id = :Id)
	AND (:KeyID IS NULL OR tbl.col_KeyID = :KeyID)
	AND (:LangID IS NULL OR tbl.col_LangID = :LangID)
<%=Sort("@SORT@","@DIR@")%>