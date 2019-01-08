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
  v_appbasecode nvarchar2(255);
  v_relid Integer;
  v_relelementid Integer;
  v_relsource Integer;
  v_reltarget Integer;
  v_sourceobjcode nvarchar2(255);
  v_targetobjcode nvarchar2(255);
  v_sourceobjtype nvarchar2(255);
  v_targetobjtype nvarchar2(255);
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
  v_parentfomattrid Integer;
  v_fomattrid Integer;
  v_resultattrid Integer;
  v_searchattrid Integer;
  v_parentFOMPathId Integer;
  v_sconfigid Integer;
begin
  v_objectcode := :ObjectCode;
  v_parentobjectcode := :ParentObjectCode;

  if v_objectcode = v_parentobjectcode then
    return null;
  end if;

  select count(*) into v_sourceid from tbl_dom_modelcache
  where extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value') = objectCode and col_type = 'object' and col_subtype = 'referenceObject';

  if v_sourceid > 0 then
    v_value := v_objectcode;
    v_objectcode := v_parentobjectcode;
    v_parentobjectcode := v_value;
  end if;

  begin
    select RelId, ElementId, RelCode as RelCode, RelName as RelName, AppbaseCode, ForeignKeyName, RelSource, RelTarget,
    (select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value') from tbl_dom_modelcache
    where col_type = 'object' and col_elementid = RelSource) as SourceObjCode,
    (select col_subtype from tbl_dom_modelcache where col_type = 'object' and col_elementid = RelSource) as SourceObjType,
    (select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value') from tbl_dom_modelcache
    where col_type = 'object' and col_elementid = RelTarget) as TargetObjCode,
    (select col_subtype from tbl_dom_modelcache where col_type = 'object' and col_elementid = RelTarget) as TargetObjType
    into v_relid, v_relelementid, v_relcode, v_relname, v_appbasecode, v_foreignkeyname, v_relsource, v_reltarget, v_sourceobjcode, v_sourceobjtype, v_targetobjcode, v_targetobjtype
    from
    (select col_id as RelId, col_elementid as ElementId, col_type as Type, col_subtype as Subtype,
    extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value') as AppbaseCode,
    extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="ForeignKeyName"]/@value') as ForeignKeyName,
    extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value') as RelCode,
    extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Name"]/@value') as RelName,
    extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Source"]/@value') as RelSource,
    extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Target"]/@value') as RelTarget
    from tbl_dom_modelcache
    where col_type = 'relationship')
    where RelSource = (select col_elementid from tbl_dom_modelcache
                     where extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value') = v_parentobjectcode and col_type = 'object')
    and RelTarget = (select col_elementid from tbl_dom_modelcache
                     where extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value') = v_objectcode and col_type = 'object');
    exception
    when NO_DATA_FOUND then
    v_relid := null;
  end;

  if v_relcode is null then
    return null;
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
    select col_id into v_relid from tbl_fom_relationship where lower(col_apicode) = lower(v_appbasecode);
    exception
    when NO_DATA_FOUND then
      insert into tbl_fom_relationship(col_code, col_name, col_apicode, col_foreignkeyname, col_childfom_relfom_object, col_parentfom_relfom_object)
      values(v_relcode, v_relname, v_appbasecode, v_foreignkeyname, v_childfomobjectid, v_parentfomobjectid);
      select gen_tbl_fom_relationship.currval into v_relid from dual;
      if v_sourceobjtype <> 'referenceObject' then
        begin
          select col_id into v_parentfomattrid from tbl_fom_attribute where lower(col_code) = lower(v_targetobjcode || '_PARENTID');
          exception
          when NO_DATA_FOUND then
          insert into tbl_fom_attribute(col_code, col_name, col_apicode, col_columnname, col_alias, col_storagetype, col_fom_attributefom_object, col_fom_attributedatatype)
          values(v_targetobjcode || '_PARENTID', v_targetobjcode || '_PARENTID', v_appbasecode, v_foreignkeyname, 'PARENTID' /*v_relcode*/, 'SIMPLE', v_childfomobjectid,
                 (select col_id from tbl_dict_datatype where lower(col_code) = 'integer'));
          select gen_tbl_fom_attribute.currval into v_parentfomattrid from dual;
        end;
        begin
          select col_id into v_fomattrid from tbl_fom_attribute where lower(col_code) = lower(v_targetobjcode || '_ID');
          exception
          when NO_DATA_FOUND then
          insert into tbl_fom_attribute(col_code, col_name, col_apicode, col_columnname, col_alias, col_storagetype, col_fom_attributefom_object, col_fom_attributedatatype)
          values(v_targetobjcode || '_ID', v_targetobjcode || '_ID', 'root_' || v_targetobjcode || '_Id', 'col_id', 'ID', 'SIMPLE', v_childfomobjectid,
                 (select col_id from tbl_dict_datatype where lower(col_code) = 'integer'));
          select gen_tbl_fom_attribute.currval into v_fomattrid from dual;
        end;
      elsif v_sourceobjtype = 'referenceObject' then
        begin
          select col_id into v_parentfomattrid from tbl_fom_attribute where lower(col_code) = lower(v_relcode);
          exception
          when NO_DATA_FOUND then
          insert into tbl_fom_attribute(col_code, col_name, col_apicode, col_columnname, col_alias, col_storagetype, col_fom_attributefom_object, col_fom_attributedatatype)
          values(v_relcode, v_relcode, v_appbasecode, v_foreignkeyname, v_relcode, 'SIMPLE', v_childfomobjectid,
               (select col_id from tbl_dict_datatype where lower(col_code) = 'integer'));
          select gen_tbl_fom_attribute.currval into v_parentfomattrid from dual;
        end;
      end if;
      begin
        select col_id into v_pathtoparentid from tbl_fom_path where lower(col_code) = lower(v_relcode);
        exception
        when NO_DATA_FOUND then
          v_pathtoparentid := null;

          if(v_parentobjectcode <> 'CASE') then
            begin
              select col_id INTO v_parentFOMPathId
              from tbl_fom_path
              where col_fom_pathfom_relationship = (select col_id
                                                    from tbl_fom_relationship
                                                    where col_childfom_relfom_object = (select col_parentfom_relfom_object
                                                                                        from tbl_fom_relationship
                                                                                        where col_id = v_relid));
            exception
              when OTHERS then
                  v_parentFOMPathId := null;
            end;  
          end if; 

          insert into tbl_fom_path(col_code, col_name, col_fom_pathfom_relationship, col_jointype, col_fom_pathfom_path)
          values(v_relcode, v_relname, v_relid, 'LEFT', v_parentFOMPathId);
          select gen_tbl_fom_path.currval into v_pathid from dual;
          return v_pathid;
      end;
    when TOO_MANY_ROWS then
    --insert into tbl_log(col_data1, col_data2) values(v_appbasecode, 1);
    null;
  end;
  if v_relid is not null and v_pathtoparentid is null then
    begin
      select col_id into v_pathtoparentid from tbl_fom_path where lower(col_code) = lower(v_relcode);
      exception
      when NO_DATA_FOUND then
        insert into tbl_fom_path(col_code, col_name, col_fom_pathfom_relationship, col_jointype)
        values(v_relcode, v_relname, v_relid, 'LEFT');
        select gen_tbl_fom_path.currval into v_pathid from dual;
        return v_pathid;
    end;
  end if;
  begin
    select col_id into v_parentfomattrid from tbl_fom_attribute where lower(col_code) = lower(v_targetobjcode || '_PARENTID');
    exception
    when NO_DATA_FOUND then
    v_parentfomattrid := null;
  end;
  begin
    select col_id into v_fomattrid from tbl_fom_attribute where lower(col_code) = lower(v_targetobjcode || '_ID');
    exception
    when NO_DATA_FOUND then
    v_fomattrid := null;
  end;
  if v_parentfomattrid is not null and v_sourceobjtype <> 'referenceObject' then
    begin
      select col_id into v_resultattrid from tbl_som_resultattr where lower(col_code) = lower(v_targetobjcode || '_PARENTID');
      exception
      when NO_DATA_FOUND then
      begin
      select col_id into v_sconfigid from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid));
      exception
      when NO_DATA_FOUND then
      v_sconfigid := null;
      end;
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_sorder)
      values(v_targetobjcode || '_PARENTID', v_targetobjcode || '_PARENTID', v_parentfomattrid, v_pathtoparentid,
      (select col_id from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid))),
      nvl((select min(col_sorder) - 1 from tbl_som_resultattr where col_som_resultattrsom_config = (select col_id from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid)))),0));
      select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
    end;
    begin
      select col_id into v_resultattrid from tbl_som_resultattr where lower(col_code) = lower('PARENTOBJECTCODE')
      and col_som_resultattrsom_config = (select col_id from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid)));
      exception
      when NO_DATA_FOUND then
      begin
      select col_id into v_sconfigid from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid));
      exception
      when NO_DATA_FOUND then
      v_sconfigid := null;
      end;
      insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_metaproperty, col_idproperty, col_processorcode, col_sorder)
      values('PARENTOBJECTCODE', 'PARENTOBJECTCODE', v_parentfomattrid, v_pathtoparentid,
      (select col_id from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid))),
      1, 1, 'f_DOM_getParentSOMObjCode',
      nvl((select min(col_sorder) - 1 from tbl_som_resultattr where col_som_resultattrsom_config = (select col_id from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid)))),0));
      select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
    end;
    begin
      select col_id into v_searchattrid from tbl_som_searchattr where lower(col_code) = lower(v_targetobjcode || '_PARENTID');
      exception
      when NO_DATA_FOUND then
      insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config, col_sorder)
      values(v_targetobjcode || '_PARENTID', v_targetobjcode || '_PARENTID', v_parentfomattrid, v_pathtoparentid,
      (select col_id from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid))),
      nvl((select min(col_sorder) - 1 from tbl_som_searchattr where col_som_searchattrsom_config = (select col_id from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid)))),0));
      select gen_tbl_som_searchattr.currval into v_searchattrid from dual;
    end;
  end if;
  if v_sourceobjtype = 'referenceObject' then
    begin
      select col_id into v_parentfomattrid from tbl_fom_attribute where lower(col_code) = lower(v_relcode);
      exception
      when NO_DATA_FOUND then
      v_parentfomattrid := null;
    end;
    if v_parentfomattrid is not null then
      begin
        select col_id into v_resultattrid from tbl_som_resultattr where lower(col_code) = lower(v_relcode);
        exception
        when NO_DATA_FOUND then
        insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_sorder)
        values(v_relcode, v_relcode, v_parentfomattrid, v_pathtoparentid,
        (select col_id from tbl_som_config where col_som_configfom_object =
        (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid))),
        nvl((select max(col_sorder) + 1 from tbl_som_resultattr where col_sorder <= 1000 and col_som_resultattrsom_config = (select col_id from tbl_som_config where col_som_configfom_object =
          (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid)))),0));
        select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
      end;
    end if;
  end if;
  begin
    select col_id into v_resultattrid from tbl_som_resultattr where lower(col_code) = lower(v_targetobjcode || '_ID');
    exception
    when NO_DATA_FOUND then
    begin
    select col_id into v_sconfigid from tbl_som_config where col_som_configfom_object =
    (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_fomattrid));
    exception
    when NO_DATA_FOUND then
    v_sconfigid := null;
    end;
    if v_sconfigid > 0 then
    insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_sorder)
    values(v_targetobjcode || '_ID', v_targetobjcode || '_ID', v_fomattrid, v_pathtoparentid,
    (select col_id from tbl_som_config where col_som_configfom_object =
    (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_fomattrid))),
    nvl((select min(col_sorder) - 1 from tbl_som_resultattr where col_som_resultattrsom_config = (select col_id from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid)))),0));
    select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
    end if;
    when TOO_MANY_ROWS then
    --insert into tbl_log(col_data1, col_data2) values (lower(v_targetobjcode || '_ID'), 2);
    null;
  end;
  begin
    select col_id into v_searchattrid from tbl_som_searchattr where lower(col_code) = lower(v_targetobjcode || '_ID');
    exception
    when NO_DATA_FOUND then
    begin
    select col_id into v_sconfigid from tbl_som_config where col_som_configfom_object =
    (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_fomattrid));
    exception
    when NO_DATA_FOUND then
    v_sconfigid := null;
    end;
    if v_sconfigid > 0 then
    insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config, col_sorder)
    values(v_targetobjcode || '_ID', v_targetobjcode || '_ID', v_fomattrid, v_pathtoparentid,
    (select col_id from tbl_som_config where col_som_configfom_object =
    (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_fomattrid))),
    nvl((select min(col_sorder) - 1 from tbl_som_searchattr where col_som_searchattrsom_config = (select col_id from tbl_som_config where col_som_configfom_object =
      (select col_id from tbl_fom_object where col_id = (select col_fom_attributefom_object from tbl_fom_attribute where col_id = v_parentfomattrid)))),0));
    select gen_tbl_som_searchattr.currval into v_searchattrid from dual;
    end if;
    when TOO_MANY_ROWS then
    --insert into tbl_log(col_data1, col_data2) values (lower(v_targetobjcode || '_ID'), 3);
    null;
  end;
  return v_pathtoparentid;
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  return null;

end;