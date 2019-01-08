SELECT col_id   AS Id,
       col_code AS Code,
       col_name AS NAME
FROM tbl_DICT_TaskEventType
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>