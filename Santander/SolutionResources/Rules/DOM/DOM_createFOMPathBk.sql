declare
  v_elementid Integer;
  v_objectcode nvarchar2(255);
  v_parentobjectcode nvarchar2(255);
  v_parentelementid Integer;
  v_elementcount Integer;
  v_name nvarchar2(255);
  v_value nvarchar2(255);
  v_type nvarchar2(255);
  v_subtype nvarchar2(255);
  v_code nvarchar2(255);
  v_pathtoparent nvarchar2(255);
  v_pathtoparentid Integer;
  v_relname nvarchar2(255);
  v_relcode nvarchar2(255);
  v_childfomobjectid Integer;
  v_parentfomobjectid Integer;
  v_foreignkeyname nvarchar2(255);
  v_relid Integer;
  v_pathid Integer;
  v_sourceid Integer;
  v_source nvarchar2(255);
  v_sourcefomobjectid Integer;
  v_targetid Integer;
  v_target nvarchar2(255);
  v_targetfomobjectid Integer;
  v_relfound number;
  ErrorCode number;
  ErrorMessage nvarchar2(255);
  v_paramxml varchar2(32767);
  v_relparamxml varchar2(32767);
  v_objparamxml varchar2(32767);
begin
  v_objectcode := :ObjectCode;
  v_parentobjectcode := :ParentObjectCode;
  v_pathtoparent := v_objectcode || v_parentobjectcode;
  v_relcode := upper(v_pathtoparent);
  v_relname := v_pathtoparent;
  v_foreignkeyname := 'col_' || v_pathtoparent;
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  begin
    select col_elementid, col_type, col_subtype, xmlt.Code, xmlt.Value
    into v_elementid, v_type, v_subtype, v_code, v_value
    from tbl_dom_modelcache,
         xmltable('/Parameters/Parameter[1]'
         passing xmltype(tbl_dom_modelcache.col_paramxml)
         columns
         Code nvarchar2(255) path '@name',
         Value nvarchar2(255) path '@value') xmlt
    where col_type = 'object'
    and lower(xmlt.Value) = lower(v_objectcode);
    exception
    when NO_DATA_FOUND then
    v_elementid := null;
  end;
  if v_subtype = 'referenceObject' then
    v_value := v_objectcode;
    v_objectcode := v_parentobjectcode;
    v_parentobjectcode := v_value;
    v_pathtoparent := v_objectcode || v_parentobjectcode;
    v_relcode := upper(v_pathtoparent);
    v_relname := v_pathtoparent;
    v_foreignkeyname := 'col_' || v_pathtoparent;
  end if;
  begin
    select col_id into v_childfomobjectid from tbl_fom_object where lower(col_code) = lower(v_objectcode);
    exception
    when NO_DATA_FOUND then
    v_childfomobjectid := null;
  end;
  begin
    select col_id into v_parentfomobjectid from tbl_fom_object where lower(col_code) = lower(v_parentobjectcode);
    exception
    when NO_DATA_FOUND then
    v_parentfomobjectid := null;
  end;
  begin
    select col_id into v_pathtoparentid from tbl_fom_path where lower(col_code) = lower(v_relcode);
    exception
    when NO_DATA_FOUND then
      v_pathtoparentid := null;
      insert into tbl_fom_relationship(col_code, col_name, col_foreignkeyname, col_childfom_relfom_object, col_parentfom_relfom_object)
      values(v_relcode, v_relname, v_foreignkeyname, v_childfomobjectid, v_parentfomobjectid);
      select gen_tbl_fom_relationship.currval into v_relid from dual;
      insert into tbl_fom_path(col_code, col_name, col_fom_pathfom_relationship)
      values(v_relcode, v_relname, v_relid);
      select gen_tbl_fom_path.currval into v_pathid from dual;
      return v_pathid;
  end;
  return v_pathtoparentid;
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  return null;

end;