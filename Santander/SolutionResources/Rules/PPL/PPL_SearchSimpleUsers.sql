SELECT *
FROM   vw_users 
WHERE (:Name IS NULL OR (LOWER(name) LIKE f_UTIL_toWildcards(:Name)))
<%=Sort("@SORT@","@DIR@")%>