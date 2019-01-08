SELECT p.col_id AS Id,
       p.col_iconname AS IconName,
       p.col_icon AS Icon,
       p.col_icon AS IconCode,
       p.col_value AS VALUE,
       p.col_code AS Code,
       p.col_name AS Name,
       p.col_isdefault AS IsDefault,
       p.col_isdeleted AS IsDeleted,
       p.col_description AS Description,
       -------------------------------------------
       f_getNameFromAccessSubject(p.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(p.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_modifiedDate) AS ModifiedDuration
  -------------------------------------------
  FROM tbl_stp_priority p
 WHERE     (:Id IS NULL OR p.col_id = :Id)
       AND (:IsDeleted IS NULL OR NVL(p.col_isdeleted, 0) = :IsDeleted)
       AND (:IsDefault IS NULL OR p.col_isdefault = :IsDefault)
<%=IfNotNull("@SORT@", " order by @SORT@ @DIR@, 1")%>