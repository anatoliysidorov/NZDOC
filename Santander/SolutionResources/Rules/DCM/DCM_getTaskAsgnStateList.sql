select col_activity as Activity, col_id as ID from tbl_dict_taskstate
where col_isassign = 1
and nvl(col_stateconfigtaskstate,0) =
(select nvl(col_stateconfigtasksystype,0) from tbl_dict_tasksystype where col_id =
(select col_taskdict_tasksystype from tbl_task where col_id = :TaskId))