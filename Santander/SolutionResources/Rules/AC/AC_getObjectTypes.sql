select col_id         as id,
    col_name        as name,
    col_code        as code,
    col_isdeleted    as isdeleted,
    col_description    as description,
    f_getNameFromAccessSubject(col_createdBy) AS CreatedBy_Name,
    f_UTIL_getDrtnFrmNow(col_createdDate) AS CreatedDuration,
    f_getNameFromAccessSubject(col_modifiedBy) AS ModifiedBy_Name,
    f_UTIL_getDrtnFrmNow(col_modifiedDate) AS ModifiedDuration
from tbl_ac_accessobjecttype
where 1=1
	<%= IfNotNull(":IsDeleted", " AND COL_ISDELETED = :IsDeleted ") %>
	<%= IfNotNull(":ObjectType_Id", " AND COL_ID = :ObjectType_Id ") %>
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>