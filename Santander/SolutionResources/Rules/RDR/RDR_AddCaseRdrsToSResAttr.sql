DECLARE
  v_count number;
  v_maxorder number;
  v_i number;
  v_pathid NUMBER;
  v_groupResultAttrId number;
  v_groupSearchAttrId number;
  v_rootFomObject NUMBER; --input parameter
  v_sconfigid number; --input parameter
  v_somattrid Integer;
BEGIN
  --input parameters
  v_rootFomObject := :RootFomObject;
  v_sconfigid := :SConfigId; 
  
  v_i :=-2000;
  
  for rec in (select rc.col_id as RCId, rc.col_code as RCCode, rc.col_name as RCName, ro.col_id as ROId, ro.COL_RENDEROBJECTFOM_OBJECT as fomObjectId, fo.col_code as foCode, ro.COL_NAME AS ROName, refo.COL_ID as REFOId
              from tbl_dom_rendercontrol rc
              inner join tbl_dom_renderobject ro on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id
              inner join tbl_fom_object fo on fo.col_id = ro.COL_RENDEROBJECTFOM_OBJECT
              left join tbl_dom_referenceobject refo on ro.COL_RENDEROBJECTFOM_OBJECT = refo.COL_DOM_REFOBJECTFOM_OBJECT
              where rc.COL_ISDEFAULT = 1 and ro.COL_USEINCASE = 1)
  loop  
        
        --calculate pathId between CASE and RenderObject.FomObject
        if rec.foCode = 'CASE' then
           begin
            SELECT fp.col_id into v_pathid
              FROM tbl_fom_relationship fr
              LEFT JOIN tbl_fom_path fp
              ON fp.COL_FOM_PATHFOM_RELATIONSHIP = fr.col_id
              LEFT JOIN tbl_fom_object parentObject
              ON parentObject.col_id = fr.COL_PARENTFOM_RELFOM_OBJECT
              LEFT JOIN tbl_fom_object childObject
              ON childObject.col_id       = fr.COL_CHILDFOM_RELFOM_OBJECT
              WHERE parentObject.col_code = 'CASE'
              AND childObject.col_id      = v_rootFomObject;  
            exception
              when NO_DATA_FOUND then
                v_pathid := null;
              when TOO_MANY_ROWS then
                v_pathid := null;
          end;
        else
         begin
            SELECT fp.col_id into v_pathid
              FROM tbl_fom_relationship fr
              LEFT JOIN tbl_fom_path fp
              ON fp.COL_FOM_PATHFOM_RELATIONSHIP = fr.col_id
              LEFT JOIN tbl_fom_object parentObject
              ON parentObject.col_id = fr.COL_PARENTFOM_RELFOM_OBJECT
              LEFT JOIN tbl_fom_object childObject
              ON childObject.col_id       = fr.COL_CHILDFOM_RELFOM_OBJECT
              WHERE parentObject.col_id = rec.fomObjectId
              AND childObject.col_code      = 'CASE';  
            exception
              when NO_DATA_FOUND then
                v_pathid := null;
              when TOO_MANY_ROWS then
                v_pathid := null;
        end;
        end if;
     
  
      --create group ResultAttributes for each default RendererControl. Make it first and move others SOrder column
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_path, col_som_resultattrsom_config, COL_SOM_RESATTRRENDEROBJECT, COL_SOM_RESULTATTRRENDERCTRL, COL_SOM_RESULTATTRREFOBJECT, col_sorder, col_isrender)
      values ('RC_' || rec.RCCode, rec.ROName, v_PathId, v_sconfigid, rec.ROId, rec.RCid, rec.REFOId, v_i, 1);
    
      select gen_tbl_som_resultattr.currval into v_groupResultAttrId from dual;

      --create group SearchAttributes for each default RendererControl. Make it first and move others SOrder column
      insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_path, col_som_searchattrsom_config, COL_SOM_SRCHATTRRENDEROBJECT, COL_SOM_SEARCHATTRRENDERCTRL, COL_SOM_SEARCHATTRREFOBJECT, col_sorder, col_isrender)
      values ('RC_' || rec.RCCode, rec.ROName, v_PathId, v_sconfigid, rec.ROId, rec.RCid, rec.REFOId, v_i, 1);
    
      select gen_tbl_som_searchattr.currval into v_groupSearchAttrId from dual;
      
      begin
        select col_id into v_somattrid from tbl_som_attribute where col_code = 'RC_' || rec.RCCode and 
        col_som_attributesom_object = (select so.col_id
                                      from tbl_som_object so   
                                      inner join tbl_som_config sc on sc.COL_SOM_CONFIGSOM_MODEL = so.col_som_objectsom_model 
                                            and sc.col_id = v_sconfigid
                                      where so.col_code = 'CASE');
        exception
          when no_data_found then
              --Insert Render Control into som_attributes
              insert into tbl_som_attribute(col_code, col_name,  col_som_attributerenderobject, col_som_attributerefobject, col_som_attributesom_object)
              values ('RC_' || rec.RCCode, rec.ROName, rec.ROId, rec.REFOID, (select so.col_id
                                                                                            from tbl_som_object so   
                                                                                            inner join tbl_som_config sc on sc.COL_SOM_CONFIGSOM_MODEL = so.col_som_objectsom_model and sc.col_id = v_sconfigid
                                                                                            where so.col_code = 'CASE'));
              select gen_tbl_som_attribute.currval into v_somattrid from dual;
      end;

      v_i := v_i +1;

      
      --create ResultAttributes for each RenderAttribute pointed to group ResultAttribute
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrsom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, COL_SOM_RESATTRRENDEROBJECT,
      COL_RESULTATTRRESULTATTRGROUP, COL_SOM_RESULTATTRRENDERATTR, col_sorder, col_isrender, col_processorcode)
      select ra.col_code, ra.col_name, ra.COL_RENDERATTRFOM_ATTRIBUTE, v_somattrid, v_PathId, v_sconfigid, ro.col_id, v_groupResultAttrId,  ra.col_id, rownum+v_i+1, 1,
      (select col_processorcode from tbl_dict_datatype where col_id = (select col_dom_renderobjectdatatype from tbl_dom_renderobject where col_id = ro.col_id))
      from tbl_dom_renderattr ra
      left join tbl_dom_renderobject ro on ra.COL_RENDERATTRRENDEROBJECT = ro.col_id
      inner join tbl_dom_rendercontrol rc on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id
      where rc.COL_ISDEFAULT = 1 and ro.COL_USEINCASE = 1
      and rc.col_id = rec.RCId;

      --create SearchAttributes for each RenderAttribute pointed to group SearchAttribute
      insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrsom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config, COL_SOM_SRCHATTRRENDEROBJECT,
      COL_SEARCHATTRSEARCHATTRGROUP, COL_SOM_SEARCHATTRRENDERATTR, col_sorder, col_isrender, col_processorcode)
      select ra.col_code, ra.col_name, ra.COL_RENDERATTRFOM_ATTRIBUTE, v_somattrid, v_PathId, v_sconfigid, ro.col_id, v_groupSearchAttrId,  ra.col_id, rownum+v_i+1, 1,
      (select col_processorcode from tbl_dict_datatype where col_id = (select col_dom_renderobjectdatatype from tbl_dom_renderobject where col_id = ro.col_id))
      from tbl_dom_renderattr ra
      left join tbl_dom_renderobject ro on ra.COL_RENDERATTRRENDEROBJECT = ro.col_id
      inner join tbl_dom_rendercontrol rc on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id
      where rc.COL_ISDEFAULT = 1 and ro.COL_USEINCASE = 1
      and rc.col_id = rec.RCId;
      
      v_i := v_i+SQL%ROWCOUNT+2;
      
  end loop; 
  
END;