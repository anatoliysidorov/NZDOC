SELECT col_id   AS Id,
       col_name AS Name,
       col_code AS Code
  FROM tbl_dict_partyorgtype
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>