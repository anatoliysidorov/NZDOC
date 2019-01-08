declare
  v_SOMResultAttrId number;
  v_DOMObjId number;
begin
  v_SOMResultAttrId := :SOMResultAttrID;
  begin
    select do.col_id as DOMObjId into v_DOMObjId
    from tbl_som_resultattr ra
    inner join tbl_fom_attribute fa on ra.col_som_resultattrfom_attr = fa.col_id
    inner join tbl_fom_object fo on fa.col_fom_attributefom_object = fo.col_id
    inner join tbl_som_config sc on ra.col_som_resultattrsom_config = sc.col_id
    inner join tbl_som_model sm on sc.col_som_configsom_model = sm.col_id
    inner join tbl_mdm_model mm on sm.col_som_modelmdm_model = mm.col_id
    inner join tbl_dom_model dm on mm.col_id = dm.col_dom_modelmdm_model
    inner join tbl_dom_object do on dm.col_id = do.col_dom_objectdom_model
    inner join tbl_fom_object fod on do.col_dom_objectfom_object = fod.col_id and fo.col_id = fod.col_id
    inner join tbl_dom_relationship dr on do.col_id = dr.col_childdom_reldom_object
    inner join tbl_dom_object pdo on dr.col_parentdom_reldom_object = pdo.col_id and pdo.col_type in ('parentBusinessObject', 'rootBusinessObject', 'businessObject')
    where ra.col_id = v_SOMResultAttrId;
    exception
    when NO_DATA_FOUND then
    v_DOMObjId := null;
  end;
  return v_DOMObjId;
end;