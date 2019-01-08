with cts as
(select col_som_configsom_model as SomModelId from tbl_som_config where col_id = :CONFIGID)
select rownum as RowNumber, ObjLevel, ChildObjectId, ChildObjectCode, ChildObjectName, ParentObjectId, ParentObjectCode, ParentObjectName, AttributeId, AttributeCode, AttributeName,
ReferenceBOId, ReferenceBOCode, ReferenceBOName, RenderObjectId, RenderObjectCode, RenderObjectName, AttrType, AttrTypeCode
from
(
select s2.ObjLevel as ObjLevel,
s2.ChildBOId as ChildObjectId, s2.ChildBOCode as ChildObjectCode, s2.ChildBOName as ChildObjectName,
s2.ParentBOId as ParentObjectId, s2.ParentBOCode as ParentObjectCode, s2.ParentBOName as ParentObjectName,
s2.AttrId as AttributeId, s2.AttrCode as AttributeCode, s2.AttrName as AttributeName,
s2.AttrParentBOId as ReferenceBOId, s2.AttrParentBOCode as ReferenceBOCode, s2.AttrParentBOName as ReferenceBOName,
s2.RenderId as RenderObjectId, s2.RenderCode as RenderObjectCode, s2.RenderName as RenderObjectName,
s2.AttrType as AttrType, (case when s2.AttrType = 1 then to_nchar('INTERNAL') when s2.AttrType = 2 then to_nchar('EXTERNAL') end) as AttrTypeCode
from
--Custom (including references) Objects for Case Type
(select ObjLevel, s1.ChildBOId, s1.ChildBOCode, s1.ChildBOName, s1.ParentBOId, s1.ParentBOCode, s1.ParentBOName,
sa.ParentBOId as AttrParentBOId, sa.ParentBOCode as AttrParentBOCode, sa.ParentBOName as AttrParentBOName, sa.SOMAttrID as AttrID, sa.SOMAttrCode as AttrCode, sa.SOMAttrName as AttrName, sa.AttrType as AttrType,
ro.col_id as RenderId, ro.col_code as RenderCode, ro.col_name as RenderName
from
(
select cso.col_id as ChildBOId, cso.col_code as ChildBOCode, cso.col_name as ChildBOName, pso.col_id as ParentBOId, pso.col_code as ParentBOCode, pso.col_name as ParentBOName, level as ObjLevel
from tbl_som_object cso
inner join tbl_som_relationship sr on cso.col_id = sr.col_childsom_relsom_object
inner join tbl_som_object pso on sr.col_parentsom_relsom_object = pso.col_id
where cso.col_som_objectsom_model = (select SOMModelId from cts)
and pso.col_som_objectsom_model = (select SOMModelId from cts)
and cso.col_type in ('rootBusinessObject', 'businessObject') and pso.col_type <> 'referenceObject'
connect by prior pso.col_id = cso.col_id
start with cso.col_code = (select col_code from tbl_fom_object where col_id = (select col_som_configfom_object from tbl_som_config where col_id = :CONFIGID))) s1
inner join
(select null as ParentBOId, null as ParentBOCode, null as ParentBOName, sa.col_id as SOMAttrId, sa.col_code as SOMAttrCode, sa.col_name as SOMAttrName, sa.col_som_attributesom_object as SOMObjectCodeId,
 sa.col_som_attributerenderobject as RenderObjectId, null as RenderObjectCode, null as RenderObjectName, 1 as AttrType
 from tbl_som_attribute sa
 union
 select pso.col_id as ParentBOId, pso.col_code as ParentBOCode, pso.col_name as ParentBOName, null as SOMAttrID, null as SOMAttrCode, null as SOMAttrName, cso.col_id as SOMObjectCodeId,
 ro.col_id as RenderObjectId, ro.col_code as RenderObjectCode, ro.col_name as RenderObjectName, 2 as AttrType
 from tbl_som_object cso
 inner join tbl_som_relationship sr on cso.col_id = sr.col_childsom_relsom_object
 inner join tbl_som_object pso on sr.col_parentsom_relsom_object = pso.col_id
 left join tbl_dom_renderobject ro on pso.col_som_objectfom_object = ro.col_renderobjectfom_object
 where cso.col_som_objectsom_model = (select SOMModelId from cts)
 and pso.col_som_objectsom_model = (select SOMModelId from cts)
 and cso.col_type in ('rootBusinessObject', 'businessObject') and pso.col_type = 'referenceObject') sa on s1.ChildBOId = sa.SOMObjectCodeId
left join tbl_dom_renderobject ro on sa.RenderObjectId = ro.col_id) s2
union
--CASE INTERNAL ATTRIBUTES
select 999 as ObjLevel,
cso.col_id as ChildObjectId, cso.col_code as ChildObjectCode, cso.col_name as ChildObjectName,
so.col_id as ParentObjectId, so.col_code as ParentObjectCode, so.col_name as ParentObjectName,
sa.col_id as AttributeId, sa.col_code as AttributeCode, sa.col_name as AttributeName,
null as ReferenceBOId, null as ReferenceBOCode, null as ReferenceBOName,
ro.col_id as RenderObjectId, ro.col_code as RenderObjectCode, ro.col_name as RenderObjectName,
1 as AttrType, to_nchar('INTERNAL') as AttrTypeCode
from tbl_som_attribute sa
inner join tbl_som_object so on sa.col_som_attributesom_object = so.col_id
inner join tbl_som_relationship sr on  so.col_id = sr.col_parentsom_relsom_object
inner join tbl_som_object cso on sr.col_childsom_relsom_object = cso.col_id
left join tbl_dom_renderobject ro on sa.col_som_attributerenderobject = ro.col_id
where so.col_som_objectsom_model = (select SOMModelId from cts)
and so.col_code = 'CASE'
union
--CASE EXTERNAL ATTRIBUTES
select 999 as ObjLevel,
cfo.col_id as ChildObjectId, cfo.col_code as ChildObjectCode, cfo.col_name as ChildObjectName,
fo.col_id as ParentObjectId, fo.col_code as ParentObjectCode, fo.col_name as ParentObjectName,
null as AttributeId, null as AttributeCode, null as AttributeName,
refo.col_id as ReferenceBOId, refo.col_code as ReferenceBOCode, refo.col_name as ReferenceBOName,
ro.col_id as RenderObjectId, ro.col_code as RenderObjectCode, ro.col_name as RenderObjectName,
2 as AttrType, to_nchar('EXTERNAL') as AttrTypeCode
from tbl_dom_renderobject ro
inner join tbl_fom_object fo on ro.col_renderobjectfom_object = fo.col_id
inner join tbl_fom_relationship fr on fo.col_id = fr.col_parentfom_relfom_object
inner join tbl_fom_object cfo on fr.col_childfom_relfom_object = cfo.col_id and cfo.col_code = 'CASE'
left join tbl_dom_referenceobject refo on fo.col_id = refo.col_dom_refobjectfom_object
where col_useincase = 1
and col_renderobjectrendertype = 1
order by ObjLevel, AttrType)