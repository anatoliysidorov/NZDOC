SELECT dt.col_id                                                 AS id, 
       dt.col_code                                               AS code, 
       dt.col_name                                               AS NAME, 
       dt.col_isdeleted                                          AS isdeleted,
       dt.col_description                                        AS description, 
       ------------------------------------------- 
       F_getnamefromaccesssubject(dt.col_createdby)              AS CreatedBy_Name, 
       F_UTIL_getDrtnFrmNow(dt.col_createddate)                  AS CreatedDuration,
       F_getnamefromaccesssubject(dt.col_modifiedby)             AS ModifiedBy_Name, 
       F_UTIL_getDrtnFrmNow(dt.col_modifieddate)                 AS ModifiedDuration
       -------------------------------------------  
FROM   tbl_dict_DocumentType dt 
WHERE  (:DocType_Id IS NULL OR (:DocType_Id IS NOT NULL AND dt.col_id = :DocType_Id )) 
<%=Sort("@SORT@","@DIR@")%>