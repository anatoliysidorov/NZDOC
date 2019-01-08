  SELECT ap.*,
         f_getNameFromAccessSubject(ap.createdBy) AS CreatedBy_Name,
         f_UTIL_getDrtnFrmNow(ap.createdDate) AS CreatedDuration,
         f_getNameFromAccessSubject(ap.modifiedBy) AS ModifiedBy_Name,
         f_UTIL_getDrtnFrmNow(ap.modifiedDate) AS ModifiedDuration
    FROM vw_dcm_assocpage ap
         LEFT JOIN tbl_dict_casesystype cst
            ON ap.casesystype = cst.col_id
         LEFT JOIN tbl_dict_tasksystype tst
            ON ap.tasksystype = tst.col_id
   WHERE     (:IsDeleted IS NULL OR NVL(ap.isDeleted, 0) = :IsDeleted)
         AND (:PAGETYPE_CODE IS NULL OR (:PAGETYPE_CODE IS NOT NULL AND UPPER(ap.PAGETYPE_CODE) = UPPER(:PAGETYPE_CODE)))
         AND (   (ap.id = :Id)
              OR (ap.CASESYSTYPE = :CASESYSTYPE)
              OR (LOWER(cst.col_code) = LOWER(:CaseSysType_Code))
              OR (ap.CASESYSTYPE = (SELECT COL_PROCEDUREDICT_CASESYSTYPE
                                      FROM tbl_procedure
                                     WHERE UPPER(col_code) = UPPER(:Procedure_Code)))
              OR (ap.TASKSYSTYPE = :TASKSYSTYPE)
              OR (ap.WORKACTIVITYTYPE = :WORKACTIVITYTYPE)
              OR (LOWER(tst.col_code) = LOWER(:TaskSysType_Code))
              OR (ap.TASKTEMPLATE = :TASKTEMPLATE)
              OR (ap.PARTYTYPE = :PARTYTYPE)
              OR (ap.DOCTYPE = :DOCTYPE))
ORDER BY ShowOrder ASC