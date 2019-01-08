SELECT ds.col_id                                                 AS id, 
       ds.col_code                                               AS code, 
       ds.col_name                                               AS NAME, 
       ds.col_description                                        AS description, 
       ds.col_isdeleted                                          AS isdeleted, 
       ------------------------------------------- 
       F_getnamefromaccesssubject(ds.col_createdby)              AS CreatedBy_Name, 
       F_UTIL_getDrtnFrmNow(ds.col_createddate)              AS CreatedDuration
		-------------------------------------------  
FROM   tbl_dict_docsource ds 
WHERE  (:DocSource_Id IS NULL OR (:DocSource_Id IS NOT NULL AND ds.col_id = :DocSource_Id )) 
<%=Sort("@SORT@","@DIR@")%>