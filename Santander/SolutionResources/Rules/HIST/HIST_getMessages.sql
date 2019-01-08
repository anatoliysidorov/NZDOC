SELECT    m.col_id ID,
          m.Col_Code Code,
          m.col_messagetypemessage AS MessageType,
          mt.col_Name AS MessageTypeName,
          mt.col_code AS MessageTypeCode,
          mt.COL_COLORTHEME AS MessageTypeColorCode,
          m.Col_Template AS MessageTemplate,
          m.Col_Description AS Description,
          /*-------------------------------------------*/
          f_getNameFromAccessSubject(m.col_createdBy) AS CreatedBy_Name,
          f_UTIL_getDrtnFrmNow(m.col_createdDate) AS CreatedDuration,
          f_getNameFromAccessSubject(m.col_modifiedBy) AS ModifiedBy_Name,
          f_UTIL_getDrtnFrmNow(m.col_modifiedDate) AS ModifiedDuration
          /*-------------------------------------------*/
FROM      tbl_message m
LEFT JOIN tbl_DICT_MessageType mt ON mt.col_id = m.col_messagetypemessage
WHERE     :Message_Id IS NULL OR m.col_id = :Message_Id
<%=Sort("@SORT@","@DIR@")%>