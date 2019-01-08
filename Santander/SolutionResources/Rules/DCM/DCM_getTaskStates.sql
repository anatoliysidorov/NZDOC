SELECT tskst.col_id                         ID, 
       tskst.col_name                       NAME, 
       tskst.col_code                       CODE, 
       tskst.col_activity                   ACTIVITY, 
       Nvl(tskst.col_isdefaultoncreate, 0)  ISCREATE, 
       Nvl(tskst.col_isstart, 0)            ISSTART, 
       Nvl(tskst.col_isassign, 0)           ISASSIGN, 
       Nvl(tskst.col_isdefaultoncreate2, 0) ISINPROCESS, 
       Nvl(tskst.col_isresolve, 0)          ISRESOLVE, 
       Nvl(tskst.col_isfinish, 0)           ISFINISH, 
       tskst.col_stateconfigtaskstate       STATECONFIG 
FROM   tbl_task tsk 
       left join tbl_dict_tasksystype tst 
              ON tst.col_id = tsk.col_taskdict_tasksystype 
       left join tbl_dict_taskstate tskst 
              ON Nvl(tst.col_stateconfigtasksystype, 0) = 
                 Nvl(tskst.col_stateconfigtaskstate, 0) 
WHERE  tsk.col_id = :TaskId 