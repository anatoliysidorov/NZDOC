SELECT     tss.COL_MAP_TASKSTATEINITTASK AS ChildTask,
           t.COL_CASETASK AS CaseId,
           tst.COL_MAP_TASKSTATEINITTASK AS ParentTask
FROM       tbl_TaskDependency td
INNER JOIN TBL_MAP_TaskStateInitiation tss ON td.COL_TSKDPNDCHLDTSKSTATEINIT = tss.col_id
INNER JOIN tbl_task t                      ON t.col_id = tss.COL_MAP_TASKSTATEINITTASK
INNER JOIN TBL_MAP_TaskStateInitiation tst ON td.COL_TSKDPNDPRNTTSKSTATEINIT = tst.col_id
WHERE      t.COL_CASETASK = :Case_Id
           OR
           t.COL_CASETASK =(
           SELECT COL_CASETASK
           FROM   TBL_TASK
           WHERE  COL_ID = :Task_Id
           ) 