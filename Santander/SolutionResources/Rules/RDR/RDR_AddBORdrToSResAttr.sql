DECLARE
  v_count number;
  v_maxorder number;
  v_i number;
  v_pathid NUMBER;
  v_groupResultAttrId number;
  v_groupSearchAttrId number;
  v_rootFomObject NUMBER; --input parameter
  v_sconfigid number; --input parameter
  v_attrtypecode nvarchar2(255);
  v_fomattributeid number;
  v_rcCode nvarchar2(255);
  v_somattrid Integer;
BEGIN
  --input parameters
  v_pathid := :PathId;
  v_sconfigid := :SConfigId;
  v_attrtypecode := :AttrTypeCode;
  v_fomattributeid := :FomAttributeId;
  
  v_i :=-2000;
  
  for rec in (select rc.col_id as RCId, rc.col_code as RCCode, rc.col_name as RCName, ro.col_id as ROId, ro.COL_RENDEROBJECTFOM_OBJECT as fomObjectId, ro.col_name as ROName,
              refo.COL_ID as REFOId
              from tbl_dom_rendercontrol rc
              inner join tbl_dom_renderobject ro on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id
              inner join tbl_dict_datatype dt on ro.col_dom_renderobjectdatatype = dt.col_id
              left join tbl_dom_referenceobject refo on ro.COL_RENDEROBJECTFOM_OBJECT = refo.COL_DOM_REFOBJECTFOM_OBJECT
              where dt.col_code = v_attrtypecode and rc.COL_ISDEFAULT = 1 and nvl(ro.COL_USEINCASE,0) = 0)
  loop  
      select col_code into v_rcCode 
      from tbl_fom_attribute
      where col_id = v_fomattributeid;
       
      v_rcCode := 'RC_' || (case 
                            when length(v_rcCode) > 27 then substr(v_rcCode, -20) || substr(to_char(v_fomattributeid),0, 10) 
                            else v_rcCode end);

      --create group ResultAttributes for each default RendererControl. Make it first and move others SOrder column
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_path, col_som_resultattrsom_config, COL_SOM_RESATTRRENDEROBJECT, COL_SOM_RESULTATTRRENDERCTRL, COL_SOM_RESULTATTRREFOBJECT, col_sorder, col_isrender)
      values (v_rcCode, rec.ROName, v_PathId, v_sconfigid, rec.ROId, rec.RCid, rec.REFOId, v_i, 1);
    
      select gen_tbl_som_resultattr.currval into v_groupResultAttrId from dual;
      
      -- Insert Render Control into som_attributes
      insert into tbl_som_attribute(col_code, col_name,  col_som_attributerenderobject, col_som_attributerefobject, col_som_attributesom_object)
      values(v_rcCode, rec.ROName, rec.ROId, rec.REFOId, (select so.col_id
                                                                                    from tbl_fom_attribute fa
                                                                                    inner join tbl_som_object so on so.col_som_objectfom_object =  fa.col_fom_attributefom_object
                                                                                    inner join tbl_som_config sc on sc.COL_SOM_CONFIGSOM_MODEL = so.col_som_objectsom_model and sc.col_id = v_sconfigid
                                                                                    where fa.col_id = v_fomattributeid));
      select gen_tbl_som_attribute.currval into v_somattrid from dual;

      --create group SearchAttributes for each default RendererControl. Make it first and move others SOrder column

      v_i := v_i +1;

      --create ResultAttributes for each RenderAttribute pointed to group ResultAttribute
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrsom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, COL_SOM_RESATTRRENDEROBJECT,
      COL_RESULTATTRRESULTATTRGROUP, COL_SOM_RESULTATTRRENDERATTR, col_sorder, col_isrender, col_processorcode)
      select ra.col_code, ra.col_name, v_fomattributeid, v_somattrid, v_PathId, v_sconfigid, ro.col_id, v_groupResultAttrId,  ra.col_id, rownum+v_i+1, 1,
      (select col_processorcode from tbl_dict_datatype where col_id = (select col_dom_renderobjectdatatype from tbl_dom_renderobject where col_id = ro.col_id))
      from tbl_dom_renderattr ra
      left join tbl_dom_renderobject ro on ra.COL_RENDERATTRRENDEROBJECT = ro.col_id
      inner join tbl_dom_rendercontrol rc on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id
      where rc.COL_ISDEFAULT = 1 and nvl(ro.COL_USEINCASE,0) = 0
      and rc.col_id = rec.RCId;

      v_i := v_i+SQL%ROWCOUNT+2;
      
  end loop; 
  
END;