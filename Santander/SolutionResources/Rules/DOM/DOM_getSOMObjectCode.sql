declare
  v_SOMResultAttrId number;
  v_SOMObjCode nvarchar2(255);
begin
  v_SOMResultAttrId := :SOMResultAttrID;
  begin
    select so.col_code as SOMObjCode into v_SOMObjCode
    from tbl_som_resultattr ra
    inner join tbl_fom_attribute fa on ra.col_som_resultattrfom_attr = fa.col_id
    inner join tbl_fom_object fo on fa.col_fom_attributefom_object = fo.col_id
    inner join tbl_som_config sc on ra.col_som_resultattrsom_config = sc.col_id
    inner join tbl_som_model sm on sc.col_som_configsom_model = sm.col_id
    inner join tbl_som_object so on sm.col_id = so.col_som_objectsom_model and fo.col_id = so.col_som_objectfom_object
    inner join tbl_som_relationship sr on so.col_id = sr.col_childsom_relsom_object
    inner join tbl_som_object pso on sr.col_parentsom_relsom_object = pso.col_id and pso.col_type in ('parentBusinessObject', 'rootBusinessObject', 'businessObject')
    where ra.col_id = v_SOMResultAttrId;
    exception
    when NO_DATA_FOUND then
    v_SOMObjCode := null;
  end;
  return v_SOMObjCode;
end;