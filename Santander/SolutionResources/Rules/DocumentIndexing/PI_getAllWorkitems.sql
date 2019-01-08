SELECT wi.col_id AS Id,
    wi.col_code AS Code,
    wi.col_name AS Name,
    wi.col_title AS Title,
    wi.col_isdeleted AS ISDELETED,
    extractValue(c.col_customdata,'/CONTENT/FROM') AS SourceFrom,
	wi.col_pi_workitemppl_workbasket as WORKBASKET_ID,
    wbs.calcname AS CurrentWorkbasketName,
    pwbs.calcname AS PrevWorkbasketName,
    ct.col_name AS SourceType,
    st.col_id AS State_id,
    st.col_name AS State_Name,
    st.col_code AS State_Code,
    st.col_iconcode AS State_Icon,
    f_getNameFromAccessSubject(wi.col_createdBy) AS CreatedBy_Name,
    f_UTIL_getDrtnFrmNow(wi.col_createdDate) AS CreatedDuration,
    f_getNameFromAccessSubject(wi.col_modifiedBy) AS ModifiedBy_Name,
    f_UTIL_getDrtnFrmNow(wi.col_modifiedDate) AS ModifiedDuration
FROM tbl_pi_workitem wi
    LEFT JOIN vw_ppl_simpleworkbasket wbs  ON wi.col_pi_workitemppl_workbasket = wbs.col_id
    LEFT JOIN vw_ppl_simpleworkbasket pwbs ON pwbs.id = wi.col_pi_workitemprevworkbasket
    LEFT JOIN tbl_doc_document pdoc     ON pdoc.col_isprimary = 1 AND pdoc.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id
    LEFT JOIN tbl_container c           ON pdoc.COL_DOC_DOCUMENTCONTAINER = c.col_id
    LEFT JOIN tbl_dict_containertype ct ON c.COL_CONTAINERCONTAINERTYPE = ct.COL_ID
    LEFT JOIN tbl_dict_documenttype dt  ON dt.col_id = pdoc.col_DocType
    LEFT JOIN tbl_dict_state st         ON st.col_id = wi.col_pi_workitemdict_state
WHERE 1 = 1
<%=IfNotNull(":SourceType", " and ct.col_id = :SourceType")%>
<%=IfNotNull(":CreatedEnd", " and trunc(wi.col_createdDate) <= trunc(to_date(:CreatedEnd)) ")%>
<%=IfNotNull(":CreatedStart", " and trunc(wi.col_createdDate) >= trunc(to_date(:CreatedStart))")%>
<%=IfNotNull(":CurrentWorkbasket", " and wi.col_pi_workitemppl_workbasket = :CurrentWorkbasket")%>
<%=IfNotNull(":Title", " AND lower(wi.col_title) like '%' || :Title || '%' ")%>

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>