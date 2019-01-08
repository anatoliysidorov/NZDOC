with spos as
(select col_id as PermissionId, col_defaultACL as DefaultACL, col_orderACL as OrderACL, col_position-1 as position from tbl_ac_permission where col_id = :PermissionId)
select s11.CaseworkerId as Id, s11.CaseworkerId as CaseworkerId, s11.CaseworkerUserId as CaseworkerUserId, s11.CaseworkerCode, s11.CaseworkerName as CaseworkerName,
s11.CaseworkerAccessSubjectId as CaseworkerAccessSubjectId, s11.CaseworkerAccessSubjectCode as CaseworkerAccessSubjectCode, s11.CaseworkerAccessSubjectName as CaseworkerAccessSubjectName,
nvl(s9.PermissionId, :PermissionId) as PermissionId, nvl(s9.AccessObjectId, :AccessObjectId) as AccessObjectId,
case when nvl(s9.AllowFlag,0) = 0 and nvl(s9.DenyFlag,0) = 0 then (select case when DefaultAcl = 1 then 1 else 0 end from spos)
when s9.AllowFlag = 1 and s9.DenyFlag = 0 then 1
when s9.AllowFlag = 0 and s9.DenyFlag = 1 then 0
when (select OrderACL from spos) = 1 and s9.AllowFlag = 1 and s9.DenyFlag = 1 then 1
when (select OrderACL from spos) = 2 and s9.AllowFlag = 1 and s9.DenyFlag = 1 then 0
end as Allowed
from
(select col_id as PermissionId, col_defaultACL as DefaultACL, col_orderACL as OrderACL from tbl_ac_permission where col_id = :PermissionId) s10
inner join
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
where cw.col_id = :CaseworkerId
union all
select ep.id as CaseworkerId, ep.userid as CaseworkerUserId, ep.epcode as CaseworkerCode, ep.epname as CaseworkerName, ep.epaccesssubjectid as CaseworkerAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName
from vw_ppl_externalpartiesusers ep
inner join tbl_ac_accesssubject cwas on ep.epaccesssubjectid = cwas.col_id and cwas.col_type = 'EXTERNALPARTY'
where ep.id = :CaseworkerId
) s11 on 1 = 1
left join
(select s8.CaseworkerId as CaseworkerId, s8.CaseworkerUserId as CaseworkeruserId, s8.CaseworkerCode as CaseworkerCode, s8.CaseworkerName as CaseworkerName,
s8.CaseworkerAccessSubjectId as CaseworkerAccessSubjectId, s8.CaseworkerAccessSubjectCode as CaseworkerAccessSubjectCode, s8.CaseworkerAccessSubjectName as CaseworkerAccessSubjectName,
s8.PermissionId as PermissionId, s8.AccessObjectId as AccessObjectId,
case when bitoragg(bitand(s8.ACLEntry, power(2,(select position from spos)))) > 0 then 1 else 0 end as AllowFlag,
case when bitoragg(bitand(f_UTIL_BitNot(s8.ACLEntry), power(2,(select position from spos)))) > 0 then 1 else 0 end as DenyFlag
from
(
select s4.CaseworkerId, s4.CaseworkerUserId, s4.CaseworkerCode, s4.CaseworkerName, s4.CaseworkerAccessSubjectId, s4.CaseworkerAccessSubjectCode, s4.CaseworkerAccessSubjectName, 'CASEWORKER' as PeopleType,
s6.PermissionId as PermissionId, s6.AccessObjectId as AccessObjectId, s4.ACLId as ACLId, s6.ACLEntry as ACLEntry
from
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName,
acl.col_id as ACLId, acl.col_aclaccessobject as AccessObjectId
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
inner join tbl_ac_acl acl on cwas.col_id = acl.col_aclaccesssubject and nvl(acl.col_type, 0) = 0
) s4
left join
(select cas.col_id as AccessSubjectId, acl.col_aclpermission as PermissionId, oa.col_id as AccessObjectId,
acl.col_id as ACLId,
(case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :CaseId, ProcessorName => acl.col_processorcode)
      when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(ProcessorName => acl.col_processorcode, TaskId => :TaskId) else acl.col_aclentry end) as ACLEntry
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'CASEWORKER'
and nvl(acl.col_type, 0) = 0) s6 on s4.CaseworkerAccessSubjectId = s6.AccessSubjectId and s4.ACLId = s6.ACLId and s4.AccessObjectId = s6.AccessObjectId
union all
select s4.CaseworkerId, s4.CaseworkerUserId, s4.CaseworkerCode, s4.CaseworkerName, s4.CaseworkerAccessSubjectId, s4.CaseworkerAccessSubjectCode, s4.CaseworkerAccessSubjectName, 'EXTERNALPARTY' as PeopleType,
s6.PermissionId as PermissionId, s6.AccessObjectId as AccessObjectId,  s4.ACLId as ACLId, s6.ACLEntry as ACLEntry
from
(select ep.col_id as CaseworkerId, ep.col_userid as CaseworkerUserId, ep.col_code as CaseworkerCode, ep.col_name as CaseworkerName, ep.col_extpartyaccesssubject as CaseworkerAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName,
acl.col_id as ACLId, acl.col_aclaccessobject as AccessObjectId
from tbl_externalparty ep
inner join tbl_ac_accesssubject cwas on ep.col_extpartyaccesssubject = cwas.col_id and cwas.col_type = 'EXTERNALPARTY'
inner join tbl_ac_acl acl on cwas.col_id = acl.col_aclaccesssubject and nvl(acl.col_type, 0) = 0
) s4
left join
(select cas.col_id as AccessSubjectId, acl.col_aclpermission as PermissionId, oa.col_id as AccessObjectId,
acl.col_id as ACLId,
(case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :CaseId, ProcessorName => acl.col_processorcode)
      when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(ProcessorName => acl.col_processorcode, TaskId => :TaskId) else acl.col_aclentry end) as ACLEntry
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'EXTERNALPARTY'
and nvl(acl.col_type, 0) = 0) s6 on s4.CaseworkerAccessSubjectId = s6.AccessSubjectId and s4.ACLId = s6.ACLId and s4.AccessObjectId = s6.AccessObjectId
union all
select s4.CaseworkerId, s4.CaseworkerUserId, s4.CaseworkerCode, s4.CaseworkerName, s4.CaseworkerAccessSubjectId, s4.CaseworkerAccessSubjectCode, s4.CaseworkerAccessSubjectName, 'BUSINESSROLE' as PeopleType,
s6.PermissionId as PermissionId, s6.AccessObjectId as AccessObjectId, s4.ACLId as ACLId, s6.ACLEntry as ACLEntry
from
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
br.col_id as BusinessroleId, br.col_code as BusinessroleCode, br.col_name as BusinessroleName, br.col_businessroleaccesssubject as BusinessroleAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName,
bras.col_id as BusinessroleAccessSubjectId, bras.col_code as BusinessroleAccessSubjectCode, bras.col_name as BusinessroleAccessSubjectName,
acl.col_id as ACLId, acl.col_aclaccessobject as AccessObjectId
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
inner join tbl_caseworkerbusinessrole cwbr on cw.col_id = cwbr.col_br_ppl_caseworker
inner join tbl_ppl_businessrole br on cwbr.col_tbl_ppl_businessrole = br.col_id
inner join tbl_ac_accesssubject bras on br.col_businessroleaccesssubject = bras.col_id and bras.col_type = 'BUSINESSROLE'
inner join tbl_ac_acl acl on bras.col_id = acl.col_aclaccesssubject and nvl(acl.col_type, 0) = 0) s4
left join
(select cas.col_id as AccessSubjectId, acl.col_aclpermission as PermissionId, oa.col_id as AccessObjectId,
acl.col_id as ACLId,
(case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :CaseId, ProcessorName => acl.col_processorcode)
      when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(ProcessorName => acl.col_processorcode, TaskId => :TaskId) else acl.col_aclentry end) as ACLEntry
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'BUSINESSROLE'
and nvl(acl.col_type, 0) = 0) s6 on s4.BusinessroleAccessSubjectId = s6.AccessSubjectId and s4.ACLId = s6.ACLId and s4.AccessObjectId = s6.AccessObjectId
union all
select s4.CaseworkerId, s4.CaseworkerUserId, s4.CaseworkerCode, s4.CaseworkerName, s4.CaseworkerAccessSubjectId, s4.CaseworkerAccessSubjectCode, s4.CaseworkerAccessSubjectName, 'TEAM' as PeopleType,
s6.PermissionId as PermissionId, s6.AccessObjectId as AccessObjectId, s4.ACLId as ACLId, s6.ACLEntry as ACLEntry
from
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
tm.col_id as TeamId, tm.col_code as TeamCode, tm.col_name as TeamName, tm.col_teamaccesssubject as TeamAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName,
tmas.col_id as TeamAccessSubjectId, tmas.col_code as TeamAccessSubjectCode, tmas.col_name as TeamAccessSubjectName,
acl.col_id as ACLId, acl.col_aclaccessobject as AccessObjectId
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
inner join tbl_caseworkerteam cwt on cw.col_id = cwt.col_tm_ppl_caseworker
inner join tbl_ppl_team tm on cwt.col_tbl_ppl_team = tm.col_id
inner join tbl_ac_accesssubject tmas on tm.col_teamaccesssubject = tmas.col_id and tmas.col_type = 'TEAM'
inner join tbl_ac_acl acl on tmas.col_id = acl.col_aclaccesssubject and nvl(acl.col_type, 0) = 0) s4
left join
(select cas.col_id as AccessSubjectId, acl.col_aclpermission as PermissionId, oa.col_id as AccessObjectId,
acl.col_id as ACLId,
(case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :CaseId, ProcessorName => acl.col_processorcode)
      when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc( ProcessorName => acl.col_processorcode, TaskId => :TaskId) else acl.col_aclentry end) as ACLEntry
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'TEAM'
and nvl(acl.col_type, 0) = 0) s6 on s4.TeamAccessSubjectId = s6.AccessSubjectId and s4.ACLId = s6.ACLId and s4.AccessObjectId = s6.AccessObjectId
union all
select s4.CaseworkerId, s4.CaseworkerUserId, s4.CaseworkerCode, s4.CaseworkerName, s4.CaseworkerAccessSubjectId, s4.CaseworkerAccessSubjectCode, s4.CaseworkerAccessSubjectName, 'SKILL' as PeopleType,
s6.PermissionId as PermissionId, s6.AccessObjectId as AccessObjectId, s4.ACLId as ACLId, s6.ACLEntry as ACLEntry
from
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
sl.col_id as SkillId, sl.col_code as SkillCode, sl.col_name as SkillName, sl.col_skillaccesssubject as SkillAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName,
slas.col_id as SkillAccessSubjectId, slas.col_code as SkillAccessSubjectCode, slas.col_name as SkillAccessSubjectName,
acl.col_id as ACLId, acl.col_aclaccessobject as AccessObjectId
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
inner join tbl_caseworkerskill cws on cw.col_id = cws.col_sk_ppl_caseworker
inner join tbl_ppl_skill sl on cws.col_tbl_ppl_skill = sl.col_id
inner join tbl_ac_accesssubject slas on sl.col_skillaccesssubject = slas.col_id and slas.col_type = 'SKILL'
inner join tbl_ac_acl acl on slas.col_id = acl.col_aclaccesssubject and nvl(acl.col_type, 0) = 0) s4
left join
(select cas.col_id as AccessSubjectId, acl.col_aclpermission as PermissionId, oa.col_id as AccessObjectId,
acl.col_id as ACLId,
(case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :CaseId, ProcessorName => acl.col_processorcode)
      when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(ProcessorName => acl.col_processorcode, TaskId => :TaskId) else acl.col_aclentry end) as ACLEntry
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'SKILL'
and nvl(acl.col_type, 0) = 0) s6 on s4.SkillAccessSubjectId = s6.AccessSubjectId and s4.ACLId = s6.ACLId and s4.AccessObjectId = s6.AccessObjectId
) s8
where s8.CaseworkerId = :CaseworkerId and s8.AccessObjectId = :AccessObjectId
group by s8.CaseworkerId, s8.CaseworkerUserId, s8.CaseworkerCode, s8.CaseworkerName, s8.CaseworkerAccessSubjectId, s8.CaseworkerAccessSubjectCode, s8.CaseworkerAccessSubjectName,
s8.PermissionId, s8.AccessObjectId) s9 on s9.PermissionId = s10.PermissionId