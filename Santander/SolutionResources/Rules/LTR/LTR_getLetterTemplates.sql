SELECT lt.col_id AS Id,
       lt.col_code AS Code,
       lt.col_name AS Name,
       lt.col_description AS Description,
       lt.col_markup AS Markup,
       -------------------------------------------
       f_getNameFromAccessSubject(lt.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(lt.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(lt.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(lt.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
  FROM tbl_ltr_lettertemplate lt
 WHERE (:Id IS NULL OR lt.col_id = :Id)
<%=Sort("@SORT@","@DIR@")%>