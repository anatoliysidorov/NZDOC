    SELECT s1.dtid AS ID,
           s1.col_location AS LOCATION,
           s1.col_message AS MESSAGE,
           s1.col_rule AS RULE,
           s1.ttid AS TASKID,
           s1.col_taskid AS TASK_TASKID,
           s1.col_createddate AS CREATEDDATE,
           s1.col_accuratetime AS ACCURATETIME,
           s1.col_accuratetime - PRIOR s1.col_accuratetime AS TimeInterval,
           -------------------------------------------
           f_getNameFromAccessSubject(s1.col_createdBy) AS CreatedBy_Name,
           f_UTIL_getDrtnFrmNow(s1.col_createdDate) AS CreatedDuration,
           f_getNameFromAccessSubject(s1.col_modifiedBy) AS ModifiedBy_Name,
           f_UTIL_getDrtnFrmNow(s1.col_modifiedDate) AS ModifiedDuration
           -------------------------------------------
      FROM (SELECT ROWNUM AS rownumber, f.*
              FROM (  SELECT dt.col_id AS dtid,
                             dt.col_location,
                             dt.col_message,
                             dt.col_rule,
                             tt.col_id AS ttid,
                             tt.col_taskid,
                             dt.col_createdby,
                             dt.col_createddate,
                             dt.col_modifiedby,
                             dt.col_modifieddate,
                             dt.col_accuratetime
                        FROM tbl_debugtrace dt LEFT JOIN tbl_task tt ON dt.col_debugtracetask = tt.col_id
                       WHERE (dt.col_debugtracedebugsession = :SessionId)
                    ORDER BY dt.col_id ASC) f) s1
CONNECT BY s1.rownumber = PRIOR s1.rownumber + 1
START WITH s1.rownumber = 1