select ao.col_id as Id, ao.col_id as AccessObjectId, aocs.col_id as CaseStateId
from tbl_ac_accessobject ao
inner join tbl_dict_casestate aocs on ao.col_accessobjectcasestate = aocs.col_id