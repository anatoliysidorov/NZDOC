SELECT l.col_id AS Id,
       l.col_eventname AS EventName,
       l.col_isdeleted AS IsDeleted,
       l.col_description AS Description,
       l.col_caselog AS Case_Id,
       l.col_tasklog AS Task_Id,
       l.Col_Smpl_Logdict_Customword as EventType_Id,
       w.col_name as EventTypeName,
       -------------------------------------------
       f_getNameFromAccessSubject(l.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(l.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(l.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(l.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
  FROM tbl_smpl_log l
  LEFT JOIN tbl_dict_customword w on w.col_id = l.Col_Smpl_Logdict_Customword
 WHERE     (:Id IS NULL OR (:Id IS NOT NULL AND l.col_id = :Id))
       AND (:Case_Id IS NULL OR (:Case_Id IS NOT NULL AND l.col_caselog = :Case_Id))
       AND (:Task_Id IS NULL OR (:Task_Id IS NOT NULL AND l.col_tasklog = :Task_Id))
       AND (:IsDeleted IS NULL OR (:IsDeleted IS NOT NULL AND l.col_isdeleted = :IsDeleted))
<%=Sort("@SORT@","@DIR@")%>