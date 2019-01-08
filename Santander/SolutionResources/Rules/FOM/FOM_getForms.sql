SELECT ff.col_id AS id,
       ff.col_code AS code,
       ff.col_name AS NAME,
       ff.col_formmarkup AS FORMMARKUP,
       ff.col_description AS DESCRIPTION,
       ff.col_isdeleted AS isdeleted,
       'FORM' AS RAWTYPE,
       -------------------------------------------
       f_getNameFromAccessSubject(ff.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(ff.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(ff.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(ff.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
  FROM tbl_fom_form ff
 WHERE (:FOMFORM_Id IS NULL OR ff.col_id IN (SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:FOMFORM_Id, ','))))
       AND (:FORMCODES IS NULL OR LOWER(ff.col_code) IN (SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:FORMCODES, ','))))
<%=Sort("@SORT@","@DIR@")%>