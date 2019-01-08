SELECT p.col_id AS Id,
       p.col_value AS VALUE,
       dbms_xmlgen.CONVERT(p.col_bigvalue) AS BigValue,
       p.col_name AS Name,
       p.col_isdeletable AS IsDeletable,
       p.col_isdeleted AS IsDeleted,
       p.col_ismodifiable AS IsModifiable,
       p.col_configid AS ConfigId,
       -------------------------------------------
       f_getNameFromAccessSubject(p.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(p.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_modifiedDate) AS ModifiedDuration
  -------------------------------------------
  FROM tbl_config p
 WHERE (:Config_Id IS NULL OR p.col_configid = :Config_Id) AND (:name IS NULL OR LOWER(p.col_name) = LOWER(:name))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>