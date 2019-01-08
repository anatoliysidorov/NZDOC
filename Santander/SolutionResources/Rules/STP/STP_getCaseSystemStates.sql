  SELECT t.code, t.name, t.TYPE
    FROM (SELECT col_code AS code,
                 col_name AS name,
                 1 AS flag,
                 'start' AS TYPE
            FROM tbl_dict_casestate
           WHERE col_stateconfigcasestate = (SELECT sc.col_id
                                               FROM    tbl_dict_casesystype ct
                                                    INNER JOIN
                                                       tbl_dict_stateconfig sc
                                                    ON sc.col_id = ct.col_stateconfigcasesystype
                                              WHERE ct.col_id = :caseTypeId)
                 AND col_isstart = 1
          UNION ALL
          SELECT col_code AS code,
                 col_name AS name,
                 2 AS flag,
                 'inprocess' AS TYPE
            FROM tbl_dict_casestate
           WHERE     col_stateconfigcasestate = (SELECT sc.col_id
                                                   FROM    tbl_dict_casesystype ct
                                                        INNER JOIN
                                                           tbl_dict_stateconfig sc
                                                        ON sc.col_id = ct.col_stateconfigcasesystype
                                                  WHERE ct.col_id = :caseTypeId)
                 AND NVL (col_isstart, 0) = 0
                 AND NVL (col_isfinish, 0) = 0
          UNION ALL
          SELECT col_code AS code,
                 col_name AS name,
                 3 AS flag,
                 'finish' AS TYPE
            FROM tbl_dict_casestate
           WHERE col_stateconfigcasestate = (SELECT sc.col_id
                                               FROM    tbl_dict_casesystype ct
                                                    INNER JOIN
                                                       tbl_dict_stateconfig sc
                                                    ON sc.col_id = ct.col_stateconfigcasesystype
                                              WHERE ct.col_id = :caseTypeId)
                 AND col_isfinish = 1) t
ORDER BY t.flag, t.name