select col_assignor as Id, col_assignor as CaseworkerId, (select accode from vw_ppl_activecaseworkersusers where id = col_assignor) as AccessSubject,
(select name from vw_ppl_activecaseworkersusers where id = col_assignor) as Name,
col_startdate as StartDate, col_EndDate as EndDate
from tbl_proxy
where col_assignee = (select id from vw_ppl_activecaseworkersusers where accode = sys_context('CLIENTCONTEXT', 'AccessSubject'))
and sysdate between col_startdate and col_enddate
union
select id as Id, id as CaseworkerId, cast(sys_context('CLIENTCONTEXT', 'AccessSubject') as nvarchar2(255)) as AccessSubject, name as Name,
null as StartDate, null as EndDate
from vw_ppl_activecaseworkersusers
where accode = sys_context('CLIENTCONTEXT', 'AccessSubject')