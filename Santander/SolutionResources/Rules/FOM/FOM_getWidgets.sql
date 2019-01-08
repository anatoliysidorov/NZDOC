SELECT col_Id AS Id,
       col_Type AS TYPE,
       col_Name AS Name,
       col_Code AS Code,
       col_Category AS Category,
       col_Image AS Image,
       NVL(col_isDeleted, 0) AS IsDeleted,
       col_Description AS Description,
       col_Config AS Config,
       f_getNameFromAccessSubject(col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(col_modifiedDate) AS ModifiedDuration
  FROM tbl_FOM_Widget
 WHERE (:WidgetId IS NULL OR (:WidgetId IS NOT NULL AND col_Id = :WidgetId))
<%=Sort("@SORT@","@DIR@")%>