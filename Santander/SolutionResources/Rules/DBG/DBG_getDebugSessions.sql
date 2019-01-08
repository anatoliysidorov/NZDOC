SELECT td.col_id AS ID,
     td.col_code AS CODE,
     tc.col_id AS CASE_ID,
     tc.col_caseid AS CASE_CASEID,
     tc.COL_SUMMARY AS CASE_SUMMARY,
     tdc.col_NAME AS CASETYPE_NAME,
     -------------------------------------------
     f_getNameFromAccessSubject(td.col_createdBy) AS CreatedBy_Name,
     f_UTIL_getDrtnFrmNow(td.col_createdDate) AS CreatedDuration,
     f_getNameFromAccessSubject(td.col_modifiedBy) AS ModifiedBy_Name,
     f_UTIL_getDrtnFrmNow(td.col_modifiedDate) AS ModifiedDuration
-------------------------------------------
FROM tbl_debugsession td 
LEFT JOIN tbl_case tc ON td.col_debugsessioncase = tc.col_id
LEFT JOIN TBL_DICT_CASESYSTYPE tdc ON tdc.col_Id = tc.COL_CASEDICT_CASESYSTYPE
WHERE NVL(td.COL_DEBUGSESSIONCASE, 0) > 0
ORDER BY td.col_CREATEDDATE DESC