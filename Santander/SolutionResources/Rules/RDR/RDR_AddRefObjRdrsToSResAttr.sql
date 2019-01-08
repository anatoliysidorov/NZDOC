DECLARE
  v_count number;
  v_maxorder number;
  v_pathid NUMBER;
  v_groupResultAttrId number;
  v_groupSearchAttrId number;
  v_FomObjectCode nvarchar2(255);
  v_ObjectName nvarchar2(255);
  v_sconfigid number;
  v_PathCode nvarchar2(255);
  v_ResAttrCode nvarchar2(255);
  v_somattrid Integer;
BEGIN
  --input parameters
  v_pathid := :PathToParentId; 
  v_FomObjectCode := :FomObjectCode;
  v_ObjectName := :ObjectName;
  v_sconfigid := :SConfigId; 

  begin
    select col_code into v_PathCode
    from tbl_fom_path
    where col_id = v_pathid;
    exception
    when NO_DATA_FOUND then
    v_PathCode := null;
  end;

  for rec in (select rc.col_id as RCId, fo.col_id as foId, fo.col_code as foCode, rc.col_code as RCCode, rc.col_name as RCName, ro.col_id as ROId, ro.COL_RENDEROBJECTFOM_OBJECT as fomObjectId, refo.COL_ID as REFOId
                from tbl_dom_rendercontrol rc
                inner join tbl_dom_renderobject ro on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id
                inner join tbl_fom_object fo on fo.col_id = ro.COL_RENDEROBJECTFOM_OBJECT
                left join tbl_dom_referenceobject refo on ro.COL_RENDEROBJECTFOM_OBJECT = refo.COL_DOM_REFOBJECTFOM_OBJECT
                where 1=1
                and rc.COL_ISDEFAULT = 1
                and fo.col_code = v_FomObjectCode)
  loop 
  
      select max(col_sorder) into v_maxorder
      from tbl_som_resultattr
      where col_som_resultattrsom_config = v_sconfigid;


      if ((v_maxorder is null) or (v_maxorder < 1)) then
         v_maxorder := 0;
      end if;

      if length('RC_' || v_PathCode) > 14 then
        v_ResAttrCode := substr('RC_' || v_PathCode,1,7) || substr(v_PathCode,-7) || '_';
      else
        v_ResAttrCode := 'RC_' || v_PathCode || '_';
      end if;
      -- v_ResAttrCode  must be unique
      if length(v_ObjectName) > 15 then
        v_ResAttrCode := v_ResAttrCode || substr(replace(v_ObjectName, ' ', '_'),-15);
      else
        v_ResAttrCode := v_ResAttrCode || replace(v_ObjectName, ' ', '_');
      end if;

      --create group ResultAttributes for each default RendererControl. Make it first and move others SOrder column
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_path, col_som_resultattrsom_config, COL_SOM_RESATTRRENDEROBJECT, COL_SOM_RESULTATTRRENDERCTRL, COL_SOM_RESULTATTRREFOBJECT, col_sorder)
      values (v_ResAttrCode, v_ObjectName /*rec.RCName*/, v_PathId, v_sconfigid, rec.ROId, rec.RCid, rec.REFOId, v_maxorder+1);

      select gen_tbl_som_resultattr.currval into v_groupResultAttrId from dual;

      --create group SearchAttributes for each default RendererControl. Make it first and move others SOrder column
      insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_path, col_som_searchattrsom_config, COL_SOM_SRCHATTRRENDEROBJECT, COL_SOM_SEARCHATTRRENDERCTRL, COL_SOM_SEARCHATTRREFOBJECT, col_sorder)
      values (v_ResAttrCode, v_ObjectName /*rec.RCName*/, v_PathId, v_sconfigid, rec.ROId, rec.RCid, rec.REFOId, v_maxorder+1);

      select gen_tbl_som_searchattr.currval into v_groupSearchAttrId from dual;
      
      --Insert Render Control into som_attributes
      insert into tbl_som_attribute(col_code, col_name,  col_som_attributerenderobject, col_som_attributerefobject, col_som_attributesom_object)
      values (v_ResAttrCode, v_ObjectName, rec.ROId, rec.REFOId, (select so.col_id
                                                        from tbl_som_object so   
                                                        inner join tbl_som_config sc on sc.COL_SOM_CONFIGSOM_MODEL = so.col_som_objectsom_model and sc.col_id = v_sconfigid
                                                        inner join tbl_fom_object fo on fo.col_id = so.col_som_objectfom_object
                                                        where fo.col_code = v_FomObjectCode and so.col_name = v_ObjectName));
      select gen_tbl_som_attribute.currval into v_somattrid from dual;


      if length(v_PathCode) > 14 then
        v_ResAttrCode := substr(v_PathCode,1,7) || substr(v_PathCode,-7) || '_';
      else
        v_ResAttrCode := v_PathCode || '_';
      end if;

      --create ResultAttributes for each RenderAttribute pointed to group ResultAttribute
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrsom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config,
      COL_SOM_RESATTRRENDEROBJECT, COL_RESULTATTRRESULTATTRGROUP, COL_SOM_RESULTATTRRENDERATTR, col_sorder)
      select v_ResAttrCode || case when length(ra.col_code) > 15 then substr(ra.col_code, -15) else ra.col_code end
      /*ra.col_code || v_pathid*/, ra.col_name, ra.COL_RENDERATTRFOM_ATTRIBUTE, v_somattrid, v_PathId, v_sconfigid, ro.col_id, v_groupResultAttrId,  ra.col_id, rownum+v_maxorder+1
      from tbl_dom_renderattr ra
      inner join tbl_dom_renderobject ro on ra.COL_RENDERATTRRENDEROBJECT = ro.col_id
      inner join tbl_dom_rendercontrol rc on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id    
      inner join tbl_fom_object fo on fo.col_id = ro.COL_RENDEROBJECTFOM_OBJECT
      where 1=1 
      and rc.col_isdefault = 1      
      and rc.col_id = rec.RCId;

      --create SearchAttributes for each RenderAttribute pointed to group SearchAttribute
      insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrsom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config,
      COL_SOM_SRCHATTRRENDEROBJECT, COL_SEARCHATTRSEARCHATTRGROUP, COL_SOM_SEARCHATTRRENDERATTR, col_sorder)
      select v_ResAttrCode || case when length(ra.col_code) > 15 then substr(ra.col_code, -15) else ra.col_code end,
      ra.col_name, ra.COL_RENDERATTRFOM_ATTRIBUTE, v_somattrid, v_PathId, v_sconfigid, ro.col_id, v_groupSearchAttrId,  ra.col_id, rownum+v_maxorder+1
      from tbl_dom_renderattr ra
      inner join tbl_dom_renderobject ro on ra.COL_RENDERATTRRENDEROBJECT = ro.col_id
      inner join tbl_dom_rendercontrol rc on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id    
      inner join tbl_fom_object fo on fo.col_id = ro.COL_RENDEROBJECTFOM_OBJECT
      where 1=1 
      and rc.col_isdefault = 1      
      and rc.col_id = rec.RCId;
      --Update order for all previously existing attributes
      /*update tbl_som_resultattr
      set col_sorder = col_sorder +v_count
      where col_som_resultattrsom_config = v_sconfigid
      and col_id != v_groupResultAttrId 
      and COL_RESULTATTRRESULTATTRGROUP != v_groupResultAttrId;*/

  end loop;

END;