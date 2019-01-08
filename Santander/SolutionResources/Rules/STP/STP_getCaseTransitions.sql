  SELECT t.*
    FROM (SELECT ct.col_id AS id,
                 ct.col_name AS name,
                 ct.col_description AS description,
                 ct.col_code AS code,
                 ct.col_manualonly AS manualonly,
                 ct.col_iconcode AS transitionIconcode,
                 ss.col_id AS source_id,
                 ss.col_code AS source_code,
                 ss.col_activity AS source_activity,
                 ss.col_name AS source_name,
                 st.col_id AS target_id,
                 st.col_code AS target_code,
                 st.col_activity AS target_activity,
                 st.col_name AS target_name,
                 ss.col_name || ' to ' || st.col_name AS calc_name,
                 NVL(sc.col_code, 'DEFAULT') AS milestone_code,
                 NVL(sc.col_name, 'Default') AS milestone_name,
                 f_getNameFromAccessSubject(ct.col_createdBy) AS CreatedBy_Name,
                 f_UTIL_getDrtnFrmNow(ct.col_createdDate) AS CreatedDuration,
                 f_getNameFromAccessSubject(ct.col_modifiedBy) AS ModifiedBy_Name,
                 f_UTIL_getDrtnFrmNow(ct.col_modifiedDate) AS ModifiedDuration
            FROM tbl_dict_casetransition ct
                 LEFT JOIN tbl_dict_casestate ss
                    ON ct.col_sourcecasetranscasestate = ss.col_id
                 LEFT JOIN tbl_dict_casestate st
                    ON ct.col_targetcasetranscasestate = st.col_id
                 LEFT JOIN tbl_dict_stateconfig sc
                    ON ss.col_stateconfigcasestate = sc.col_id
                 LEFT JOIN tbl_dict_casesystype dict_ct
                    ON dict_ct.col_stateconfigcasesystype = ss.col_stateconfigcasestate
           WHERE 1 = 1 AND (:Id IS NULL OR ct.col_id = :Id) AND (:CaseTypeId IS NULL OR dict_ct.col_id = :CaseTypeId)) t
ORDER BY t.milestone_name, t.name