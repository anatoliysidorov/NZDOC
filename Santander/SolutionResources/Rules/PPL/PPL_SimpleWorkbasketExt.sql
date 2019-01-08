select WBId as ID, WBId as COL_ID, WBName as NAME, WBCode as CODE, WBTId as WorkBasketType_Id, WBTName as WorkBasketType_Name, WBTCode as WorkBasketType_Code,
       WBIsDefault as IsDefault, WBIsPrivate as IsPrivate, AccessSubjectCode as ACCESSSUBJECTCODE, EmailAddress as EmailAddress,
       IsDeleted as ISDELETED, CWId as Caseworker_Id, ExternalPartyId as ExternalParty_Id, TeamId as Team_Id, SkillId as Skill_Id, BusinessRoleId as BusinessRole_Id,
       CalcName as CalcName, CalcType as CalcType, CalcTypeCode as CalcTypeCode
from
(
select wb.col_id as WBId, wb.col_name as WBName, wb.col_code as WBCode, wbt.col_id as WBTId, wbt.col_name as WBTName, wbt.col_code as WBTCode,
          NVL(wb.col_isdefault,0) as WBIsDefault, NVL(wb.col_isprivate,0) as WBIsPrivate, u.accesssubjectcode as AccessSubjectCode, u.email as EmailAddress,
          cw.col_isdeleted as IsDeleted, cw.col_id as CWId, null as ExternalPartyId, null as TeamId, null as SkillId, null as BusinessRoleId,
          u.name as CalcName, 'Case Worker' as CalcType, 'CASEWORKER' as CalcTypeCode
from tbl_ppl_workbasket wb
left join tbl_dict_workbaskettype wbt on wbt.col_id = wb.col_workbasketworkbaskettype
inner join tbl_ppl_caseworker cw on cw.col_id = wb.col_caseworkerworkbasket
inner join vw_users u on u.userid = cw.col_userid
union all
select wb.col_id as WBId, wb.col_name as WBName, wb.col_code as WBCode, wbt.col_id as WBTId, wbt.col_name as WBTName, wbt.col_code as WBTCode,
          NVL(wb.col_isdefault,0) as WBIsDefault, NVL(wb.col_isprivate,0) as WBIsPrivate, null as AccessSubjectCode, null as EmailAddress,
          ep.col_isdeleted as IsDeleted, null as CWId, ep.col_id as ExternalPartyId, null as TeamId, null as SkillId, null as BusinessRoleId,
          ep.col_name as CalcName, 'External Party' as CalcType, 'EXTERNALPARTY' as CalcTypeCode
from tbl_ppl_workbasket wb
left join tbl_dict_workbaskettype wbt on wbt.col_id = wb.col_workbasketworkbaskettype
inner join tbl_externalparty ep on ep.col_id = wb.col_workbasketexternalparty
union all
select wb.col_id as WBId, wb.col_name as WBName, wb.col_code as WBCode, wbt.col_id as WBTId, wbt.col_name as WBTName, wbt.col_code as WBTCode,
          NVL(wb.col_isdefault,0) as WBIsDefault, NVL(wb.col_isprivate,0) as WBIsPrivate, null as AccessSubjectCode, null as EmailAddress,
          null as IsDeleted, null as CWId, null as ExternalPartyId, t.col_id as TeamId, null as SkillId, null as BusinessRoleId,
          t.col_name as CalcName, 'Team' as CalcType, 'TEAM' as CalcTypeCode
from tbl_ppl_workbasket wb
left join tbl_dict_workbaskettype wbt on wbt.col_id = wb.col_workbasketworkbaskettype
inner join tbl_ppl_team t on t.col_id = wb.col_workbasketteam
union all
select wb.col_id as WBId, wb.col_name as WBName, wb.col_code as WBCode, wbt.col_id as WBTId, wbt.col_name as WBTName, wbt.col_code as WBTCode,
          NVL(wb.col_isdefault,0) as WBIsDefault, NVL(wb.col_isprivate,0) as WBIsPrivate, null as AccessSubjectCode, null as EmailAddress,
          null as IsDeleted, null as CWId, null as ExternalPartyId, null as TeamId, s.col_id as SkillId, null as BusinessRoleId,
          s.col_name as CalcName, 'Skill' as CalcType, 'SKILL' as CalcTypeCode
from tbl_ppl_workbasket wb
left join tbl_dict_workbaskettype wbt on wbt.col_id = wb.col_workbasketworkbaskettype
inner join tbl_ppl_skill s on s.col_id = wb.col_workbasketskill
union all
select wb.col_id as WBId, wb.col_name as WBName, wb.col_code as WBCode, wbt.col_id as WBTId, wbt.col_name as WBTName, wbt.col_code as WBTCode,
          NVL(wb.col_isdefault,0) as WBIsDefault, NVL(wb.col_isprivate,0) as WBIsPrivate, null as AccessSubjectCode, null as EmailAddress,
          null as IsDeleted, null as CWId, null as ExternalPartyId, null as TeamId, null as SkillId, br.col_id as BusinessRoleId,
          br.col_name as CalcName, 'Business Role' as CalcType, 'BUSINESSROLE' as CalcTypeCode
from tbl_ppl_workbasket wb
left join tbl_dict_workbaskettype wbt on wbt.col_id = wb.col_workbasketworkbaskettype
inner join tbl_ppl_businessrole br on br.col_id = wb.col_workbasketbusinessrole
union all
select wb.col_id as WBId, wb.col_name as WBName, wb.col_code as WBCode, wbt.col_id as WBTId, wbt.col_name as WBTName, wbt.col_code as WBTCode,
          NVL(wb.col_isdefault,0) as WBIsDefault, NVL(wb.col_isprivate,0) as WBIsPrivate, null as AccessSubjectCode, null as EmailAddress,
          null as IsDeleted, null as CWId, null as ExternalPartyId, null as TeamId, null as SkillId, null as BusinessRoleId,
          NVL(wb.col_name,'MISSING') as CalcName, 'Group Workbasket' as CalcType, 'GROUPWB' as CalcTypeCode
from tbl_ppl_workbasket wb
left join tbl_dict_workbaskettype wbt on wbt.col_id = wb.col_workbasketworkbaskettype
where wb.col_workbasketbusinessrole is null and wb.col_workbasketskill is null and wb.col_workbasketteam is null and wb.col_workbasketexternalparty is null and wb.col_caseworkerworkbasket is null
)