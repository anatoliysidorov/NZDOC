SELECT i.col_id AS Id,
       i.col_name AS Name,
       i.col_code AS Code,
       i.col_isdeleted AS IsDeleted,
       i.col_description AS Description,
       dbms_xmlgen.CONVERT(i.col_config) AS Config,
       -------------------------------------------
       f_getNameFromAccessSubject(i.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(i.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(i.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(i.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
  FROM tbl_int_integtarget i
 WHERE     (:Id IS NULL OR (:Id IS NOT NULL AND i.col_id = :Id))
       AND (:Name IS NULL OR (:Name IS NOT NULL AND UPPER(i.col_name) = UPPER(:Name)))
       AND (:Code IS NULL OR (:Code IS NOT NULL AND UPPER(i.col_code) = UPPER(:Code)))
       AND (:IsDeleted IS NULL OR (:IsDeleted IS NOT NULL AND i.col_isdeleted = :IsDeleted))
<%=Sort("@SORT@","@DIR@")%>