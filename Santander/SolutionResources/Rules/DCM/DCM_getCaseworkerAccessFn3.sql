with s11 as (select col_defaultACL as DefaultACL, col_orderACL as OrderACL from tbl_ac_permission where col_id = :p_PermissionId)
select s10.CaseworkerId as Id, s10.CaseworkerId as CaseworkerId, s10.CaseworkerUserId as CaseworkerUserId, s10.CaseworkerCode as CaseworkerCode, s10.CaseworkerName as CaseworkerName,
s10.CaseworkerAccessSubjectId as CaseworkerAccessSubjectId, s10.CaseworkerAccessSubjectCode, s10.CaseworkerAccessSubjectName,
nvl(s8.AccessObjectId, :p_AccessObjectId) as AccessObjectId, s9.PermissionId as PermissionId,
case when nvl(s8.AllowFlag,0) = 0 and nvl(s8.DenyFlag,0) = 0 then (select case when DefaultACL = 1 then 1 else 0 end from s11)
when s8.AllowFlag = 1 and s8.DenyFlag = 0 then 1
when s8.AllowFlag = 0 and s8.DenyFlag = 1 then 0
when (select OrderACL from s11) = 1 and s8.AllowFlag = 1 and s8.DenyFlag = 1 then 1
when (select OrderACL from s11) = 2 and s8.AllowFlag = 1 and s8.DenyFlag = 1 then 0
end as Allowed
from
(select col_id as PermissionId, col_defaultACL as DefaultACL, col_orderACL as OrderACL from tbl_ac_permission where col_id = :p_PermissionId) s9
inner join
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
) s10 on s10.CaseworkerId = :p_CaseworkerId
left join
(select s7.CaseworkerId, s7.CaseworkerUserId, s7.CaseworkerCode, s7.CaseworkerName, s7.CaseworkerAccessSubjectId, s7.CaseworkerAccessSubjectCode, s7.CaseworkerAccessSubjectName,
s7.AccessObjectId, s7.PermissionId as PermissionId,
case when sum(s7.AllowFlag) > 0 then 1 else 0 end as AllowFlag, case when sum(s7.DenyFlag) > 0 then 1 else 0 end as DenyFlag
from
(
select s4.CaseworkerId, s4.CaseworkerUserId, s4.CaseworkerCode, s4.CaseworkerName, s4.CaseworkerAccessSubjectId, s4.CaseworkerAccessSubjectCode, s4.CaseworkerAccessSubjectName,
s6.AccessObjectId, s6.PermissionId as PermissionId,
s6.AllowFlag as AllowFlag, s6.DenyFlag as DenyFlag
from
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
) s4
left join
(select s5.AccessSubjectId as AccessSubjectId, s5.AccessObjectId as AccessObjectId, s5.PermissionId as PermissionId, s5.AllowFlag as AllowFlag, s5.DenyFlag as DenyFlag
from
(select AccessSubjectId as AccessSubjectId, AccessObjectId as AccessObjectId, PermissionId as PermissionId,
case when AllowFlag = 1 then 1 else 0 end as AllowFlag, case when DenyFlag = 1 then 1 else 0 end as DenyFlag
from
(select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectId, acl.col_aclpermission as PermissionId,
case when count(*) > 0 then 1 else 0 end as AllowFlag, null as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'CASEWORKER' and acl.col_aclpermission = :p_PermissionId
and (case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :p_CaseId, ProcessorName => acl.col_processorcode)
          when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(TaskId => :p_TaskId, ProcessorName => acl.col_processorcode)
          else acl.col_type end) = 1
group by cas.col_id, oa.col_id, acl.col_aclpermission)
union all
(select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectId, acl.col_aclpermission as PermissionId,
null as AllowFlag, case when count(*) > 0 then 1 else 0 end as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'CASEWORKER' and acl.col_aclpermission = :p_PermissionId
and (case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :p_CaseId, ProcessorName => acl.col_processorcode)
          when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(TaskId => :p_TaskId, ProcessorName => acl.col_processorcode)
          else acl.col_type end) = 2
group by cas.col_id, oa.col_id, acl.col_aclpermission)) s5) s6 on s4.CaseworkerAccessSubjectId = s6.AccessSubjectId
union all
select s4.CaseworkerId, s4.CaseworkerUserId, s4.CaseworkerCode, s4.CaseworkerName, s4.CaseworkerAccessSubjectId, s4.CaseworkerAccessSubjectCode, s4.CaseworkerAccessSubjectName,
s6.AccessObjectId, s6.PermissionId as PermissionId,
s6.AllowFlag as AllowFlag, s6.DenyFlag as DenyFlag
from
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
br.col_id as BusinessroleId, br.col_code as BusinessroleCode, br.col_name as BusinessroleName, br.col_businessroleaccesssubject as BusinessroleAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName,
bras.col_id as BusinessroleAccessSubjectId, bras.col_code as BusinessroleAccessSubjectCode, bras.col_name as BusinessroleAccessSubjectName
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
inner join tbl_caseworkerbusinessrole cwbr on cw.col_id = cwbr.col_br_ppl_caseworker
inner join tbl_ppl_businessrole br on cwbr.col_tbl_ppl_businessrole = br.col_id
inner join tbl_ac_accesssubject bras on br.col_businessroleaccesssubject = bras.col_id and bras.col_type = 'BUSINESSROLE') s4
left join
(select s5.AccessSubjectId as AccessSubjectId, s5.AccessObjectId as AccessObjectId, s5.PermissionId as PermissionId,
s5.AllowFlag as AllowFlag, s5.DenyFlag as DenyFlag
from
(select AccessSubjectId as AccessSubjectId, AccessObjectId as AccessObjectId, PermissionId as PermissionId,
case when AllowFlag = 1 then 1 else 0 end as AllowFlag, case when DenyFlag = 1 then 1 else 0 end as DenyFlag
from
(select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectId, acl.col_aclpermission as PermissionId,
case when count(*) > 0 then 1 else 0 end as AllowFlag, null as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'BUSINESSROLE' and acl.col_aclpermission = :p_PermissionId
and (case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :p_CaseId, ProcessorName => acl.col_processorcode)
          when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(TaskId => :p_TaskId, ProcessorName => acl.col_processorcode) else acl.col_type end) = 1
group by cas.col_id, oa.col_id, acl.col_aclpermission)
union all
(select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectId, acl.col_aclpermission as PermissionId,
null as AllowFlag, case when count(*) > 0 then 1 else 0 end as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'BUSINESSROLE' and acl.col_aclpermission = :p_PermissionId
and (case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :p_CaseId, ProcessorName => acl.col_processorcode)
          when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(TaskId => :p_TaskId, ProcessorName => acl.col_processorcode) else acl.col_type end) = 2
group by cas.col_id, oa.col_id, acl.col_aclpermission)) s5) s6 on s4.BusinessRoleAccessSubjectId = s6.AccessSubjectId
union all
select s4.CaseworkerId, s4.CaseworkerUserId, s4.CaseworkerCode, s4.CaseworkerName, s4.CaseworkerAccessSubjectId, s4.CaseworkerAccessSubjectCode, s4.CaseworkerAccessSubjectName,
s6.AccessObjectId, s6.PermissionId as PermissionId,
s6.AllowFlag as AllowFlag, s6.DenyFlag as DenyFlag
from
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
tm.col_id as TeamId, tm.col_code as TeamCode, tm.col_name as TeamName, tm.col_teamaccesssubject as TeamAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName,
tmas.col_id as TeamAccessSubjectId, tmas.col_code as TeamAccessSubjectCode, tmas.col_name as TeamAccessSubjectName
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
inner join tbl_caseworkerteam cwt on cw.col_id = cwt.col_tm_ppl_caseworker
inner join tbl_ppl_team tm on cwt.col_tbl_ppl_team = tm.col_id
inner join tbl_ac_accesssubject tmas on tm.col_teamaccesssubject = tmas.col_id and tmas.col_type = 'TEAM') s4
left join
(select s5.AccessSubjectId as AccessSubjectId, s5.AccessObjectId as AccessObjectId, s5.PermissionId as PermissionId, s5.AllowFlag as AllowFlag, s5.DenyFlag as DenyFlag
from
(select AccessSubjectId as AccessSubjectId, AccessObjectId as AccessObjectId, PermissionId as PermissionId,
case when AllowFlag = 1 then 1 else 0 end as AllowFlag, case when DenyFlag = 1 then 1 else 0 end as DenyFlag
from
(select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectId, acl.col_aclpermission as PermissionId,
case when count(*) > 0 then 1 else 0 end as AllowFlag, null as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'TEAM' and acl.col_aclpermission = :p_PermissionId
and (case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :p_CaseId, ProcessorName => acl.col_processorcode)
          when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(TaskId => :p_TaskId, ProcessorName => acl.col_processorcode) else acl.col_type end) = 1
group by cas.col_id, oa.col_id, acl.col_aclpermission)
union all
(select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectId, acl.col_aclpermission as PermissionId,
null as AllowFlag, case when count(*) > 0 then 1 else 0 end as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'TEAM' and acl.col_aclpermission = :p_PermissionId
and (case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :p_CaseId, ProcessorName => acl.col_processorcode)
          when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(TaskId => :p_TaskId, ProcessorName => acl.col_processorcode) else acl.col_type end) = 2
group by cas.col_id, oa.col_id, acl.col_aclpermission)) s5) s6 on s4.TeamAccessSubjectId = s6.AccessSubjectId
union all
select s4.CaseworkerId, s4.CaseworkerUserId, s4.CaseworkerCode, s4.CaseworkerName, s4.CaseworkerAccessSubjectId, s4.CaseworkerAccessSubjectCode, s4.CaseworkerAccessSubjectName,
s6.AccessObjectId, s6.PermissionId as PermissionId,
s6.AllowFlag as AllowFlag, s6.DenyFlag as DenyFlag
from
(select cw.col_id as CaseworkerId, cw.col_userid as CaseworkerUserId, cw.col_code as CaseworkerCode, cw.col_name as CaseworkerName, cw.col_caseworkeraccesssubject as CaseworkerAccessSubject,
sl.col_id as SkillId, sl.col_code as SkillCode, sl.col_name as SkillName, sl.col_skillaccesssubject as SkillAccessSubject,
cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName,
slas.col_id as SkillAccessSubjectId, slas.col_code as SkillAccessSubjectCode, slas.col_name as SkillAccessSubjectName
from vw_ppl_activecaseworker cw
inner join tbl_ac_accesssubject cwas on cw.col_caseworkeraccesssubject = cwas.col_id and cwas.col_type = 'CASEWORKER'
inner join tbl_caseworkerskill cws on cw.col_id = cws.col_sk_ppl_caseworker
inner join tbl_ppl_skill sl on cws.col_tbl_ppl_skill = sl.col_id
inner join tbl_ac_accesssubject slas on sl.col_skillaccesssubject = slas.col_id and slas.col_type = 'SKILL') s4
left join
(select s5.AccessSubjectId as AccessSubjectId, s5.AccessObjectId as AccessObjectId, s5.PermissionId as PermissionId,
s5.AllowFlag as AllowFlag, s5.DenyFlag as DenyFlag
from
(select AccessSubjectId as AccessSubjectId, AccessObjectId as AccessObjectId, PermissionId as PermissionId,
case when AllowFlag = 1 then 1 else 0 end as AllowFlag, case when DenyFlag = 1 then 1 else 0 end as DenyFlag
from
(select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectId, acl.col_aclpermission as PermissionId,
case when count(*) > 0 then 1 else 0 end as AllowFlag, null as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'SKILL' and acl.col_aclpermission = :p_PermissionId
and (case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :p_CaseId, ProcessorName => acl.col_processorcode)
          when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(TaskId => :p_TaskId, ProcessorName => acl.col_processorcode) else acl.col_type end) = 1
group by cas.col_id, oa.col_id, acl.col_aclpermission)
union all
(select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectId, acl.col_aclpermission as PermissionId,
null as AllowFlag, case when count(*) > 0 then 1 else 0 end as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'SKILL' and acl.col_aclpermission = :p_PermissionId
and (case when aot.col_code = 'CASE_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeaclcaseproc(CaseId => :p_CaseId, ProcessorName => acl.col_processorcode)
          when aot.col_code = 'TASK_BUSINESS_OBJECT' and acl.col_processorcode is not null then f_dcm_invokeacltaskproc(TaskId => :p_TaskId, ProcessorName => acl.col_processorcode) else acl.col_type end) = 2
group by cas.col_id, oa.col_id, acl.col_aclpermission)) s5) s6 on s4.SkillAccessSubjectId = s6.AccessSubjectId) s7
where s7.CaseworkerId = :p_CaseworkerId
and s7.AccessObjectId = :p_AccessObjectId
group by s7.CaseworkerId, s7.CaseworkerUserId, s7.CaseworkerCode, s7.CaseworkerName, s7.CaseworkerAccessSubjectId, s7.CaseworkerAccessSubjectCode, s7.CaseworkerAccessSubjectName,
s7.AccessObjectId, s7.PermissionId) s8 on s8.PermissionId = s9.PermissionId
