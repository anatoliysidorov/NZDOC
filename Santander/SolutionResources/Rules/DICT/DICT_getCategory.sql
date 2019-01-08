SELECT s.*
  FROM (SELECT c.col_id AS id,
               c.col_id AS elementid,
               c.col_code AS code,
               c.col_name AS NAME,
               c.col_iconcode AS IconCode,
               c.col_colorcode AS ColorCode,
               c.col_isdeleted AS isDeleted,
               SUBSTR(c.col_description, 1, 4000) AS description,
               'CATEGORY' AS rawtype,
               c.COL_CATEGORYCATEGORY AS parentCategory,
               c.col_categoryorder AS CategoryOrder,
               c.COL_CATEGORYCATEGORY AS CalcParentId,
               -------------------------------------------
               f_getNameFromAccessSubject(c.col_createdby) AS CreatedBy_Name,
               f_UTIL_getDrtnFrmNow(c.col_createddate) AS CreatedDuration,
               f_getNameFromAccessSubject(c.col_modifiedby) AS ModifiedBy_Name,
               f_UTIL_getDrtnFrmNow(c.col_modifieddate) AS ModifiedDuration,
               -------------------------------------------
               'CATEGORY' || '-' || c.col_id AS CalcId,
               NVL2(c.COL_CATEGORYCATEGORY, 'CATEGORY' || '-' || c.COL_CATEGORYCATEGORY, '') AS CalcParentparentcategory,
               1 AS IsDeletable,
               1 AS IsModifiable
          FROM tbl_dict_customcategory c
        UNION ALL
        SELECT -1 AS id,
               -1 AS elementid,
               CAST('ROOT' AS NVARCHAR2(255)) AS Code,
               CAST('All Categories' AS NVARCHAR2(255)) AS NAME,
               NULL AS IconCode,
               NULL AS ColorCode,
               0 AS isDeleted,
               NULL AS description,
               'CATEGORY' AS rawtype,
               0 AS parentCategory,
               1 AS CategoryOrder,
               0 AS CalcParentId,
               -------------------------------------------
               NULL AS CreatedBy_Name,
               NULL AS CreatedDuration,
               NULL AS ModifiedBy_Name,
               NULL AS ModifiedDuration,
               -------------------------------------------
               NULL AS CalcId,
               NULL AS CalcParentparentcategory,
               0    AS IsDeletable,
               0    AS IsModifiable
          FROM DUAL) s
 WHERE (:Id IS NULL OR s.id = :Id)
   AND (:NotRoot IS NULL OR s.id <> -1)
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>