SELECT col_id ID,
       Col_Placeholder Name,
       col_value VALUE,
       Col_Processorcode Processorcode,
       Col_Description Description,
       -------------------------------------------
       f_getNameFromAccessSubject(col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(col_modifiedDate) AS ModifiedDuration
  -------------------------------------------
  FROM tbl_messageplaceholder
 WHERE (:Placeholder_Id IS NULL OR col_id = :Placeholder_Id)
 ANd (:Placeholder_Name IS NULL OR UPPER(Col_Placeholder) = UPPER(:Placeholder_Name))
<%=Sort("@SORT@","@DIR@")%>