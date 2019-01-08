select ao.col_id as Id, ao.col_id as AccessObjectId, ao.col_code as AccessObjectCode,
ct.col_id as CaseTransitionId, ct.col_code as CaseTransitionCode,
aot.col_id as AccessObjectTypeId, aot.col_code as AccessObjectTypeCode
from tbl_ac_accessobject ao
inner join tbl_dict_casetransition ct on ao.col_accessobjcasetransition = ct.col_id
inner join tbl_ac_accessobjecttype aot on ao.col_accessobjaccessobjtype = aot.col_id
where lower(aot.col_code) = 'case_transition'
order by ao.col_id