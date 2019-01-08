SELECT p.bocode       AS Code, 
       p.botablename   AS TableName
		-------------------------------------------  
FROM   vw_fom_businessobject p
WHERE  (:Object_Id IS NULL OR (:Object_Id IS NOT NULL AND p.bocode = :Object_Id )) 
<%=Sort("@SORT@","@DIR@")%>