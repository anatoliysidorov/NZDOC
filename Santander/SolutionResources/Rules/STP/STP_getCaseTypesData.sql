SELECT ct.col_id AS Id,
       ct.col_code AS Code,
       ct.col_name AS Name,
       'STATE' AS DataType,
       Csst.col_id AS DataId,
       Csst.col_code AS DataCode,
       Csst.col_name AS DataName
  FROM    tbl_dict_casesystype ct
       LEFT JOIN
          tbl_dict_casestate csst
       ON NVL (ct.col_stateconfigcasesystype, 0) = NVL (Csst.Col_Stateconfigcasestate, 0) AND NVL (Csst.col_isdeleted, 0) = 0
 WHERE ct.col_id IN
          (WITH s1
                AS (SELECT CASE
                              WHEN (SELECT COUNT (*)
                                      FROM    tbl_dict_casesystype ct
                                           LEFT JOIN
                                              tbl_dict_procedureincasetype pict
                                           ON ct.col_casetypeprocincasetype = pict.col_id
                                     WHERE (:ProcedureId IS NULL OR ct.col_casesystypeprocedure = :ProcedureId)
                                           AND (:CaseTypeId IS NULL OR ct.col_id = :CaseTypeId)) > 0
                              THEN
                                 (SELECT Code
                                    FROM (SELECT LOWER (pict.col_code) AS Code, ROW_NUMBER () OVER (ORDER BY ct.col_id) AS RowNumber
                                            FROM    tbl_dict_casesystype ct
                                                 LEFT JOIN
                                                    tbl_dict_procedureincasetype pict
                                                 ON ct.col_casetypeprocincasetype = pict.col_id
                                           WHERE (:ProcedureId IS NULL OR ct.col_casesystypeprocedure = :ProcedureId)
                                                 AND (:CaseTypeId IS NULL OR ct.col_id = :CaseTypeId))
                                   WHERE RowNumber = 1)
                              ELSE
                                 N'dedicated_single'
                           END
                              AS ProcInCaseType
                      FROM DUAL)
           SELECT col_id
             FROM tbl_dict_casesystype
            WHERE     (:ProcedureId IS NULL OR col_casesystypeprocedure = :ProcedureId)
                  AND (:CaseTypeId IS NULL OR col_id = :CaseTypeId)
                  AND (SELECT LOWER (ProcInCaseType) FROM s1) = 'shared_single'
           UNION
           SELECT col_proceduredict_casesystype
             FROM tbl_procedure pr
            WHERE     (:ProcedureId IS NULL OR col_id = :ProcedureId)
                  AND (:CaseTypeId IS NULL OR col_proceduredict_casesystype = :CaseTypeId)
                  AND (SELECT LOWER (ProcInCaseType) FROM s1) IN ('dedicated_multiple', 'dedicated_single'))
UNION ALL
SELECT ct.col_id AS Id,
       ct.col_code AS Code,
       ct.col_name AS Name,
       'RESOLUTION_CODE' AS DataType,
       rc.col_id AS DataId,
       rc.col_code AS DataCode,
       rc.col_name AS DataName
  FROM tbl_dict_casesystype ct
       INNER JOIN tbl_casesystyperesolutioncode cstrc
          ON ct.col_id = cstrc.col_tbl_dict_casesystype
       INNER JOIN tbl_stp_resolutioncode rc
          ON cstrc.col_casetyperesolutioncode = rc.col_id AND NVL (rc.col_isdeleted, 0) = 0
 WHERE ct.col_id IN
          (WITH s1
                AS (SELECT CASE
                              WHEN (SELECT COUNT (*)
                                      FROM    tbl_dict_casesystype ct
                                           LEFT JOIN
                                              tbl_dict_procedureincasetype pict
                                           ON ct.col_casetypeprocincasetype = pict.col_id
                                     WHERE (:ProcedureId IS NULL OR ct.col_casesystypeprocedure = :ProcedureId)
                                           AND (:CaseTypeId IS NULL OR ct.col_id = :CaseTypeId)) > 0
                              THEN
                                 (SELECT Code
                                    FROM (SELECT LOWER (pict.col_code) AS Code, ROW_NUMBER () OVER (ORDER BY ct.col_id) AS RowNumber
                                            FROM    tbl_dict_casesystype ct
                                                 LEFT JOIN
                                                    tbl_dict_procedureincasetype pict
                                                 ON ct.col_casetypeprocincasetype = pict.col_id
                                           WHERE (:ProcedureId IS NULL OR ct.col_casesystypeprocedure = :ProcedureId)
                                                 AND (:CaseTypeId IS NULL OR ct.col_id = :CaseTypeId))
                                   WHERE RowNumber = 1)
                              ELSE
                                 N'dedicated_single'
                           END
                              AS ProcInCaseType
                      FROM DUAL)
           SELECT col_id
             FROM tbl_dict_casesystype
            WHERE     (:ProcedureId IS NULL OR col_casesystypeprocedure = :ProcedureId)
                  AND (:CaseTypeId IS NULL OR col_id = :CaseTypeId)
                  AND (SELECT LOWER (ProcInCaseType) FROM s1) = 'shared_single'
           UNION
           SELECT col_proceduredict_casesystype
             FROM tbl_procedure
            WHERE     (:ProcedureId IS NULL OR col_id = :ProcedureId)
                  AND (:CaseTypeId IS NULL OR col_proceduredict_casesystype = :CaseTypeId)
                  AND (SELECT LOWER (ProcInCaseType) FROM s1) IN ('dedicated_multiple', 'dedicated_single'))
UNION ALL
SELECT ct.col_id AS Id,
       ct.col_code AS Code,
       ct.col_name AS Name,
       'MILESTONE' AS DataType,
       s.col_id AS DataId,
       s.col_commoncode AS DataCode,
       s.col_name AS DATANAME
  FROM tbl_dict_casesystype ct
       LEFT JOIN tbl_dict_stateconfig sc
          ON ct.col_id = sc.col_casesystypestateconfig AND sc.col_iscurrent = 1
       LEFT JOIN tbl_dict_state s
          ON s.col_statestateconfig = sc.col_id
       LEFT JOIN tbl_dict_casestate cs
          ON cs.col_id = s.col_statecasestate
 WHERE     (:ProcedureId IS NULL OR ct.col_casesystypeprocedure = :ProcedureId)
       AND (:CaseTypeId IS NULL OR ct.col_id = :CaseTypeId)
       AND NVL (ct.col_isdeleted, 0) = 0
ORDER BY Name, DataType, DataName