SELECT r.col_id AS Id,
       r.col_name AS NAME,
       r.col_code AS Code,
       r.col_description AS Description,
       r.col_isdeleted AS IsDeleted,
       r.col_type AS TYPE,
       r.col_textstyle AS TextStyle,
       r.col_cellstyle AS CellStyle,
       r.col_rowstyle AS RowStyle,
       r.col_iconcode AS IconCode,
       r.col_theme AS Theme,
       -------------------------------------------
       f_getNameFromAccessSubject(r.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(r.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(r.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(r.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
  FROM tbl_stp_resolutioncode r
 WHERE (:TypeCode IS NULL OR LOWER(r.col_type) = LOWER(:TypeCode))
AND (:ID IS NULL OR r.col_id = :ID)
<%=Sort("@SORT@","@DIR@")%>