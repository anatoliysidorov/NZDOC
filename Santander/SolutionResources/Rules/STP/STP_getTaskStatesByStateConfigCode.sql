SELECT ts.col_Id AS Id,
       ts.col_Name AS Name,
       ts.col_Code AS Code,
       ts.col_Description AS Description,
       ts.col_isDeleted AS IsDeleted,
       sc.col_Name AS StateConfig_Name,
       Nvl(ts.col_isdefaultoncreate, 0)   AS ISCREATE,
       Nvl(ts.col_isstart, 0)             AS ISSTART,
       Nvl(ts.col_isassign, 0)            AS ISASSIGN,
       Nvl(ts.col_isdefaultoncreate2, 0)  AS ISINPROCESS,
       Nvl(ts.col_isresolve, 0)           AS ISRESOLVE,
       Nvl(ts.col_isfinish, 0)            AS ISFINISH,
       case
         when Nvl(ts.col_isdefaultoncreate, 0) = 1  then 'ISCREATE'
         when Nvl(ts.col_isstart, 0) = 1            then 'ISSTART'
         when Nvl(ts.col_isassign, 0) = 1           then 'ISASSIGN'
         when Nvl(ts.col_isdefaultoncreate2, 0) = 1 then 'ISINPROCESS'
         when Nvl(ts.col_isfinish, 0) = 1           then 'ISFINISH'
         when Nvl(ts.col_isresolve, 0) = 1          then 'ISRESOLVE'
         else null end                    AS StateFlag,
       f_getNameFromAccessSubject(ts.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(ts.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(ts.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(ts.col_modifiedDate) AS ModifiedDuration
  FROM tbl_dict_stateconfig sc LEFT JOIN tbl_dict_taskstate ts ON ts.col_stateconfigtaskstate = sc.col_id
 WHERE     1 = 1
       AND (:StateConfig_Code IS NULL OR sc.col_code = :StateConfig_Code)
       
       
