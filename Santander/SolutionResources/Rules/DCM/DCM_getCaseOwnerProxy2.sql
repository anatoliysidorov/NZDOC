select s1.CaseId as Id, s1.CaseId as CaseId, s1.WorkbasketId WorkbasketId, s1.WorkbasketCode as WorkbasketCode, s1.WorkbasketTypeCode as WorkbasketTypeCode,
(select name from vw_ppl_activecaseworkersusers where id = col_assignor) as AssignorName,
(select name from vw_ppl_activecaseworkersusers where id = col_assignee) as AssigneeName
from
(select cs.col_id as CaseId, wb.col_id WorkbasketId, wb.col_code as WorkbasketCode, wbt.col_code as WorkbasketTypeCode, cw.col_id as CaseworkerId
from tbl_case cs
inner join tbl_ppl_workbasket wb on cs.col_caseppl_workbasket = wb.col_id
inner join tbl_dict_workbaskettype wbt on wb.col_workbasketworkbaskettype = wbt.col_id
inner join vw_ppl_activecaseworker cw on wb.col_caseworkerworkbasket = cw.col_id
where cs.col_id = :CaseId
and wbt.col_code = 'PERSONAL') s1
left join tbl_proxy pr on s1.CaseworkerId = pr.col_assignor
where sysdate between pr.col_startdate and pr.col_enddate