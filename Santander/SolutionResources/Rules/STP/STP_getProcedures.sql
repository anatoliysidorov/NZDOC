SELECT P.col_id AS ID,
       p.col_description AS description,
       P.col_isdefault AS isdefault,
       p.col_name AS NAME,
       ct.col_ShowInPortal AS ShowInPortal,
       P.col_proceduredict_casesystype AS casesystype_id,
       ct.col_name AS casesystype_name,
       P.col_code AS code,
       NVL2 (:Id, dbms_xmlgen.CONVERT(P.col_config), NULL) AS CONFIG,
       p.col_CustomDataProcessor AS customdataprocessor,
       p.col_customvalidator AS customvalidator,
       p.col_IsDeleted AS isdeleted,
       p.col_RetCustDataProcessor AS retcustdataprocessor,
       p.col_RootTaskTypeCode AS roottasktypecode,
       p.col_UpdateCustDataProcessor AS updatecustdataprocessor,
       F_getnamefromaccesssubject (p.col_createdby) AS CreatedBy_Name,
       F_UTIL_getDrtnFrmNow (p.col_createddate) AS CreatedDuration,
       F_getnamefromaccesssubject (p.col_modifiedby) AS ModifiedBy_Name,
       F_UTIL_getDrtnFrmNow (p.col_modifieddate) AS ModifiedDuration
  FROM tbl_procedure P LEFT JOIN tbl_dict_casesystype ct ON (ct.col_id = P.col_proceduredict_casesystype)
 WHERE (:Id IS NULL OR (:Id IS NOT NULL AND p.col_id = :Id))
       AND (   :UNIFIED_SEARCH IS NULL
            OR LOWER (P.col_code) LIKE f_util_towildcards (:UNIFIED_SEARCH)
            OR LOWER (P.col_name) LIKE f_util_towildcards (:UNIFIED_SEARCH)
            OR LOWER (P.col_description) LIKE f_util_towildcards (:UNIFIED_SEARCH))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>