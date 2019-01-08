select rownum as Id, 
ts1.col_activity as TaskActivity,
f_DCM_getNextActivity2(TaskActivity => ts1.col_activity) as NextTaskActivity,
case when ts1.col_activity = 'root_TSK_Status_NEW' then 1
     when ts1.col_activity = 'root_TSK_Status_STARTED' then 2
     when ts1.col_activity = 'root_TSK_Status_ASSIGNED' then 3
     when ts1.col_activity = 'root_TSK_Status_IN_PROCESS' then 4
     when ts1.col_activity = 'root_TSK_Status_RESOLVED' then 5
     when ts1.col_activity = 'root_TSK_Status_CLOSED' then 6
     else 7
end as TaskStatusOrder
from tbl_dict_taskstate ts1
where f_DCM_getNextActivity2(TaskActivity=>ts1.col_activity) <> 'NONE'
start with ts1.col_activity = :StartState
connect by prior f_DCM_getNextActivity2(TaskActivity => ts1.col_activity) = ts1.col_activity