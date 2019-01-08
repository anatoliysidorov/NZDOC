SELECT col_code        AS Code, 
       col_id          AS Id, 
       col_description AS Description, 
       col_name        AS Name 
FROM   tbl_ppl_businessrole 
WHERE  1 = 1 
<%=Filter(OPTION=:Name_OPTION, VALUE1=:Name_VALUE1, VALUE2=:Name_VALUE2, FIELD=col_Name)%>  
<%=Sort("@SORT@","@DIR@")%>