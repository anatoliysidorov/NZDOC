SELECT col_id   AS Id,
       col_code AS Code,
       col_name AS NAME
  FROM tbl_dict_commoneventtype
 WHERE (:CaseType IS NULL OR UPPER(col_purpose) = 'CASE')
   AND (:PROCEDURE IS NULL OR UPPER(col_purpose) = 'PROCEDURE')
   AND (:TaskType IS NULL OR UPPER(col_purpose) = 'TASK')
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>