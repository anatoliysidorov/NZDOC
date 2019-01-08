SELECT col_id          AS ID, 
       col_name        AS Name, 
       col_code        AS Code, 
       col_description AS Description 
FROM   tbl_ppl_team 
WHERE :Name IS NULL OR LOWER(col_Name) LIKE '%' || LOWER(:Name) || '%'
<%=Sort("@SORT@","@DIR@")%>