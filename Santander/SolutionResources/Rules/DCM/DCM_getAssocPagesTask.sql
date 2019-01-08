SELECT ap.*
FROM   vw_dcm_assocpage ap 
       INNER JOIN tbl_dict_tasksystype tt 
               ON ap.TASKSYSTYPE = tt.col_id 
       INNER JOIN tbl_task t 
               ON tt.col_id = t.COL_TASKDICT_TASKSYSTYPE 
WHERE  
	(NVL(:Task_Id, 0) > 0) AND
	(NVL(:Task_Id, 0) = 0 OR (NVL(:Task_Id, 0) > 0 AND t.col_id = :Task_Id )) AND
	(:PAGETYPE_CODE IS NULL OR (:PAGETYPE_CODE IS NOT NULL AND lower(ap.PAGETYPE_CODE) = lower(:PAGETYPE_CODE) ))
ORDER BY ShowOrder ASC