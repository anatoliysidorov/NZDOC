SELECT ID AS ID,
	NAME AS NAME
FROM VW_PPL_APPBASEGROUP
WHERE ((:Query IS NULL) OR (:Query IS NOT NULL AND UPPER(NAME) LIKE UPPER(:Query||'%')))
<%=Sort("@SORT@","@DIR@")%>