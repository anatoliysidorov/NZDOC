select ao.col_id as Id, ao.col_id as AccessObjectId, ao.col_code as AccessObjectCode,
tst.col_id as TaskTypeId, tst.col_code as TaskTypeCode,
aot.col_id as AccessObjectTypeId, aot.col_code as AccessObjectTypeCode
from tbl_ac_accessobject ao
inner join tbl_dict_tasksystype tst on ao.col_accessobjecttasksystype = tst.col_id
inner join tbl_ac_accessobjecttype aot on ao.col_accessobjaccessobjtype = aot.col_id
where lower(aot.col_code) = 'task_type'
order by ao.col_id