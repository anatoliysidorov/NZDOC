select dr.col_id
,dr.col_code
,dr.col_name
,dr.COL_PARENTDOM_RELDOM_OBJECT as DR_PARENTDOMOBJECTID
,dr.COL_CHILDDOM_RELDOM_OBJECT as DR_CHILDDOMOBJECTID
,fr.COL_FOREIGNKEYNAME AS FR_FOREIGNKEYNAME
, DP.COL_ID AS DP_ID
, DP.COL_UCODE AS DP_UCODE
, DP.COL_OWNER AS DP_OWNER
, DP.COL_NAME AS DP_NAME
, DP.COL_MODIFIEDBY AS DP_MODIFIEDBY
, DP.COL_LOCKEDBY AS DP_LOCKEDBY
, DP.COL_CREATEDBY AS DP_CREATEDBY
, DP.COL_CODE AS DP_CODE
, DP.COL_MODIFIEDDATE AS DP_MODIFIEDDATE
, DP.COL_LOCKEDEXPDATE AS DP_LOCKEDEXPDATE
, DP.COL_LOCKEDDATE AS DP_LOCKEDDATE
, DP.COL_CREATEDDATE AS DP_CREATEDDATE
, DP.COL_ISROOT AS DP_ISROOT
, DP.COL_ISSHARABLE AS DP_ISSHARABLE
, DP.COL_TYPE AS DP_TYPE
, DP.COL_DESCRIPTION AS DP_DESCRIPTION
, DP.COL_UCODE as  DP_UCODE
, DP.COL_DOM_OBJECTDICT_PARTYTYPE AS DP_DOM_OBJECTDICT_PARTYTYPE
, DP.COL_DOM_OBJECTDOM_MODEL AS DP_DOM_OBJECTDOM_MODEL
, DP.COL_DOM_OBJECTFOM_OBJECT AS DP_DOM_OBJECTFOM_OBJECT
, DP.COL_DOM_OBJECT_PATHTOPRNTEXT AS DP_DOM_OBJECT_PATHTOPRNTEXT
, DP.COL_DOM_OBJECT_PATHTOSRVPARTY AS DP_DOM_OBJECT_PATHTOSRVPARTY

, DC	.COL_ID AS DC_ID
, DC.COL_UCODE AS DC_UCODE
, DC.COL_OWNER AS DC_OWNER
, DC.COL_NAME AS DC_NAME
, DC.COL_MODIFIEDBY AS DC_MODIFIEDBY
, DC.COL_LOCKEDBY AS DC_LOCKEDBY
, DC.COL_CREATEDBY AS DC_CREATEDBY
, DC.COL_CODE AS DC_CODE
, DC.COL_MODIFIEDDATE AS DC_MODIFIEDDATE
, DC.COL_LOCKEDEXPDATE AS DC_LOCKEDEXPDATE
, DC.COL_LOCKEDDATE AS DC_LOCKEDDATE
, DC.COL_CREATEDDATE AS DC_CREATEDDATE
, DC.COL_ISROOT AS DC_ISROOT
, DC.COL_ISSHARABLE AS DC_ISSHARABLE
, DC.COL_TYPE AS DC_TYPE
, DC.COL_DESCRIPTION AS DC_DESCRIPTION
, DC.COL_UCODE as  DC_UCODE
, DC.COL_DOM_OBJECTDICT_PARTYTYPE AS DC_DOM_OBJECTDICT_PARTYTYPE
, DC.COL_DOM_OBJECTDOM_MODEL AS DC_DOM_OBJECTDOM_MODEL
, DC.COL_DOM_OBJECTFOM_OBJECT AS DC_DOM_OBJECTFOM_OBJECT
, DC.COL_DOM_OBJECT_PATHTOPRNTEXT AS DC_DOM_OBJECT_PATHTOPRNTEXT
, DC.COL_DOM_OBJECT_PATHTOSRVPARTY AS DC_DOM_OBJECT_PATHTOSRVPARTY

,fp.COL_TABLENAME as FOPARENT_ALIAS
,fp.COL_TABLENAME as FOPARENT_APICODE
,fp.COL_TABLENAME as FOPARENT_CODE
,fp.COL_TABLENAME as FOPARENT_ISADDED
,fp.COL_TABLENAME as FOPARENT_ISDELETED
,fp.COL_TABLENAME as FOPARENT_NAME
,fp.COL_TABLENAME as FOPARENT_TABLENAME
,fp.COL_TABLENAME as FOPARENT_XMLALIAS
,fc.COL_TABLENAME as FOchild_ALIAS
,fc.COL_TABLENAME as FOchild_APICODE
,fc.COL_TABLENAME as FOchild_CODE
,fc.COL_TABLENAME as FOchild_ISADDED
,fc.COL_TABLENAME as FOchild_ISDELETED
,fc.COL_TABLENAME as FOchild_NAME
,fc.COL_TABLENAME as FOchild_TABLENAME
,fc.COL_TABLENAME as FOchild_XMLALIAS
from tbl_dom_relationship dr
inner join tbl_fom_relationship fr
        on dr.COL_DOM_RELFOM_REL = fr.col_id
inner join tbl_dom_object DP         on DP.col_id = dr.COL_PARENTDOM_RELDOM_OBJECT
inner join tbl_dom_object DC         on DC.col_id = dr.COL_CHILDDOM_RELDOM_OBJECT
inner join tbl_fom_object fp  on DP.COL_DOM_OBJECTFOM_OBJECT = fp.col_id
inner join tbl_fom_object fc   on DC.COL_DOM_OBJECTFOM_OBJECT = fc.col_id
        
start with dr.col_parentdom_reldom_object in 
    (select do.col_id 
      from tbl_dom_object do
      where do.col_type in ('parentBusinessObject'/*, 'referenceObject'*/) 
      and do.col_dom_objectdom_model = :DomModelId
      )
connect by prior dr.col_childdom_reldom_object = dr.col_parentdom_reldom_object