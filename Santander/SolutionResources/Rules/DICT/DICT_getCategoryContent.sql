SELECT s1.id             AS ID,
       s1.id             AS elementid,
       s1.parentCategory AS parentcategory,
       s1.code           AS code,
       s1.name           AS NAME,
       s1.VALUE          AS VALUE,
       s1.rowstyle       AS rowstyle,
       s1.style          AS style,
       s1.isdeleted      AS isdeleted,
       s1.rawtype        AS rawtype,
       s1.description    AS description,
       s1.WordOrder      AS wordorder,
       -------------------------------------------
       f_getNameFromAccessSubject(s1.createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(s1.createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(s1.modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(s1.modifiedDate) AS ModifiedDuration,
       -------------------------------------------
       s1.rawtype || '-' || s1.id AS CalcId,
       NVL2(s1.parentCategory, 'CATEGORY' || '-' || s1.parentcategory, '') AS CalcParentparentcategory,
       1 AS IsDeletable,
       1 AS IsModifiable
  FROM (SELECT w.col_id AS id,
               w.col_code AS code,
               w.col_name AS NAME,
               w.col_value AS VALUE,
               w.col_rowstyle AS rowstyle,
               w.col_style AS style,
               w.col_createdby AS createdby,
               w.col_createddate AS createddate,
               w.col_modifiedby AS modifiedby,
               w.col_modifieddate AS modifieddate,
               w.col_isdeleted AS isDeleted,
               dbms_lob.substr(w.col_description, 2000, 1) AS description,
               'WORD' AS rawtype,
               w.COL_WORDCATEGORY AS parentCategory,
               w.col_wordorder AS WordOrder
          FROM tbl_dict_customword w
         WHERE (:ParentCategory IS NULL OR (NVL(w.COL_WORDCATEGORY, 0) = NVL(:ParentCategory, 0)))
           AND (:WordId IS NULL OR w.col_id = :WordId)) s1
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>