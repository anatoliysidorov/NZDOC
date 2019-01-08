SELECT ao.col_id    AS Id, 
       ao.col_id    AS AccessObjectId, 
       ao.col_code  AS AccessObjectCode, 
       cs.col_id    AS CaseStateId, 
       cs.col_code  AS CaseStateCode, 
       aot.col_id   AS AccessObjectTypeId, 
       aot.col_code AS AccessObjectTypeCode 
FROM   tbl_ac_accessobject ao 
       inner join tbl_dict_casestate cs 
               ON ao.col_accessobjectcasestate = cs.col_id 
       inner join tbl_ac_accessobjecttype aot 
               ON ao.col_accessobjaccessobjtype = aot.col_id 
WHERE  Lower(aot.col_code) = 'case_state' 
ORDER  BY ao.col_id 