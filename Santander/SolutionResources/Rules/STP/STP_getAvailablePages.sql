SELECT name AS NAME,
     elementid AS ELEMENTID,
     rawtype AS RAWTYPE,
     rawtype || '-' || elementid AS CalcId,
     IsDeleted AS ISDELETED
FROM (SELECT ff.col_name AS NAME,
             TO_CHAR(ff.col_id) AS elementid,
             'FORM' AS rawtype,
             'FORM' AS rawtype1,
             ff.col_isDeleted AS IsDeleted
        FROM tbl_fom_form ff
      UNION
      SELECT dp.name AS NAME,
             TO_CHAR(dp.code) AS elementid,
             'APPBASE_PAGE' AS RAWTYPE,
             'APPBASE_PAGE' AS RAWTYPE1,
             NULL AS IsDeleted
        FROM vw_util_deployedpage dp
      UNION
      SELECT cp.col_name AS NAME,
             TO_CHAR(cp.col_id) AS elementid,
             'CODED_PAGE' AS rawtype,
             'CODED_PAGE' AS rawtype1,
             cp.col_isDeleted AS IsDeleted
        FROM tbl_fom_codedpage cp
      UNION
      SELECT p.col_name AS NAME,
             TO_CHAR(p.col_id) AS elementid,
             'PAGE' AS rawtype,
             'PAGE_DESIGNER_CASE_DETAIL' AS rawtype1,
             p.col_isDeleted AS IsDeleted
        FROM tbl_fom_page p
       WHERE LOWER(p.col_usedfor) = 'case'
            AND (:CASESYSTYPE is NULL or ((p.COL_PAGECASESYSTYPE is NULL) or (p.COL_PAGECASESYSTYPE = :CASESYSTYPE)))
      UNION
      SELECT p.col_name AS NAME,
             TO_CHAR(p.col_id) AS elementid,
             'PAGE' AS rawtype,
             'PAGE_DESIGNER_TASK_DETAIL' AS rawtype1,
             p.col_isDeleted AS IsDeleted
        FROM tbl_fom_page p
       WHERE LOWER(p.col_usedfor) = 'task'
      UNION
      SELECT p.col_name AS NAME,
             TO_CHAR(p.col_id) AS elementid,
             'PAGE' AS rawtype,
             'PAGE_DESIGNER_PARTY_DETAIL' AS rawtype1,
             p.col_isDeleted AS IsDeleted
        FROM tbl_fom_page p
       WHERE LOWER(p.col_usedfor) = 'extparty'
      UNION
      SELECT p.col_name AS NAME,
             TO_CHAR(p.col_id) AS elementid,
             'PAGE' AS rawtype,
             'PAGE_DESIGNER_PORTALCASE_DETAIL' AS rawtype1,
             p.col_isDeleted AS IsDeleted
        FROM tbl_fom_page p
       WHERE LOWER(p.col_usedfor) = 'portalcase'
            AND (:CASESYSTYPE is NULL or ((p.COL_PAGECASESYSTYPE is NULL) or (p.COL_PAGECASESYSTYPE = :CASESYSTYPE)))
      UNION
      SELECT p.col_name AS NAME,
             TO_CHAR(p.col_id) AS elementid,
             'PAGE' AS rawtype,
             'PAGE_DESIGNER_PORTALTASK_DETAIL' AS rawtype1,
             p.col_isDeleted AS IsDeleted
        FROM tbl_fom_page p
       WHERE LOWER(p.col_usedfor) = 'portaltask')
WHERE (:IsDeleted IS NULL OR NVL(isDeleted, 0) = :IsDeleted)
     AND (:Purpose IS NULL
          OR (   (:Purpose = 'PORTAL_DETAIL' AND rawtype IN ('FORM'))
              OR (:Purpose = 'DETAIL' AND rawtype IN ('FORM', 'APPBASE_PAGE', 'CODED_PAGE'))
              OR (:Purpose IN ('CLOSE', 'RESOLVE') AND rawtype IN ('APPBASE_PAGE'))
              OR (:Purpose IN ('NEW', 'EDIT', 'PORTAL_NEW', 'PORTAL_EDIT') AND rawtype IN ('FORM'))
              OR (:Purpose IN ('FULL_PAGE_CASE_DETAIL') AND rawtype1 IN ('PAGE_DESIGNER_CASE_DETAIL', 'APPBASE_PAGE'))
              OR (:Purpose IN ('FULL_PAGE_TASK_DETAIL') AND rawtype1 IN ('PAGE_DESIGNER_TASK_DETAIL', 'APPBASE_PAGE'))
              OR (:Purpose IN ('FULL_PAGE_PARTY_DETAIL') AND rawtype1 IN ('PAGE_DESIGNER_PARTY_DETAIL', 'APPBASE_PAGE'))
              OR (:Purpose IN ('FULL_PAGE_PORTALCASE_DETAIL') AND rawtype1 IN ('PAGE_DESIGNER_PORTALCASE_DETAIL', 'APPBASE_PAGE'))
              OR (:Purpose IN ('FULL_PAGE_PORTALTASK_DETAIL') AND rawtype1 IN ('PAGE_DESIGNER_PORTALTASK_DETAIL', 'APPBASE_PAGE'))))
ORDER BY RAWTYPE DESC, name ASC