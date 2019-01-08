SELECT dl.col_id                                                 AS id, 
       dl.col_code                                               AS code, 
       dl.col_name                                               AS NAME, 
       dl.col_isdeleted                                          AS isdeleted, 
       dl.col_description										 AS description,
       ------------------------------------------- 
       F_getnamefromaccesssubject(dl.col_createdby)              AS CreatedBy_Name, 
       F_UTIL_getDrtnFrmNow(dl.col_createddate)                  AS CreatedDuration
       F_getnamefromaccesssubject(dl.col_modifiedby)             AS ModifiedBy_Name, 
       F_UTIL_getDrtnFrmNow(dl.col_modifieddate)                 AS ModifiedDuration
		-------------------------------------------  
FROM   tbl_dict_doclocation dl 
WHERE  (:DocLocation_Id IS NULL OR (:DocLocation_Id IS NOT NULL AND dl.col_id = :DocLocation_Id )) 
<%=Sort("@SORT@","@DIR@")%>