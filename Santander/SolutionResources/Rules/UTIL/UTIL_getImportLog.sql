SELECT col_id AS ID,
    col_importstatus AS IMPORTSTATUS,
    col_notes AS NOTES,
	col_errorlog as ERRORLOG,
    col_error_cnt AS ERROR_CNT,
    col_cmspath AS CMSPATH,
    -------------------------------------------
    F_getnamefromaccesssubject(col_createdby) AS CreatedBy_Name,
    F_util_getdrtnfrmnow(col_createddate) AS CreatedDuration,
    F_getnamefromaccesssubject(col_modifiedby) AS ModifiedBy_Name,
    F_util_getdrtnfrmnow(col_modifieddate)
    -------------------------------------------
FROM tbl_importxml
WHERE 1 = 1 
<%= IfNotNull(":ID", " AND COL_ID = :ID ") %>
ORDER BY COL_ID DESC