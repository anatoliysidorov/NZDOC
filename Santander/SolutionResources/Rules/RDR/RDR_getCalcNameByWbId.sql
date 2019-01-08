DECLARE
  v_pathid NUMBER;
  v_groupResultAttrId number;
  v_rootFomObject NUMBER; --input parameter
  v_sconfigid number; --input parameter
BEGIN
  --input parameters
  v_rootFomObject := :RootFomObject /*8903*/;
  v_sconfigid := :SConfigId /*10034*/; 
  
  for rec in (select rc.col_id as RCId, rc.col_code as RCCode, rc.col_name as RCName, ro.col_id as ROId, ro.COL_RENDEROBJECTFOM_OBJECT as fomObjectId, fo.col_code as foCode
              from tbl_dom_rendercontrol rc
              inner join tbl_dom_renderobject ro on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id
              inner join tbl_fom_object fo on fo.col_id = ro.COL_RENDEROBJECTFOM_OBJECT
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
              AND childObject.col_id      = rec.fomObjectId;  
            exception
              when NO_DATA_FOUND then
                v_pathid := null;              
                return -1;
              when TOO_MANY_ROWS then
                v_pathid := null;
                return -1;
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
              WHERE parentObject.col_code = rec.fomObjectId
              AND childObject.col_id      = 'CASE';  
            exception
              when NO_DATA_FOUND then
                v_pathid := null;              
                return -1;
              when TOO_MANY_ROWS then
                v_pathid := null;
                return -1;
        end;
        end if;
        
       
  
  
      --create group ResultAttributes for each defaule RendererControl
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_path, col_som_resultattrsom_config, COL_SOM_RESATTRRENDEROBJECT, COL_SOM_RESULTATTRRENDERCTRL)
      values ('RC_' || rec.RCCode, rec.RCName, v_PathId, v_sconfigid, rec.ROId, rec.RCid);
    
      select gen_tbl_som_resultattr.currval into v_groupResultAttrId from dual;
      
      
      --create ResultAttributes for each RenderAttribute pointed to group ResultAttribute
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, COL_SOM_RESATTRRENDEROBJECT, COL_RESULTATTRRESULTATTRGROUP, COL_SOM_RESULTATTRRENDERATTR)
      select ra.col_code, ra.col_name, ra.COL_RENDERATTRFOM_ATTRIBUTE, v_PathId, v_sconfigid, ro.col_id, v_groupResultAttrId,  ra.col_id
      from tbl_dom_renderattr ra
      left join tbl_dom_renderobject ro on ra.COL_RENDERATTRRENDEROBJECT = ro.col_id
      inner join tbl_dom_rendercontrol rc on rc.COL_RENDERCONTROLRENDEROBJECT = ro.col_id
      where rc.COL_ISDEFAULT = 1 and ro.COL_USEINCASE = 1
      and rc.col_id = rec.RCId;

  end loop;

END;