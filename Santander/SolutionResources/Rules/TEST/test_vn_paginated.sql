SELECT cl.col_id AS LINKID,
       cl.col_caselinkdict_linktype AS LINK_TYPE,
       lt.col_code AS LINK_TYPECODE,
       lt.col_name AS LINK_TYPENAME,
       cl.col_description AS LINK_DESCRIPTION,
       cl.col_caselinkparentcase AS LINK_PARENTCASEID,
       (select CASESTATE_ISFINISH  from vw_dcm_simplecase where id = cl.col_caselinkparentcase) AS LINK_PARENTCASESTATE_ISFINISH,
       cl.col_caselinkchildcase AS LINK_CHILDCASEID,
       f_getNameFromAccessSubject(cl.col_CreatedBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(cl.col_CreatedDate) AS CreatedDuration,
       f_getNameFromAccessSubject(cl.col_ModifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(cl.col_ModifiedDate) AS ModifiedDuration,
       cv.*
  FROM tbl_caselink cl
       LEFT JOIN vw_dcm_simplecase cv
          ON cv.id = cl.col_caselinkchildcase
       LEFT JOIN tbl_dict_linktype lt
          ON lt.col_id = cl.col_caselinkdict_linktype
 WHERE (:ID IS NULL OR (cl.col_id = :ID))
 <%=IfNotNull(":Case_Id", "AND LEVEL = 1")%>
 <%=IfNotNull(":Case_Id", "START WITH cl.col_caselinkparentcase = :Case_Id OR cl.col_caselinkchildcase = :Case_Id CONNECT BY NOCYCLE PRIOR cl.col_caselinkparentcase = cl.col_caselinkchildcase ")%> 