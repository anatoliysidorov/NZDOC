SELECT 
  l.col_Id AS ID,
  l.COL_MESSAGE AS MESSAGE,
  COL_ADDITIONALINFO as ADDITIONALINFO,
  l.col_IsSignificant AS ISSIGNIFICANT,
  f_getnamefromaccesssubject(l.COL_CREATEDBY) AS CREATEDBY_NAME, 
  f_util_getdrtnfrmnow(l.COL_CREATEDDATE) AS CREATEDDURATION
FROM TBL_UTIL_Log l
WHERE 1 = 1 
<%=IfNotNull(":CREATEDDATEFROM", "AND trunc(l.COL_CREATEDDATE) >= trunc(to_date(:CREATEDDATEFROM))")%>
<%=IfNotNull(":CREATEDDATETO", "AND trunc(l.COL_CREATEDDATE) <= trunc(to_date(:CREATEDDATETO))")%>		
<%= IFNOTNULL("@SORT@", " ORDER BY @SORT@ @DIR@, 1 ") %>