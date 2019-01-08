  SELECT tsk.col_id                    AS ID,
       tsk.col_taskid                  AS TASKID,
       tsk.col_name                    AS TASKNAME,
       tsk.col_taskorder               AS TaskOrder,
       tsk.col_casetask                AS CASEID,
       tsk.col_parentid                AS PARENTID,
       tsk.col_createdby               AS CreatedBy,
       tsk.col_createddate             AS CreatedDate,
       tsk.col_modifiedby              AS ModifiedBy,
       tsk.col_modifieddate            AS ModifiedDate,
       tsk.col_taskdict_tasksystype    AS CaseSysType,
       dts.col_id                      AS TASKSTATE_ID,
       dts.col_name                    AS TASKSTATE_NAME,
       dts.col_isdefaultoncreate       AS TASKSTATE_ISDEFAULTONCREATE,
       dts.col_isstart                 AS TASKSTATE_ISSTART,
       dts.col_isresolve               AS TASKSTATE_ISRESOLVE,
       dts.col_isfinish                AS TASKSTATE_ISFINISH,
       wb.col_id                       AS WORKBASKET_ID,
       wb.col_code                     AS WORKBASKET_CODE,
       wb.col_name                     AS WORKBASKET_NAME,
      CASE
        WHEN dts.col_isfinish = 1 THEN 0
        WHEN tse.prevsladatetime IS NULL AND tse.nextsladatetime IS NULL THEN 0
        WHEN prevsladatetime IS NOT NULL THEN (-1 * F_util_getdrtnfrmnow(tse.prevsladatetime))
      ELSE (-1* F_util_getdrtnfrmnow(tse.nextsladatetime)) END as UNIFIEDSLA
FROM   tbl_task tsk
LEFT JOIN  tbl_dict_taskstate dts          ON tsk.col_taskdict_taskstate = dts.col_id
LEFT JOIN  tbl_ppl_workbasket wb      ON tsk.col_taskppl_workbasket = wb.col_id
LEFT JOIN  vw_dcm_taskslaprimaryevent6 tse ON tsk.col_id = tse.nexttaskid AND tsk.col_id = tse.prevtaskid
