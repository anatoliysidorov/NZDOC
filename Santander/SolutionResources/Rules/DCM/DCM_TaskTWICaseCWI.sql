SELECT tsk.col_id                    AS Id, 
       tsk.col_id                       AS COL_Id, 
       tsk.col_id                    AS TaskId, 
       tsk.col_dateassigned          AS dateassigned, 
       tsk.col_dateclosed            AS dateclosed, 
       tsk.col_depth                 AS depth, 
       tsk.col_description           AS taskdescription, 
       tsk.col_enabled               AS enabled, 
       tsk.col_hoursworked           AS hoursworked, 
       tsk.col_leaf                  AS leaf, 
       tsk.col_name                  AS taskname, 
       tsk.col_owner                 AS taskowner, 
       tsk.col_casetask              AS caseid, 
       tsk.col_required              AS required, 
       tsk.col_resolutiondescription AS resolutiondescription, 
       tsk.col_status                AS taskstatus, 
       dtst.col_code                 AS tasksystemtype, 
       tsk.col_taskorder             AS taskorder, 
       tsk.col_type                  AS tasktype, 
       tsk.col_parentid              AS taskparentid, 
       twi.col_id                    AS twiid, 
       twi.col_activity              AS taskactivity, 
       twi.col_workflow              AS taskworkflow, 
       cwi.col_activity              AS caseactivity, 
       cwi.col_id                    AS cwiid, 
       cwi.col_workflow              AS caseworkflow 
FROM   tbl_task tsk 
       inner join tbl_tw_workitem twi 
               ON tsk.col_tw_workitemtask = twi.col_id 
       inner join tbl_dict_tasksystype dtst 
               ON tsk.col_taskdict_tasksystype = dtst.col_id 
       inner join tbl_case cs 
               ON tsk.col_casetask = cs.col_id 
       inner join tbl_cw_workitem cwi 
               ON cs.col_cw_workitemcase = cwi.col_id 