select s10.AccessSubjectId as Id, s10.AccessSubjectId as AccessSubjectId, s10.AccessSubjectCode as AccessSubjectCode,
s10.AccessSubjectName as AccessSubjectName,
nvl(s8.AccessObjectId, :p_AccessObjectId) as AccessObjectId,
(select col_code from tbl_ac_accessobject where col_id = nvl(s8.AccessObjectId, :p_AccessObjectId)) as AccessObjectCode, s9.PermissionId as PermissionId, s9.PermissionCode as PermissionCode,
case when nvl(s8.AllowFlag,0) = 0 and nvl(s8.DenyFlag,0) = 0 then case when s9.DefaultAcl = 1 then 1 else 0 end
when s8.AllowFlag = 1 and s8.DenyFlag = 0 then 1
when s8.AllowFlag = 0 and s8.DenyFlag = 1 then 0
when s9.OrderACL = 1 and s8.AllowFlag = 1 and s8.DenyFlag = 1 then 1
when s9.OrderACL = 2 and s8.AllowFlag = 1 and s8.DenyFlag = 1 then 0
end as Allowed
from
(select col_id as PermissionId, col_code as PermissionCode, col_defaultACL as DefaultACL, col_orderACL as OrderACL from tbl_ac_permission where col_id = :p_PermissionId) s9
inner join
(select cwas.col_id as AccessSubjectId, cwas.col_code as AccessSubjectCode, cwas.col_name as AccessSubjectName
from tbl_ac_accesssubject cwas
where cwas.col_id = :p_AccessSubjectId and cwas.col_type = 'CUSTOM'
) s10 on 1 = 1
left join
(select s7.AccessObjectId as AccessObjectId, s7.PermissionId as PermissionId,
case when sum(s7.AllowFlag) > 0 then 1 else 0 end as AllowFlag, case when sum(s7.DenyFlag) > 0 then 1 else 0 end as DenyFlag
from
(
select s6.AccessSubjectId as AccessSubjectId, s6.AccessObjectId as AccessObjectId, s6.PermissionId as PermissionId, s6.AllowFlag as AllowFlag, s6.DenyFlag as DenyFlag
from
(select cwas.col_id as CaseworkerAccessSubjectId, cwas.col_code as CaseworkerAccessSubjectCode, cwas.col_name as CaseworkerAccessSubjectName
from tbl_ac_accesssubject cwas
where cwas.col_type = 'CUSTOM'
) s4
left join
(select s5.AccessSubjectId as AccessSubjectId, s5.AccessObjectId as AccessObjectId, s5.PermissionId as PermissionId, s5.AllowFlag as AllowFlag, s5.DenyFlag as DenyFlag
from
(select AccessSubjectId as AccessSubjectId, AccessObjectId as AccessObjectId, PermissionId as PermissionId,
case when AllowFlag = 1 then 1 else 0 end as AllowFlag, case when DenyFlag = 1 then 1 else 0 end as DenyFlag
from
((select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectid, acl.col_aclpermission as PermissionId,
case when count(*) > 0 then 1 else 0 end as AllowFlag, null as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'CUSTOM'
and acl.col_type = 1
group by cas.col_id, oa.col_id, acl.col_aclpermission)
union all
(select cas.col_id as AccessSubjectId, oa.col_id as AccessObjectid, acl.col_aclpermission as PermissionId,
null as AllowFlag, case when count(*) > 0 then 1 else 0 end as DenyFlag
from tbl_ac_accesssubject cas
left join tbl_ac_acl acl on cas.col_id = acl.col_aclaccesssubject
left join tbl_ac_accessobject oa on acl.col_aclaccessobject = oa.col_id
left join tbl_ac_accessobjecttype aot on oa.col_accessobjaccessobjtype = aot.col_id
where cas.col_type = 'CUSTOM'
and acl.col_type = 2
group by cas.col_id, oa.col_id, acl.col_aclpermission))) s5) s6 on s4.CaseworkerAccessSubjectId = s6.AccessSubjectId
) s7
where s7.AccessObjectid = :p_AccessObjectId
and s7.AccessSubjectId = :p_AccessSubjectId
group by s7.AccessObjectId, s7.PermissionId
) s8 on s8.PermissionId = s9.PermissionId
order by s8.PermissionId