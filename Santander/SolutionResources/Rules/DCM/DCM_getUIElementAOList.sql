select ao.col_id as Id, ao.col_id as AccessObjectId, ao.col_code as AccessObjectCode,
ue.col_id as UIElementId, ue.col_code as UIElementCode,
aot.col_id as AccessObjectTypeId, aot.col_code as AccessObjectTypeCode
from tbl_ac_accessobject ao
inner join tbl_fom_uielement ue on ao.col_accessobjectuielement = ue.col_id
inner join tbl_ac_accessobjecttype aot on ao.col_accessobjaccessobjtype = aot.col_id
where lower(aot.col_code) = 'ui_element'
order by ao.col_id