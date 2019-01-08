SELECT
    col_id ID,
    col_code CODE,
    col_name NAME,
    col_ucode UCODE
FROM
    tbl_dict_containertype
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>
