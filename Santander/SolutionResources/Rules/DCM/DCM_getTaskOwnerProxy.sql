select tsk.col_id as Id, tsk.col_id as TaskId, wb.col_id WorkbasketId, wb.col_code as WorkbasketCode, wbt.col_code as WorkbasketTypeCode,
pal.Name as AssignorName,
s1.AssigneeName as AssigneeName
from tbl_task tsk
inner join tbl_ppl_workbasket wb on tsk.col_taskppl_workbasket = wb.col_id
inner join tbl_dict_workbaskettype wbt on wb.col_workbasketworkbaskettype = wbt.col_id
inner join vw_ppl_activecaseworker cw on wb.col_caseworkerworkbasket = cw.col_id
inner join table(f_DCM_getProxyAssignorList()) pal on cw.col_id = pal.id
left join
(select col_assignor as Id, col_assignor as CaseworkerId, (select accode from vw_ppl_activecaseworkersusers where id = col_assignor) as AccessSubject,
(select name from vw_ppl_activecaseworkersusers where id = col_assignor) as AssignorName,
col_assignee as AssigneeId, (select accode from vw_ppl_activecaseworkersusers where id = col_assignee) as AssigneeAccessSubject,
(select name from vw_ppl_activecaseworkersusers where id = col_assignee) as AssigneeName
from tbl_proxy
where col_assignee = (select id from vw_ppl_activecaseworkersusers where accode = sys_context('CLIENTCONTEXT', 'AccessSubject'))
and sysdate between col_startdate and col_enddate) s1 on cw.col_id = s1.Id
where wbt.col_code = 'PERSONAL'
and tsk.col_id = :TaskId