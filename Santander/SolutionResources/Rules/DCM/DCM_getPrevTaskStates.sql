select rownum as Id, f_DCM_getNextActivity(TaskActivity=>ts1.col_activity) as TaskActivity, ts1.col_activity as PrevTaskActivity,
case when ts1.col_activity = 'root_TSK_Status_NEW' then 1
     when ts1.col_activity = 'root_TSK_Status_STARTED' then 2
     when ts1.col_activity = 'root_TSK_Status_ASSIGNED' then 3
     when ts1.col_activity = 'root_TSK_Status_IN_PROCESS' then 4
     when ts1.col_activity = 'root_TSK_Status_RESOLVED' then 5
     when ts1.col_activity = 'root_TSK_Status_CLOSED' then 6
     else 7
end as TaskStatusOrder
from tbl_dict_taskstate ts1
where f_DCM_getNextActivity(TaskActivity=>ts1.col_activity) <> 'NONE'
start with f_DCM_getNextActivity(TaskActivity=>ts1.col_activity) = :StartState
connect by prior ts1.col_activity = f_DCM_getNextActivity(TaskActivity => ts1.col_activity)