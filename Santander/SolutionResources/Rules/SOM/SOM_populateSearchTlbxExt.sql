with
sms as
(select col_som_configsom_model as SomModelId from tbl_som_config where col_id = :CONFIGID)
select rownum as RowNumber, ObjLevel, ChildObjectId, ChildObjectCode, ChildObjectName, ChildConfigId,
ParentObjectId, ParentObjectCode, ParentObjectName, AttributeId, AttributeCode, AttributeName,
ReferenceBOId, ReferenceBOCode, ReferenceBOName, RenderObjectId, RenderObjectCode, RenderObjectName,
ResAttrFAId, ResAttrFACode, ResAttrFAName, ResAttrROId, ResAttrROCode, ResAttrROName,
ResAttrRefObjId, ResAttrRefObjCode, ResAttrRefObjName,
SrchAttrFAId, SrchAttrFACode, SrchAttrFAName, SrchAttrROId, SrchAttrROCode, SrchAttrROName,
SrchAttrRefObjId, SrchAttrRefObjCode, SrchAttrRefObjName,
AttrType, AttrTypeCode
from
(
select s2.ObjLevel as ObjLevel,
s2.ChildBOId as ChildObjectId, s2.ChildBOCode as ChildObjectCode, s2.ChildBOName as ChildObjectName, s2.ChildConfigId as ChildConfigId,
s2.ParentBOId as ParentObjectId, s2.ParentBOCode as ParentObjectCode, s2.ParentBOName as ParentObjectName,
s2.AttrId as AttributeId, s2.AttrCode as AttributeCode, s2.AttrName as AttributeName,
s2.AttrParentBOId as ReferenceBOId, s2.AttrParentBOCode as ReferenceBOCode, s2.AttrParentBOName as ReferenceBOName,
s2.RenderId as RenderObjectId, s2.RenderCode as RenderObjectCode, s2.RenderName as RenderObjectName,
s2.ResAttrFAId as ResAttrFAId, s2.ResAttrFACode as ResAttrFACode, s2.ResAttrFAName as ResAttrFAName,
s2.ResAttrROId as ResAttrROId, s2.ResAttrROCode as ResAttrROCode, s2.ResAttrROName as ResAttrROName,
s2.ResAttrRefObjId as ResAttrRefObjId, s2.ResAttrRefObjCode as ResAttrRefObjCode, s2.ResAttrRefObjName as ResAttrRefObjName,
s2.SrchAttrFAId as SrchAttrFAId, s2.SrchAttrFACode as SrchAttrFACode, s2.SrchAttrFAName as SrchAttrFAName,
s2.SrchAttrROId as SrchAttrROId, s2.SrchAttrROCode as SrchAttrROCode, s2.SrchAttrROName as SrchAttrROName,
s2.SrchAttrRefObjId as SrchAttrRefObjId, s2.SrchAttrRefObjCode as SrchAttrRefObjCode, s2.SrchAttrRefObjName as SrchAttrRefObjName,
s2.AttrType as AttrType, (case when s2.AttrType = 1 then to_nchar('INTERNAL') when s2.AttrType = 2 then to_nchar('EXTERNAL') end) as AttrTypeCode
from
--Custom (including references) Objects for Case Type
(select ObjLevel, s1.ChildBOId, s1.ChildBOCode, s1.ChildBOName,  s1.ChildConfigId as ChildConfigId, s1.ParentBOId, s1.ParentBOCode, s1.ParentBOName,
sa.ParentBOId as AttrParentBOId, sa.ParentBOCode as AttrParentBOCode, sa.ParentBOName as AttrParentBOName,
sa.SOMAttrID as AttrID, sa.SOMAttrCode as AttrCode, sa.SOMAttrName as AttrName, sa.AttrType as AttrType,
ro.col_id as RenderId, ro.col_code as RenderCode, ro.col_name as RenderName,
srafa.col_id as ResAttrFAId, srafa.col_code as ResAttrFACode, srafa.col_name as ResAttrFAName,
sraro.col_id as ResAttrROId, sraro.col_code as ResAttrROCode, sraro.col_name as ResAttrROName,
srarefo.col_id as ResAttrRefObjId, srarefo.col_code as ResAttrRefObjCode, srarefo.col_name as ResAttrRefObjName,
ssafa.col_id as SrchAttrFAId, ssafa.col_code as SrchAttrFACode, ssafa.col_name as SrchAttrFAName,
ssaro.col_id as SrchAttrROId, ssaro.col_code as SrchAttrROCode, ssaro.col_name as SrchAttrROName,
ssarefo.col_id as SrchAttrRefObjId, ssarefo.col_code as SrchAttrRefObjCode, ssarefo.col_name as SrchAttrRefObjName
from
(
select cso.col_id as ChildBOId, cso.col_code as ChildBOCode, cso.col_name as ChildBOName, pso.col_id as ParentBOId, pso.col_code as ParentBOCode, pso.col_name as ParentBOName,
(select col_id from tbl_som_config where col_code = (select col_code from tbl_som_model where col_id = (select SomModelId from sms)) || '_' || cso.col_code) as ChildConfigId, level as ObjLevel
from tbl_som_object cso
inner join tbl_som_relationship sr on cso.col_id = sr.col_childsom_relsom_object
inner join tbl_som_object pso on sr.col_parentsom_relsom_object = pso.col_id
where cso.col_som_objectsom_model = (select SOMModelId from sms)
and pso.col_som_objectsom_model = (select SOMModelId from sms)
and cso.col_type in ('rootBusinessObject', 'businessObject') and pso.col_type <> 'referenceObject'
connect by prior pso.col_id = cso.col_id
start with cso.col_code = (select col_code from tbl_fom_object where col_id = (select col_som_configfom_object from tbl_som_config where col_id = :CONFIGID))) s1
inner join
--CUSTOM OBJECT INTERNAL ATTRIBUTES
(select null as ParentBOId, null as ParentBOCode, null as ParentBOName,
 sa.col_id as SOMAttrId, sa.col_code as SOMAttrCode, sa.col_name as SOMAttrName,
 sa.col_som_attrfom_attr as FOMAttrId,
 sa.col_som_attributesom_object as SOMObjectCodeId,
 0 as FOMPathId,
 sa.col_som_attributerenderobject as RenderObjectId, null as RenderObjectCode, null as RenderObjectName,
 null as RefObjectId, null as RefObjectCode, null as RefObjectName, 1 as AttrType
 from tbl_som_attribute sa
 where (case when sa.col_som_attributerenderobject is null then sa.col_som_attributerenderobject
            when sa.col_som_attributerenderobject is not null then sa.col_som_attrfom_attr end) is null
 union
--CUSTOM OBJECT EXTERNAL ATTRIBUTES (REFERENCES)
 select pso.col_id as ParentBOId, pso.col_code as ParentBOCode, pso.col_name as ParentBOName,
 null as SOMAttrID, null as SOMAttrCode, null as SOMAttrName,
 null as FOMAttrId,
 cso.col_id as SOMObjectCodeId,
 fp.col_id as FOMPathId,
 ro.col_id as RenderObjectId, ro.col_code as RenderObjectCode, ro.col_name as RenderObjectName,
 refo.col_id as RefObjectId, refo.col_code as RefObjectCode, refo.col_name as RefObjectName, 2 as AttrType
 from tbl_som_object cso
 inner join tbl_som_relationship sr on cso.col_id = sr.col_childsom_relsom_object
 inner join tbl_som_object pso on sr.col_parentsom_relsom_object = pso.col_id
 inner join tbl_fom_relationship fr on sr.col_som_relfom_rel = fr.col_id
 inner join tbl_fom_path fp on fr.col_id = fp.col_fom_pathfom_relationship
 left join tbl_dom_renderobject ro on pso.col_som_objectfom_object = ro.col_renderobjectfom_object
 left join tbl_dom_referenceobject refo on pso.col_som_objectfom_object = refo.col_dom_refobjectfom_object
 where cso.col_som_objectsom_model = (select SOMModelId from sms)
 and pso.col_som_objectsom_model = (select SOMModelId from sms)
 and cso.col_type in ('rootBusinessObject', 'businessObject') and pso.col_type = 'referenceObject') sa on s1.ChildBOId = sa.SOMObjectCodeId
left join tbl_dom_renderobject ro on sa.RenderObjectId = ro.col_id
left join tbl_som_resultattr srafa on sa.FOMAttrId = srafa.col_som_resultattrfom_attr and srafa.col_som_resultattrsom_config = :CONFIGID and srafa.col_som_resultattrsom_config = s1.ChildConfigId
and (case when sa.FOMPathId = 0 then 0 else srafa.col_som_resultattrfom_path end) = sa.FOMPathId
and srafa.col_resultattrresultattrgroup is null and srafa.col_som_resultattrfom_attr is not null
left join tbl_som_resultattr sraro on sa.RenderObjectId = sraro.col_som_resattrrenderobject and sraro.col_som_resultattrsom_config = :CONFIGID and sraro.col_som_resultattrsom_config = s1.ChildConfigId
and (case when sa.FOMPathId = 0 then 0 else sraro.col_som_resultattrfom_path end) = sa.FOMPathId
and sraro.col_resultattrresultattrgroup is null and sraro.col_som_resultattrfom_attr is null
left join tbl_som_resultattr srarefo on sa.RefObjectId = srarefo.col_som_resultattrrefobject and srarefo.col_som_resultattrsom_config = :CONFIGID and srarefo.col_som_resultattrsom_config = s1.ChildConfigId
and (case when sa.FOMPathId = 0 then 0 else srarefo.col_som_resultattrfom_path end) = sa.FOMPathId
and srarefo.col_som_resultattrfom_attr is not null
left join tbl_som_searchattr ssafa on sa.FOMAttrId = ssafa.col_som_searchattrfom_attr and ssafa.col_som_searchattrsom_config = :CONFIGID and ssafa.col_som_searchattrsom_config = s1.ChildConfigId
and (case when sa.FOMPathId = 0 then 0 else ssafa.col_som_searchattrfom_path end) = sa.FOMPathId
and ssafa.col_searchattrsearchattrgroup is null and ssafa.col_som_searchattrfom_attr is not null
left join tbl_som_searchattr ssaro on sa.RenderObjectId = ssaro.col_som_srchattrrenderobject and ssaro.col_som_searchattrsom_config = :CONFIGID and ssaro.col_som_searchattrsom_config = s1.ChildConfigId
and (case when sa.FOMPathId = 0 then 0 else ssaro.col_som_searchattrfom_path end) = sa.FOMPathId
and ssaro.col_searchattrsearchattrgroup is null and ssaro.col_som_searchattrfom_attr is null
left join tbl_som_searchattr ssarefo on sa.RefObjectId = ssarefo.col_som_searchattrrefobject and ssarefo.col_som_searchattrsom_config = :CONFIGID and ssarefo.col_som_searchattrsom_config = s1.ChildConfigId
and (case when sa.FOMPathId = 0 then 0 else ssarefo.col_som_searchattrfom_path end) = sa.FOMPathId
and ssarefo.col_som_searchattrfom_attr is not null) s2
union
--CASE INTERNAL ATTRIBUTES
select 999 as ObjLevel,
cso.col_id as ChildObjectId, cso.col_code as ChildObjectCode, cso.col_name as ChildObjectName, null as ChildConfigId,
so.col_id as ParentObjectId, so.col_code as ParentObjectCode, so.col_name as ParentObjectName,
sa.col_id as AttributeId, sa.col_code as AttributeCode, sa.col_name as AttributeName,
null as ReferenceBOId, null as ReferenceBOCode, null as ReferenceBOName,
ro.col_id as RenderObjectId, ro.col_code as RenderObjectCode, ro.col_name as RenderObjectName,
srafa.col_id as ResAttrFAId, srafa.col_code as ResAttrFACode, srafa.col_name as ResAttrFAName,
sraro.col_id as ResAttrROId, sraro.col_code as ResAttrROCode, sraro.col_name as ResAttrROName,
srarefo.col_id as ResAttrRefObjId, srarefo.col_code as ResAttrRefObjCode, srarefo.col_name as ResAttrRefObjName,
ssafa.col_id as SrchAttrFAId, ssafa.col_code as SrchAttrFACode, ssafa.col_name as SrchAttrFAName,
ssaro.col_id as SrchAttrROId, ssaro.col_code as SrchAttrROCode, ssaro.col_name as SrchAttrROName,
ssarefo.col_id as SrchAttrRefObjId, ssarefo.col_code as SrchAttrRefObjCode, ssarefo.col_name as SrchAttrRefObjName,
1 as AttrType, to_nchar('INTERNAL') as AttrTypeCode
from tbl_som_attribute sa
inner join tbl_som_object so on sa.col_som_attributesom_object = so.col_id
inner join tbl_som_relationship sr on  so.col_id = sr.col_parentsom_relsom_object
inner join tbl_som_object cso on sr.col_childsom_relsom_object = cso.col_id
inner join tbl_fom_relationship fr on sr.col_som_relfom_rel = fr.col_id
inner join tbl_fom_path fp on fr.col_id = fp.col_fom_pathfom_relationship
left join tbl_dom_renderobject ro on sa.col_som_attributerenderobject = ro.col_id
left join tbl_som_resultattr srafa on sa.col_som_attrfom_attr = srafa.col_som_resultattrfom_attr
and srafa.col_som_resultattrsom_config = :CONFIGID
and srafa.col_som_resultattrfom_path = fp.col_id
and srafa.col_resultattrresultattrgroup is null and srafa.col_som_resultattrfom_attr is not null
left join tbl_som_resultattr sraro on sa.col_som_attributerenderobject = sraro.col_som_resattrrenderobject
and sraro.col_som_resultattrsom_config = :CONFIGID
and sraro.col_som_resultattrfom_path = fp.col_id
and sraro.col_resultattrresultattrgroup is null and sraro.col_som_resultattrfom_attr is null
left join tbl_som_resultattr srarefo on sa.col_som_attributerefobject = srarefo.col_som_resultattrrefobject
and srarefo.col_som_resultattrsom_config = :CONFIGID
and srarefo.col_som_resultattrfom_path = fp.col_id
and srarefo.col_som_resultattrfom_attr is not null
left join tbl_som_searchattr ssafa on sa.col_som_attrfom_attr = ssafa.col_som_searchattrfom_attr
and ssafa.col_som_searchattrsom_config = :CONFIGID
and ssafa.col_som_searchattrfom_path = fp.col_id
and ssafa.col_searchattrsearchattrgroup is null and ssafa.col_som_searchattrfom_attr is not null
left join tbl_som_searchattr ssaro on sa.col_som_attributerenderobject = ssaro.col_som_srchattrrenderobject
and ssaro.col_som_searchattrsom_config = :CONFIGID
and ssaro.col_som_searchattrfom_path = fp.col_id
and ssaro.col_searchattrsearchattrgroup is null and ssaro.col_som_searchattrfom_attr is null
left join tbl_som_searchattr ssarefo on sa.col_som_attributerefobject = ssarefo.col_som_searchattrrefobject
and ssarefo.col_som_searchattrsom_config = :CONFIGID
and ssarefo.col_som_searchattrfom_path = fp.col_id
and ssarefo.col_som_searchattrfom_attr is not null
where so.col_som_objectsom_model = (select SOMModelId from sms)
and so.col_code = 'CASE'
union
--CASE EXTERNAL ATTRIBUTES
select 999 as ObjLevel,
cfo.col_id as ChildObjectId, cfo.col_code as ChildObjectCode, cfo.col_name as ChildObjectName, null as ChildConfigId,
fo.col_id as ParentObjectId, fo.col_code as ParentObjectCode, fo.col_name as ParentObjectName,
null as AttributeId, null as AttributeCode, null as AttributeName,
refo.col_id as ReferenceBOId, refo.col_code as ReferenceBOCode, refo.col_name as ReferenceBOName,
ro.col_id as RenderObjectId, ro.col_code as RenderObjectCode, ro.col_name as RenderObjectName,
null as ResAttrFAId, null as ResAttrFACode, null as ResAttrFAName,
sraro.col_id as ResAttrROId, sraro.col_code as ResAttrROCode, sraro.col_name as ResAttrROName,
null as ResAttrRefObjId, null as ResAttrRefObjCode, null as ResAttrRefObjName,
null as SrchAttrFAId, null as SrchAttrFACode, null as SrchAttrFAName,
ssaro.col_id as SrchAttrROId, ssaro.col_code as SrchAttrROCode, ssaro.col_name as SrchAttrROName,
null as SrchAttrRefObjId, null as SrchAttrRefObjCode, null as SrchAttrRefObjName,
2 as AttrType, to_nchar('EXTERNAL') as AttrTypeCode
from tbl_dom_renderobject ro
inner join tbl_fom_object fo on ro.col_renderobjectfom_object = fo.col_id
inner join tbl_fom_relationship fr on fo.col_id = fr.col_parentfom_relfom_object
inner join tbl_fom_object cfo on fr.col_childfom_relfom_object = cfo.col_id and cfo.col_code = 'CASE'
inner join tbl_fom_path fp on fr.col_id = fp.col_fom_pathfom_relationship
left join tbl_dom_referenceobject refo on fo.col_id = refo.col_dom_refobjectfom_object
left join tbl_som_resultattr sraro on ro.col_id = sraro.col_som_resattrrenderobject and sraro.col_som_resultattrsom_config = :CONFIGID and sraro.col_som_resultattrfom_path = fp.col_id
and sraro.col_resultattrresultattrgroup is null
left join tbl_som_searchattr ssaro on ro.col_id = ssaro.col_som_srchattrrenderobject and ssaro.col_som_searchattrsom_config = :CONFIGID and ssaro.col_som_searchattrfom_path = fp.col_id
and ssaro.col_searchattrsearchattrgroup is null
where col_useincase = 1
and col_renderobjectrendertype = 1
order by ObjLevel, AttrType)