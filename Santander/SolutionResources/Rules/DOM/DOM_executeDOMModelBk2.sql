declare
  v_input nclob;
  v_elementid Integer;
  v_parentelementid Integer;
  v_type nvarchar2(255);
  v_subtype nvarchar2(255);
  v_elementcount number;
  v_name nvarchar2(255);
  v_modelcode nvarchar2(255);
  v_modelname nvarchar2(255);
  v_cmodelid Integer;
  v_modelid Integer;
  v_smodelid Integer;
  v_createconfigid Integer;
  v_editconfigid Integer;
  v_value varchar2(4000);
  v_code nvarchar2(255);
  v_description nvarchar2(255);
  v_rootfomobject nvarchar2(255);
  v_rootfomobjectid Integer;
  v_objectcode nvarchar2(255);
  v_objectname nvarchar2(255);
  v_objectdesc nvarchar2(255);
  v_objectappbasecode nvarchar2(255);
  v_objectdbname nvarchar2(255);
  v_objectid Integer;
  v_objecttype nvarchar2(255);
  v_objectsubtype nvarchar2(255);
  v_sobjectid Integer;
  v_fomobjectcode nvarchar2(255);
  v_fomobjectname nvarchar2(255);
  v_fomrelationshipcode nvarchar2(255);
  v_parentfomobject nvarchar2(255);
  v_parentfomobjectid Integer;
  v_fomobjectid Integer;
  v_partytype nvarchar2(255);
  v_partytypeid Integer;
  ErrorCode number;
  ErrorMessage nvarchar2(255);
  v_casetype nvarchar2(255);
  v_casetypeid Integer;
  v_pathtoparent nvarchar2(255);
  v_pathtoparentid Integer;
  v_issharable number;
  v_isroot number;
  v_attrcode nvarchar2(255);
  v_attrname nvarchar2(255);
  v_attrdesc nvarchar2(255);
  v_attrappbasecode nvarchar2(255);
  v_attrdbname nvarchar2(255);
  v_attrtypecode nvarchar2(255);
  v_attrtypename nvarchar2(255);
  v_source nvarchar2(255);
  v_sourceid Integer;
  v_sourceobjectcode nvarchar2(255);
  v_sourceobjectname nvarchar2(255);
  v_sourceobjectdbname nvarchar2(255);
  v_target nvarchar2(255);
  v_targetid Integer;
  v_targetobjectcode nvarchar2(255);
  v_targetobjectname nvarchar2(255);
  v_targetobjectdbname nvarchar2(255);
  v_mappingname nvarchar2(255);
  v_fomattribute nvarchar2(255);
  v_fomattributeid Integer;
  v_columnname nvarchar2(255);
  v_isinsertable number;
  v_isupdatable number;
  v_isretrievableindetail number;
  v_isretrievableinlist number;
  v_issearchable number;
  v_issystem number;
  v_isrequired number;
  v_attrorder number;
  v_isCaseInSensitive number;
  v_isLike number;
  v_linkorder number;
  v_relcode nvarchar2(255);
  v_relname nvarchar2(255);
  v_relappbasecode nvarchar2(255);
  v_reldbname nvarchar2(255);
  v_relforeignkeyname nvarchar2(255);
  v_relchildobject nvarchar2(255);
  v_relparentobject nvarchar2(255);
  v_relchildobjectid Integer;
  v_relparentobjectid Integer;
  v_fomrelid Integer;
  v_domrelid Integer;
  v_somrelid Integer;
  v_linkfomobjectid Integer;
  v_linkdomobjectid Integer;
  v_linkfomrelid Integer;
  v_linkfompathid Integer;
  v_islinkinsertable number;
  v_islinkupdatable number;
  v_islinkretrievableindetail number;
  v_islinkretrievableinlist number;
  v_islinksearchable number;
  v_paramxml varchar2(32767);
  v_relparamxml varchar2(32767);
  v_objparamxml varchar2(32767);
  v_sourcefomobjectid Integer;
  v_sourcedomobjectid Integer;
  v_sourcesomobjectid Integer;
  v_targetfomobjectid Integer;
  v_targetdomobjectid Integer;
  v_targetsomobjectid Integer;
  v_sconfigid Integer;
  v_srootconfigid Integer;
  v_domattrid Integer;
  v_somattrid Integer;
  v_insertattrid Integer;
  v_updateattrid Integer;
  v_resultattrid Integer;
  v_searchattrid Integer;
  v_result number;
  v_modeloverwrite number;
  v_attrconfig varchar2(32767);
  v_rootonly number;
begin
  --dbms_output.enable(500000);
  --dbms_output.put_line(v_rootattrcount);
  v_modeloverwrite := :ModelOverwrite;
  v_rootonly := nvl(:RootOnly,0);
  for rec in (select col_id as ID, col_elementid as ElementId, col_parentelementid as ParentElementId, col_type as Type, col_subtype as Subtype,
              case when col_type = 'model' then 1
                   when col_type = 'object' then 2
                   when col_type = 'relationship' then 3
                   when col_type = 'attribute' then 4
                   else 5 end as SortOrder,
                   col_paramxml as ParamXML
              from tbl_dom_modelcache
              order by SortOrder, col_elementid, col_id)
  loop
    v_elementid := rec.ElementId;
    v_parentelementid := rec.ParentElementId;
    v_type := rec.Type;
    v_subtype := rec.Subtype;
    v_paramxml := rec.ParamXML;
    v_sourceid := null;
    v_source := null;
    v_targetid := null;
    v_target := null;
    v_elementcount := 1;
    while (true)
    loop
      v_name := f_UTIL_extract_value_xml(Input => xmltype(v_paramxml), Path => '/Parameters/Parameter[' || to_char(v_elementcount) || ']/@name');
      v_value := f_UTIL_extract_value_xml(Input => xmltype(v_paramxml), Path => '/Parameters/Parameter[' || to_char(v_elementcount) || ']/@value');
      if v_name is null then
        exit;
      end if;
      if v_type = 'model' then
        if v_name = 'Name' then
          v_modelname := v_value;
        elsif v_name = 'Code' then
          v_code := v_value;
          v_modelcode := v_code;
        elsif v_name = 'Desc' then
          v_description := v_value;
        elsif v_name = 'RootFOMObject' then
          v_rootfomobject := v_value;
          if v_rootfomobject is not null then
            begin
              select col_id into v_rootfomobjectid from tbl_fom_object where lower(col_code) = lower(v_rootfomobject);
              if v_rootfomobjectid is not null then
                update tbl_fom_object set col_code = upper(v_rootfomobject), col_name = v_rootfomobject, col_tablename = 'tbl_' || v_rootfomobject,
                col_alias = 't_' || v_rootfomobject, col_xmlalias = 'xml_' || v_rootfomobject, col_isadded = 0, col_isdeleted = 0
                where col_id = v_rootfomobjectid;
              end if;
              exception
              when NO_DATA_FOUND then
              v_rootfomobjectid := null;
              insert into tbl_fom_object(col_code, col_name, col_tablename, col_alias, col_xmlalias, col_isadded, col_isdeleted)
              values(upper(v_rootfomobject), v_rootfomobject, 'tbl_' || v_rootfomobject, 't_' || v_rootfomobject, 'xml_' || v_rootfomobject, 0, 0);
              execute immediate 'select gen_tbl_fom_object.currval from dual' into v_rootfomobjectid;
            end;
          end if;
        elsif v_name = 'CaseType' then
          v_casetype := v_value;
          if v_casetype is not null then
            begin
              select col_id into v_casetypeid from tbl_dict_casesystype where lower(col_code) = lower(v_casetype);
              exception
              when NO_DATA_FOUND then
              v_casetypeid := null;
            end;
          end if;
          if v_modeloverwrite = 1 and v_casetypeid is not null then
            v_result := f_dom_clearDOMModel(ModelId => v_cmodelid, DeleteFOM => 1);
          end if;
        end if;
      elsif v_type = 'object' then
        if v_name = 'Name' then
          v_objectname := v_value;
        elsif v_name = 'Code' then
          v_code := v_value;
          v_objectcode := v_code;
        elsif v_name = 'Description' then
          v_objectdesc := v_value;
        elsif v_name = 'AppbaseCode' then
          v_objectappbasecode := v_value;
          begin
            select col_id into v_fomobjectid from tbl_fom_object where lower(col_apicode) = lower(v_objectappbasecode);
            if v_fomobjectid is not null then
              null;
            end if;
            exception
            when NO_DATA_FOUND then
              v_fomobjectid := null;
              select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value'),
                     extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="DBName"]/@value'),
                     extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="FOMObjectCode"]/@value')
                     into v_objectappbasecode, v_objectdbname, v_fomobjectcode
                     from tbl_dom_modelcache
                     where col_id = rec.ID;
              insert into tbl_fom_object(col_code, col_name, col_apicode, col_tablename, col_alias, col_xmlalias, col_isadded, col_isdeleted)
              values(upper(v_fomobjectcode), v_fomobjectcode, v_objectappbasecode, v_objectdbname, 't_' || v_fomobjectcode, 'xml_' || v_fomobjectcode, 0, 0);
              select gen_tbl_fom_object.currval into v_fomobjectid from dual;
          end;
        elsif v_name = 'FOMObjectCode' then
          v_fomobjectcode := v_value;
        elsif v_name = 'ParentFOMObject' then
          v_parentfomobject := v_value;
        elsif v_name = 'PartyType' then
          v_partytype := v_value;
          begin
            select col_id into v_partytypeid from tbl_dict_partytype where lower(col_code) = lower(v_partytype);
            exception
            when NO_DATA_FOUND then
              v_partytypeid := null;
          end;
        elsif v_name = 'IsSharable' then
          v_issharable := v_value;
        elsif v_name = 'IsRoot' then
          v_isroot := v_value;
        end if;
      elsif v_type = 'attribute' then
        if v_name = 'Code' then
          v_attrcode := v_value;
        elsif v_name = 'Name' then
          v_attrname := v_value;
        elsif v_name = 'Description' then
          v_attrdesc := v_value;
        elsif v_name = 'MappingName' then
          v_mappingname := v_value;
        elsif v_name = 'TypeCode' then
          v_attrtypecode := v_value;
        elsif v_name = 'TypeName' then
          v_attrtypename := v_value;
        elsif v_name = 'AppbaseCode' then
          v_attrappbasecode := v_value;
          select col_paramxml into v_objparamxml from tbl_dom_modelcache where col_elementid = v_elementid and col_type = 'object';
          select extractvalue(xmltype(v_objparamxml), 'Parameters/Parameter[@name="Code"]/@value'),
                 extractvalue(xmltype(v_objparamxml), 'Parameters/Parameter[@name="Name"]/@value'),
                 extractvalue(xmltype(v_objparamxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value')
                 into v_fomobjectcode, v_fomobjectname, v_objectappbasecode from dual;
          begin
            select col_id, col_code, col_name
            into v_fomobjectid, v_fomobjectcode, v_fomobjectname
            from tbl_fom_object
            where lower(col_apicode) = lower(v_objectappbasecode);
            exception
            when NO_DATA_FOUND then
            v_fomobjectid := null;
          end;
          begin
            select col_id into v_fomattributeid from tbl_fom_attribute where lower(col_apicode) = lower(v_attrappbasecode);
            if v_fomattributeid is not null then
              null;
            end if;
            exception
            when NO_DATA_FOUND then
              v_fomattributeid := null;
              select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value'),
                     extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="DBName"]/@value'),
                     extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="ColumnName"]/@value'),
                     extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="FOMAttribute"]/@value')
                     into v_attrappbasecode, v_attrdbname, v_columnname, v_fomattribute
                     from tbl_dom_modelcache
                     where col_id = rec.ID;
              if v_fomattribute is not null then
                begin
                  select col_id into v_fomattributeid from tbl_fom_attribute where lower(col_code) = lower(v_fomattribute);
                  exception
                  when NO_DATA_FOUND then

                  if (UPPER(v_fomobjectname) != 'CASE') then -- temporary!
                    begin
                      insert into tbl_fom_attribute(col_code, col_name, col_apicode, col_columnname, col_alias, col_storagetype, col_fom_attributefom_object, col_fom_attributedatatype)
                      values(v_fomattribute, /*v_fomobjectname || ' ' ||*/ v_attrname, v_attrappbasecode, v_columnname, v_fomattribute, 'SIMPLE', v_fomobjectid,
                      (select col_id from tbl_dict_datatype where lower(col_code) = lower(v_attrtypecode)));
                      select gen_tbl_fom_attribute.currval into v_fomattributeid from dual;
                    end;
                  end if;
                end;
              end if;
          end;
        elsif v_name = 'FOMAttribute' then
          v_fomattribute := v_value;
        elsif v_name = 'ColumnName' then
          v_columnname := v_value;
        elsif v_name = 'IsInsertable' then
          v_isinsertable := v_value;
        elsif v_name = 'IsUpdatable' then
          v_isupdatable := v_value;
        elsif v_name = 'IsRetrievableInDetail' then
          v_isretrievableindetail := v_value;
        elsif v_name = 'IsRetrievableInList' then
          v_isretrievableinlist := v_value;
        elsif v_name = 'IsSearchable' then
          v_issearchable := v_value;
        elsif v_name = 'IsSystem' then
          v_issystem := v_value;
        elsif v_name = 'IsRequired' then
          v_isrequired := v_value;
        elsif v_name = 'Order' then
          v_attrorder := v_value;
        elsif v_name = 'CaseSensitive' then
          if v_value = '1' then
            v_isCaseInSensitive := 0;
          else
            v_isCaseInSensitive := 1;
          end if;
        elsif v_name = 'SearchType' then
          if v_value = 'like' then
            v_isLike := 1;
          else 
            v_isLike := 0;
          end if;
        elsif v_name = 'AttrConfig' then
          select extractvalue(xmltype(v_paramxml), 'Parameters/Parameter[@name="AttrConfig"]')
                      into v_attrconfig
                      from dual;
        end if;
      elsif v_type = 'relationship' then
        if v_name = 'Code' then
          v_relcode := v_value;
        elsif v_name = 'Name' then
          v_relname := v_value;
        elsif v_name = 'AppbaseCode' then
          v_relappbasecode := v_value;
        elsif v_name = 'ForeignKeyName' then
          v_relforeignkeyname := v_value;
        elsif v_name = 'Source' then
          v_sourceid := v_value;
          begin
            select col_paramxml into v_relparamxml from tbl_dom_modelcache where col_elementid = v_sourceid and col_type = 'object';
            exception
            when NO_DATA_FOUND then
            v_relparamxml := null;
          end;
          if v_relparamxml is not null then
            begin
              --select extractvalue(xmltype(v_relparamxml), 'Parameters/Parameter[@name="Code"]/@value') into v_source from dual;
              select extractvalue(xmltype(v_relparamxml), 'Parameters/Parameter[@name="Code"]/@value'),
                     extractvalue(xmltype(v_relparamxml), 'Parameters/Parameter[@name="Name"]/@value'),
                     extractvalue(xmltype(v_relparamxml), 'Parameters/Parameter[@name="DBName"]/@value'),
                     extractvalue(xmltype(v_relparamxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value')
                     into v_sourceobjectcode, v_sourceobjectname, v_sourceobjectdbname, v_source from dual;
              exception
              when NO_DATA_FOUND then
              v_source := null;
            end;
          end if;
          begin
            select col_id into v_sourcefomobjectid from tbl_fom_object where lower(col_apicode) = lower(v_source);
            if v_sourcefomobjectid is not null then
              null;
            end if;
            exception
            when NO_DATA_FOUND then
            v_sourcefomobjectid := null;
            insert into tbl_fom_object(col_code, col_name, col_apicode, col_tablename, col_alias, col_xmlalias, col_isadded, col_isdeleted)
            values(upper(v_sourceobjectcode), v_sourceobjectname, v_source, v_sourceobjectdbname, 't_' || v_sourceobjectcode, 'xml_' || v_sourceobjectcode, 0, 0);
            select gen_tbl_fom_object.currval into v_sourcefomobjectid from dual;
          end;
          begin
            select col_id into v_sourcedomobjectid from tbl_dom_object where col_dom_objectfom_object = v_sourcefomobjectid and col_dom_objectdom_model = v_modelid;
            if v_sourcedomobjectid is not null then
              null;
            end if;
            exception
            when TOO_MANY_ROWS then
              null;
            when NO_DATA_FOUND then
            begin
              insert into tbl_dom_object(col_code, col_name, col_description, col_type, col_dom_objectfom_object, col_dom_objectdom_model, col_isroot)
              values(upper(v_sourceobjectcode), v_sourceobjectcode, v_objectdesc, v_subtype, v_sourcefomobjectid, v_modelid, v_isroot);
              exception
              when DUP_VAL_ON_INDEX then
              insert into tbl_dom_object(col_code, col_name, col_description, col_type, col_dom_objectfom_object, col_dom_objectdom_model, col_isroot)
              values(upper(v_sourceobjectcode) || sys_guid(), v_objectdesc, v_sourceobjectcode, v_subtype, v_sourcefomobjectid, v_modelid, v_isroot);
            end;
            select gen_tbl_dom_object.currval into v_sourcedomobjectid from dual;
          end;
          begin
            select col_id into v_sourcesomobjectid from tbl_som_object where col_som_objectfom_object = v_sourcefomobjectid and col_som_objectsom_model = v_smodelid;
            if v_sourcesomobjectid is not null then
              null;
            end if;
            exception
            when NO_DATA_FOUND then
            begin
              insert into tbl_som_object(col_code, col_name, col_description, col_type, col_som_objectfom_object, col_som_objectsom_model, col_isroot)
              values(upper(v_sourceobjectcode), v_sourceobjectcode, v_objectdesc, v_subtype, v_sourcefomobjectid, v_smodelid, v_isroot);
              exception
              when DUP_VAL_ON_INDEX then
              null;
            end;
            when TOO_MANY_ROWS then
            null;
            select gen_tbl_som_object.currval into v_sourcesomobjectid from dual;
          end;
        elsif v_name = 'Target' then
          v_targetid := v_value;
          begin
            select col_paramxml into v_relparamxml from tbl_dom_modelcache where col_elementid = v_targetid and col_type = 'object';
            exception
            when NO_DATA_FOUND then
            v_relparamxml := null;
          end;
          if v_relparamxml is not null then
            begin
              select extractvalue(xmltype(v_relparamxml), 'Parameters/Parameter[@name="Code"]/@value'),
                     extractvalue(xmltype(v_relparamxml), 'Parameters/Parameter[@name="Name"]/@value'),
                     extractvalue(xmltype(v_relparamxml), 'Parameters/Parameter[@name="DBName"]/@value'),
                     extractvalue(xmltype(v_relparamxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value')
                     into v_targetobjectcode, v_targetobjectname, v_targetobjectdbname, v_target from dual;
              exception
              when NO_DATA_FOUND then
              v_target := null;
            end;
          end if;
          begin
            select col_id into v_targetfomobjectid from tbl_fom_object where lower(col_apicode) = lower(v_target);
            if v_targetfomobjectid is not null then
              null;
            end if;
            exception
            when NO_DATA_FOUND then
            v_targetfomobjectid := null;
            insert into tbl_fom_object(col_code, col_name, col_apicode, col_tablename, col_alias, col_xmlalias, col_isadded, col_isdeleted)
            values(upper(v_targetobjectcode), v_targetobjectname, v_target, v_targetobjectdbname, 't_' || v_targetobjectcode, 'xml_' || v_targetobjectcode, 0, 0);
            select gen_tbl_fom_object.currval into v_targetfomobjectid from dual;
          end;
          begin
            select col_id into v_targetdomobjectid from tbl_dom_object where col_dom_objectfom_object = v_targetfomobjectid and col_dom_objectdom_model = v_modelid;
            if v_targetdomobjectid is not null then
              null;
            end if;
            exception
            when NO_DATA_FOUND then
            begin
              insert into tbl_dom_object(col_code, col_name, col_description, col_type, col_dom_objectfom_object, col_dom_objectdom_model, col_isroot)
              values(upper(v_targetobjectcode), v_targetobjectcode, v_objectdesc, v_subtype, v_targetfomobjectid, v_modelid, v_isroot);
              exception
              when DUP_VAL_ON_INDEX then
              insert into tbl_dom_object(col_code, col_name, col_description, col_type, col_dom_objectfom_object, col_dom_objectdom_model, col_isroot)
              values(upper(v_targetobjectcode) || sys_guid(), v_targetobjectcode, v_objectdesc, v_subtype, v_targetfomobjectid, v_modelid, v_isroot);
            end;
            select gen_tbl_dom_object.currval into v_targetdomobjectid from dual;
          end;
          begin
            select col_id into v_targetsomobjectid from tbl_som_object where col_som_objectfom_object = v_targetfomobjectid and col_som_objectsom_model = v_smodelid;
            if v_targetsomobjectid is not null then
              null;
            end if;
            exception
            when NO_DATA_FOUND then
            begin
              insert into tbl_som_object(col_code, col_name, col_description, col_type, col_som_objectfom_object, col_som_objectsom_model, col_isroot)
              values(upper(v_targetobjectcode), v_targetobjectcode, v_objectdesc, v_subtype, v_targetfomobjectid, v_smodelid, v_isroot);
              exception
              when DUP_VAL_ON_INDEX then
              null;
            end;
            select gen_tbl_som_object.currval into v_targetsomobjectid from dual;
          end;
        end if;
        if v_source is not null and v_target is not null then
          begin
            select col_id into v_fomrelid from tbl_fom_relationship where lower(col_apicode) = lower(v_relappbasecode);
            if v_fomrelid is not null then
              null;
            end if;
            exception
            when NO_DATA_FOUND then
              select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value'),
                     extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Name"]/@value'),
                     extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value'),
                     extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="DBName"]/@value'),
                     extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="ForeignKeyName"]/@value')
                     into v_relcode, v_relname, v_relappbasecode, v_reldbname, v_relforeignkeyname
                     from tbl_dom_modelcache
                     where col_id = rec.ID;
              insert into tbl_fom_relationship(col_code, col_name, col_apicode, col_foreignkeyname, col_childfom_relfom_object, col_parentfom_relfom_object)
              values(upper(v_relcode), v_relname, v_relappbasecode, v_relforeignkeyname,
              (select col_id from tbl_fom_object where lower(col_apicode) = lower(v_target)),
              (select col_id from tbl_fom_object where lower(col_apicode) = lower(v_source)));
              select gen_tbl_fom_relationship.currval into v_fomrelid from dual;
          end;
          begin
            select col_id into v_pathtoparentid from tbl_fom_path where lower(col_code) = lower(v_relcode);
            if v_pathtoparentid is not null then
              null;
            end if;
            exception
            when NO_DATA_FOUND then
            insert into tbl_fom_path(col_code, col_name, col_fom_pathfom_relationship, col_jointype)
            values(upper(v_relcode), v_relname, v_fomrelid, 'LEFT');
            select gen_tbl_fom_path.currval into v_pathtoparentid from dual;
          end;
        end if;
      end if;
      v_elementcount := v_elementcount + 1;
    end loop;
    if v_type = 'model' then
      begin
        select col_id into v_cmodelid from tbl_mdm_model where lower(col_code) = lower(v_code);
        if v_cmodelid is not null then
          null;
        end if;
        exception
        when NO_DATA_FOUND then
        insert into tbl_mdm_model(col_code, col_name, col_description, col_mdm_modelfom_object)
        values(v_code, v_modelname, v_description, v_rootfomobjectid);
        select gen_tbl_mdm_model.currval into v_cmodelid from dual;
        update tbl_dict_casesystype set col_casesystypemodel = v_cmodelid where col_id = v_casetypeid;
      end;
      begin
        select col_id into v_modelid from tbl_dom_model where lower(col_code) = lower(v_code);
        if v_modelid is not null then
          update tbl_dom_model set col_code = v_code, col_name = v_modelname, col_description = v_description, col_dom_modelmdm_model = v_cmodelid, col_dom_modelfom_object = v_rootfomobjectid
          where col_id = v_modelid;
        end if;
        exception
        when NO_DATA_FOUND then
        insert into tbl_dom_model(col_code, col_name, col_description, col_dom_modelmdm_model, col_dom_modelfom_object)
        values(v_code, v_modelname, v_description, v_cmodelid, v_rootfomobjectid);
        select gen_tbl_dom_model.currval into v_modelid from dual;
      end;
      begin
        select col_id into v_smodelid from tbl_som_model where lower(col_code) = lower(v_code);
        if v_smodelid is not null then
          update tbl_som_model set col_code = v_code, col_name = v_modelname, col_description = v_description, col_som_modelmdm_model = v_cmodelid, col_som_modelfom_object = v_rootfomobjectid
          where col_id = v_smodelid;
        end if;
        exception
        when NO_DATA_FOUND then
        insert into tbl_som_model(col_code, col_name, col_description, col_som_modelmdm_model, col_som_modelfom_object)
        values(v_code, v_modelname, v_description, v_cmodelid, v_rootfomobjectid);
        select gen_tbl_som_model.currval into v_smodelid from dual;
      end;
      begin
        select col_id into v_createconfigid from tbl_dom_config where lower(col_code) = lower(v_code || '_CREATE');
        if v_createconfigid is not null then
          update tbl_dom_config set col_code = v_code || '_CREATE', col_name = 'Create ' || v_modelname, col_description = 'Create ' || v_description,
          col_dom_configfom_object = (select col_id from tbl_fom_object where lower(col_code) = lower(v_code)),
          col_dom_configdom_model = v_modelid, col_purpose = 'CREATE'
          where col_id = v_createconfigid;
        end if;
        exception
        when NO_DATA_FOUND then
        insert into tbl_dom_config(col_code, col_name, col_description, col_dom_configfom_object, col_dom_configdom_model, col_purpose)
        values(v_code || '_CREATE', 'Create ' || v_modelname, 'Create ' || v_description,
        (select col_id from tbl_fom_object where lower(col_code) = lower(v_code)), v_modelid, 'CREATE');
        select gen_tbl_dom_config.currval into v_createconfigid from dual;
      end;
      begin
        select col_id into v_editconfigid from tbl_dom_config where lower(col_code) = lower(v_code || '_UPDATE');
        if v_editconfigid is not null then
          update tbl_dom_config set col_code = v_code || '_UPDATE', col_name = 'Update ' || v_modelname, col_description = 'Update ' || v_description,
          col_dom_configfom_object = (select col_id from tbl_fom_object where lower(col_code) = lower(v_code)),
          col_dom_configdom_model = v_modelid, col_purpose = 'EDIT'
          where col_id = v_editconfigid;
        end if;
        exception
        when NO_DATA_FOUND then
        insert into tbl_dom_config(col_code, col_name, col_description, col_dom_configfom_object, col_dom_configdom_model, col_purpose)
        values(v_code || '_UPDATE', 'Update ' || v_modelname, 'Update ' || v_description,
        (select col_id from tbl_fom_object where lower(col_code) = lower(v_code)), v_modelid, 'EDIT');
        select gen_tbl_dom_config.currval into v_editconfigid from dual;
      end;
    elsif v_type = 'object' then
      select col_paramxml into v_objparamxml from tbl_dom_modelcache where col_elementid = v_elementid and col_type = 'object';
      select extractvalue(xmltype(v_objparamxml), 'Parameters/Parameter[@name="FOMObjectCode"]/@value') into v_fomobjectcode from dual;
      select extractvalue(xmltype(v_objparamxml), 'Parameters/Parameter[@name="ParentFOMObject"]/@value') into v_parentfomobject from dual;
      v_pathtoparentid := f_DOM_createFOMPath(ObjectCode => v_code /*v_fomobjectcode*/, ParentObjectCode => v_parentfomobject);
      begin
        select col_id into v_objectid from tbl_dom_object where lower(col_code) = lower(v_code) and col_dom_objectdom_model = v_modelid;
        if v_objectid is not null then
          update tbl_dom_object set col_code = v_code, col_name = v_objectname, col_description = v_objectdesc, col_type = v_subtype, col_dom_objectdict_partytype = v_partytypeid, col_dom_objectdom_model = v_modelid,
          col_dom_object_pathtoprntext = v_pathtoparentid, col_dom_objectfom_object = v_fomobjectid, col_issharable = v_issharable, col_isroot = v_isroot
          where col_id = v_objectid;
        end if;
        exception
        when NO_DATA_FOUND then
        insert into tbl_dom_object(col_code, col_name, col_description, col_type, col_dom_objectdict_partytype, col_dom_objectdom_model, col_dom_object_pathtoprntext, col_dom_objectfom_object, col_issharable, col_isroot)
        values(v_code, v_objectname, v_objectdesc, v_subtype, v_partytypeid, v_modelid, v_pathtoparentid, v_fomobjectid, v_issharable, v_isroot);
        select gen_tbl_dom_object.currval into v_objectid from dual;
      end;
      begin
        select col_id into v_sobjectid from tbl_som_object where lower(col_code) = lower(v_code) and col_som_objectsom_model = v_smodelid;
        if v_objectid is not null then
          null;
        end if;
        exception
        when NO_DATA_FOUND then
        insert into tbl_som_object(col_code, col_name, col_description, col_type, col_som_objectsom_model, col_som_objectfom_object, col_issharable, col_isroot)
        values(v_code, v_objectname, v_objectdesc, v_subtype, v_smodelid,
        (select col_id from tbl_fom_object where lower(col_apicode) = lower(v_objectappbasecode)), v_issharable, v_isroot);
        select gen_tbl_som_object.currval into v_sobjectid from dual;
      end;
      if v_subtype in ('rootBusinessObject', 'businessObject') then
        begin
          select col_id into v_sconfigid from tbl_som_config where lower(col_code) = lower((select col_code from tbl_som_model where col_id = v_smodelid) || '_' || v_code);
          if v_sconfigid is not null then
            update tbl_som_config set col_code = (select col_code from tbl_som_model where col_id = v_smodelid) || '_' || v_code,
            col_name = (select col_name from tbl_som_model where col_id = v_smodelid) || ' ' || v_objectname,
            col_description = 'Automatically created when Data Model was created or updated' /*(select col_description from tbl_som_model where col_id = v_smodelid) || ' ' || v_objectdesc*/,
            col_som_configfom_object = (select col_id from tbl_fom_object where lower(col_code) = lower(v_code)),
            col_som_configsom_model = v_smodelid
            where col_id = v_sconfigid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_som_config(col_code, col_name, col_description, col_som_configfom_object, col_som_configsom_model)
          values((select col_code from tbl_som_model where col_id = v_smodelid) || '_' || v_code,
                (select col_name from tbl_som_model where col_id = v_smodelid) || ' ' || v_objectname,
                'Automatically created when Data Model was created or updated' /*(select col_description from tbl_som_model where col_id = v_smodelid) || ' ' || v_objectdesc*/,
                (select col_id from tbl_fom_object where lower(col_code) = lower(v_code)), v_smodelid);
          select gen_tbl_som_config.currval into v_sconfigid from dual;
          begin
            select col_id into v_resultattrid from tbl_som_resultattr where lower(col_code) = lower(v_code || '_PARENTID');
            update tbl_som_resultattr set col_som_resultattrsom_config = v_sconfigid where col_id = v_resultattrid;
            exception
            when NO_DATA_FOUND then
            null;
          end;
          begin
            select col_id into v_resultattrid from tbl_som_resultattr where lower(col_code) = lower(v_code || '_ID');
            update tbl_som_resultattr set col_som_resultattrsom_config = v_sconfigid where col_id = v_resultattrid;
            exception
            when NO_DATA_FOUND then
            null;
          end;
          begin
            select col_id into v_searchattrid from tbl_som_searchattr where lower(col_code) = lower(v_code || '_PARENTID');
            update tbl_som_searchattr set col_som_searchattrsom_config = v_sconfigid where col_id = v_searchattrid;
            exception
            when NO_DATA_FOUND then
            null;
          end;
          begin
            select col_id into v_searchattrid from tbl_som_searchattr where lower(col_code) = lower(v_code || '_ID');
            update tbl_som_searchattr set col_som_searchattrsom_config = v_sconfigid where col_id = v_searchattrid;
            exception
            when NO_DATA_FOUND then
            null;
          end;
        end;
        if v_subtype = 'rootBusinessObject' then
          v_srootconfigid := v_sconfigid;
        end if;
      end if;
    elsif v_type = 'attribute' then
      begin
        select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value'), col_type, col_subtype
        into v_code, v_objecttype, v_objectsubtype
        from tbl_dom_modelcache where col_elementid = v_elementid and col_type = 'object';
        exception
        when NO_DATA_FOUND then
        v_code := null;
      end;
      begin
        select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Name"]/@value') into v_objectname from tbl_dom_modelcache where col_elementid = v_elementid and col_type = 'object';
        exception
        when NO_DATA_FOUND then
        v_objectname := null;
      end;
      begin
        select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="FOMObjectCode"]/@value') into v_fomobjectcode from tbl_dom_modelcache where col_elementid = v_elementid and col_type = 'object';
        exception
        when NO_DATA_FOUND then
        v_fomobjectcode := null;
      end;
      begin
        select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="ParentFOMObject"]/@value') into v_parentfomobject from tbl_dom_modelcache where col_elementid = v_elementid and col_type = 'object';
        exception
        when NO_DATA_FOUND then
        v_parentfomobject := null;
      end;
      begin
        select col_id into v_sconfigid from tbl_som_config where lower(col_code) = lower((select col_code from tbl_som_model where col_id = v_smodelid) || '_' || v_code);
        exception
        when NO_DATA_FOUND then
        v_sconfigid := null;
      end;
      begin
        select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsInsertable"]/@value') as IsInsertable,
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsUpdatable"]/@value') as IsUpdatable,
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsRetrievableInList"]/@value') as IsRetrievableInList,
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsSearchable"]/@value') as IsSearchable
        into v_isinsertable, v_isupdatable, v_isretrievableinlist, v_issearchable
        from tbl_dom_modelcache
        where col_elementid = v_elementid
        and col_type = 'attribute'
        and lower(extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value')) = lower(v_attrappbasecode);
        exception
        when NO_DATA_FOUND then
        v_isinsertable := 0;
        v_isupdatable := 0;
        v_isretrievableinlist := 0;
        v_issearchable := 0;
      end;
      v_pathtoparentid := f_dom_createFOMPath(ObjectCode => v_code /*v_fomobjectcode*/, ParentObjectCode => v_parentfomobject);

      -- don't change Attribute Code for Parent Business Object - FOM_Attributes.col_code has correct Code for Parent BO (for example: CASE_ID, CASE_SUMMARY)
      IF (v_objectsubtype = 'parentBusinessObject') THEN
        v_attrcode := v_attrcode;
      ELSE
        v_attrcode := v_code || '_' || v_attrcode;
      END IF;
  
      begin
        select col_id into v_domattrid from tbl_dom_attribute where lower(col_code) = lower(v_attrcode)
        and col_dom_attributedom_object = (select col_id from tbl_dom_object where lower(col_code) = lower(v_code) and col_dom_objectdom_model = v_modelid);
        if v_domattrid is not null then
          update tbl_dom_attribute set col_code = v_attrcode, col_name = v_attrname, col_description = v_attrdesc, col_isinsertable = v_isinsertable,
          col_isupdatable = v_isupdatable, col_issearchable = v_issearchable, col_isretrievableindetail = v_isretrievableindetail,
          col_isretrievableinlist = v_isretrievableinlist, col_dorder = v_attrorder,
          col_dom_attrfom_attr = v_fomattributeid, col_dom_attributedom_object = (select col_id from tbl_dom_object where lower(col_code) = lower(v_code) and col_dom_objectdom_model = v_modelid),
          col_config = v_attrconfig, col_issystem = v_issystem, col_isrequired = v_isrequired
          where col_id = v_domattrid;
        end if;
        exception
        when NO_DATA_FOUND then
        insert into tbl_dom_attribute(col_code, col_name, col_description, col_isinsertable, col_isupdatable, col_issearchable, col_isretrievableindetail, col_isretrievableinlist, col_dorder,
                                      col_dom_attrfom_attr, col_dom_attributedom_object, col_config, col_issystem, col_isrequired)
        values(v_attrcode, v_attrname, v_attrdesc, v_isinsertable, v_isupdatable, v_issearchable, v_isretrievableindetail, v_isretrievableinlist, v_attrorder,
               v_fomattributeid, (select col_id from tbl_dom_object where lower(col_code) = lower(v_code) and col_dom_objectdom_model = v_modelid), v_attrconfig, v_issystem, v_isrequired);
        select gen_tbl_dom_attribute.currval into v_domattrid from dual;
      end;
      begin
        select col_id into v_somattrid from tbl_som_attribute where lower(col_code) = lower(v_attrcode)
        and col_som_attributesom_object = (select col_id from tbl_som_object where lower(col_code) = lower(v_code) and col_som_objectsom_model = v_smodelid);
        if v_somattrid is not null then
          update tbl_som_attribute set col_code = v_attrcode, col_name = v_attrname, col_description = v_attrdesc, col_isinsertable = v_isinsertable,
          col_isupdatable = v_isupdatable, col_issearchable = v_issearchable, col_isretrievableindetail = v_isretrievableindetail,
          col_isretrievableinlist = v_isretrievableinlist, col_dorder = v_attrorder,
          col_som_attrfom_attr = v_fomattributeid, col_som_attributesom_object = (select col_id from tbl_som_object where lower(col_code) = lower(v_code) and col_som_objectsom_model = v_smodelid),
          col_config = v_attrconfig, col_issystem = v_issystem
          where col_id = v_somattrid;
        end if;
        exception
        when NO_DATA_FOUND then
        insert into tbl_som_attribute(col_code, col_name, col_description, col_isinsertable, col_isupdatable, col_issearchable, col_isretrievableindetail, col_isretrievableinlist, col_dorder,
                                      col_som_attrfom_attr, col_som_attributesom_object, col_config, col_issystem)
        values(v_attrcode, v_attrname, v_attrdesc, v_isinsertable, v_isupdatable, v_issearchable, v_isretrievableindetail, v_isretrievableinlist, v_attrorder,
               v_fomattributeid, (select col_id from tbl_som_object where lower(col_code) = lower(v_code) and col_som_objectsom_model = v_smodelid), v_attrconfig, v_issystem);
        select gen_tbl_som_attribute.currval into v_somattrid from dual;
      end;

      if v_isinsertable = 1 then
        begin
          select col_id into v_insertattrid from tbl_dom_insertattr where lower(col_code) = lower(v_attrcode) and col_dom_insertattrdom_config = v_createconfigid;
          if v_insertattrid is not null then
            update tbl_dom_insertattr set col_code = v_attrcode, col_name = v_objectname || ' ' || v_attrname, col_mappingname = v_mappingname,
            col_dom_insertattrdom_config = v_createconfigid, col_dom_insertattrfom_attr = v_fomattributeid, col_dom_insertattrfom_path = v_pathtoparentid, col_dorder = v_attrorder
            where col_id = v_insertattrid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_dom_insertattr(col_code, col_name, col_mappingname, col_dom_insertattrdom_config, col_dom_insertattrfom_attr, col_dom_insertattrdom_attr, col_dom_insertattrfom_path, col_dorder)
          values(v_attrcode, v_objectname || ' ' || v_attrname, v_mappingname, v_createconfigid, v_fomattributeid,
          (select da.col_id from tbl_dom_attribute da
           inner join tbl_dom_object do on da.col_dom_attributedom_object = do.col_id
           inner join tbl_dom_model dm on do.col_dom_objectdom_model = dm.col_id
           inner join tbl_dom_config dc on dc.col_dom_configdom_model = dm.col_id
           where dc.col_id = v_createconfigid
           and lower(da.col_code) = lower(v_attrcode)), v_pathtoparentid, v_attrorder);
          select gen_tbl_dom_insertattr.currval into v_insertattrid from dual;
        end;
      end if;
      if v_isretrievableinlist = 1 and v_sconfigid is not null then
        begin
          select col_id into v_resultattrid from tbl_som_resultattr where lower(col_code) = lower(v_attrcode) and col_som_resultattrsom_config = v_sconfigid;
          if v_resultattrid is not null then
            update tbl_som_resultattr set col_code = v_attrcode, col_name = v_attrname, col_som_resultattrfom_attr = v_fomattributeid,
            col_som_resultattrfom_path = v_pathtoparentid, col_som_resultattrsom_config = v_sconfigid, col_sorder = v_attrorder
            where col_id = v_resultattrid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_sorder)
          values(v_attrcode, v_attrname, v_fomattributeid, v_pathtoparentid, v_sconfigid, v_attrorder);
          select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
        end;
      elsif v_isretrievableinlist = 1 and v_objecttype = 'object' and v_objectsubtype = 'parentBusinessObject' and v_rootonly = 0 then
        insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_sorder)
        values(v_attrcode, v_attrname, v_fomattributeid, v_pathtoparentid, v_srootconfigid, v_attrorder);
        select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
      elsif v_isretrievableinlist = 1 and v_objecttype = 'object' and v_objectsubtype = 'referenceObject'and v_rootonly = 0 then
        begin
          select col_elementid into v_sourceid from tbl_dom_modelcache
          where lower(extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value')) = lower(v_code) and col_type = 'object' and col_subtype = 'referenceObject';
          select col_elementid, extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Target"]/@value') into v_elementid, v_targetid from tbl_dom_modelcache
          where extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Source"]/@value') = v_sourceid and col_type = 'relationship';
          select col_elementid, extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value') into v_targetid, v_targetobjectcode from tbl_dom_modelcache
          where col_elementid = v_targetid and col_type = 'object' and col_subtype in ('businessObject', 'rootBusinessObject');
          select col_id into v_result from tbl_som_config where lower(col_code) = lower(v_modelcode || '_' || v_targetobjectcode);
          exception
          when NO_DATA_FOUND then
          v_result := null;
        end;
        if v_result is not null then
          insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_sorder)
          values(v_attrcode, v_attrname, v_fomattributeid, v_pathtoparentid, v_result, v_attrorder);
          select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
        end if;
      end if;
      if v_issearchable = 1 and v_sconfigid is not null then
        begin
          select col_id into v_searchattrid from tbl_som_searchattr where lower(col_code) = lower(v_attrcode) and col_som_searchattrsom_config = v_sconfigid;
          if v_searchattrid is not null then
            update tbl_som_searchattr set col_code = v_attrcode, col_name = v_attrname, col_som_searchattrfom_attr = v_fomattributeid,
            col_som_searchattrfom_path = v_pathtoparentid, col_som_searchattrsom_config = v_sconfigid, col_sorder = v_attrorder, col_iscaseincensitive = v_isCaseInSensitive, col_islike = v_isLike
            where col_id = v_searchattrid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config, col_sorder, col_iscaseincensitive, col_islike)
          values(v_attrcode, v_attrname, v_fomattributeid, v_pathtoparentid, v_sconfigid, v_attrorder, v_isCaseInSensitive, v_isLike);
          select gen_tbl_som_searchattr.currval into v_searchattrid from dual;
        end;
      elsif v_issearchable = 1 and v_objecttype = 'object' and v_objectsubtype = 'parentBusinessObject' and v_rootonly = 0 then
        insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config, col_sorder)
        values(v_attrcode, v_attrname, v_fomattributeid, v_pathtoparentid, v_srootconfigid, v_attrorder);
        select gen_tbl_som_searchattr.currval into v_searchattrid from dual;
      elsif v_issearchable = 1 and v_objecttype = 'object' and v_objectsubtype = 'referenceObject' and v_rootonly = 0 then
        begin
          select col_elementid into v_sourceid from tbl_dom_modelcache
          where lower(extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value')) = lower(v_code) and col_type = 'object' and col_subtype = 'referenceObject';
          select col_elementid, extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Target"]/@value') into v_elementid, v_targetid from tbl_dom_modelcache
          where extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Source"]/@value') = v_sourceid and col_type = 'relationship';
          select col_elementid, extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value') into v_targetid, v_targetobjectcode from tbl_dom_modelcache
          where col_elementid = v_targetid and col_type = 'object' and col_subtype in ('businessObject', 'rootBusinessObject');
          select col_id into v_result from tbl_som_config where lower(col_code) = lower(v_modelcode || '_' || v_targetobjectcode);
          exception
          when NO_DATA_FOUND then
          v_result := null;
        end;
        if v_result is not null then
          insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config, col_sorder)
          values(v_attrcode, v_attrname, v_fomattributeid, v_pathtoparentid, v_result, v_attrorder);
          select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
        end if;
      end if;
      if v_isupdatable = 1 then
        begin
          select col_id into v_updateattrid from tbl_dom_updateattr where lower(col_code) = lower(v_attrcode) and col_dom_updateattrdom_config = v_editconfigid;
          if v_updateattrid is not null then
            update tbl_dom_updateattr set col_code = v_attrcode, col_name = v_objectname || ' ' || v_attrname, col_mappingname = v_mappingname,
            col_dom_updateattrdom_config = v_editconfigid, col_dom_updateattrfom_attr = v_fomattributeid, col_dom_updateattrfom_path = v_pathtoparentid, col_dorder = v_attrorder
            where col_id = v_updateattrid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_dom_updateattr(col_code, col_name, col_mappingname, col_dom_updateattrdom_config, col_dom_updateattrfom_attr, col_dom_updateattrdom_attr, col_dom_updateattrfom_path, col_dorder)
          values(v_attrcode, v_objectname || ' ' || v_attrname, v_mappingname, v_editconfigid, v_fomattributeid,
          (select da.col_id from tbl_dom_attribute da
           inner join tbl_dom_object do on da.col_dom_attributedom_object = do.col_id
           inner join tbl_dom_model dm on do.col_dom_objectdom_model = dm.col_id
           inner join tbl_dom_config dc on dc.col_dom_configdom_model = dm.col_id
           where dc.col_id = v_editconfigid
           and lower(da.col_code) = lower(v_attrcode)), v_pathtoparentid, v_attrorder);
          select gen_tbl_dom_updateattr.currval into v_updateattrid from dual;
        end;
      end if;
    elsif v_type = 'relationship' then
      if v_source is not null and v_target is not null then
        begin
          select col_id into v_fomrelid from tbl_fom_relationship where lower(col_apicode) = lower(v_relappbasecode);
          if v_fomrelid is not null then
            update tbl_fom_relationship set col_code = upper(v_relcode), col_name = v_relname, col_apicode = v_relappbasecode, col_foreignkeyname = v_relforeignkeyname,
            col_childfom_relfom_object = (select col_id from tbl_fom_object where lower(col_apicode) = lower(v_target)),
            col_parentfom_relfom_object = (select col_id from tbl_fom_object where lower(col_apicode) = lower(v_source))
            where col_id = v_fomrelid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_fom_relationship(col_code, col_name, col_apicode, col_foreignkeyname, col_childfom_relfom_object, col_parentfom_relfom_object)
          values(upper(v_relcode), v_relname, v_relappbasecode, v_relforeignkeyname,
          (select col_id from tbl_fom_object where lower(col_apicode) = lower(v_target)),
          (select col_id from tbl_fom_object where lower(col_apicode) = lower(v_source)));
          select gen_tbl_fom_relationship.currval into v_fomrelid from dual;
        end;
        begin
          select col_id into v_pathtoparentid from tbl_fom_path where lower(col_code) = lower(v_relcode);
          if v_pathtoparentid is not null then
            update tbl_fom_path set col_code = upper(v_relcode), col_name = v_relname, col_fom_pathfom_relationship = v_fomrelid
            where col_id = v_pathtoparentid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_fom_path(col_code, col_name, col_fom_pathfom_relationship, col_jointype)
          values(upper(v_relcode), v_relname, v_fomrelid, 'LEFT');
          select gen_tbl_fom_path.currval into v_pathtoparentid from dual;
        end;
        begin
          select col_id into v_domrelid from tbl_dom_relationship where lower(col_code) = lower(v_targetobjectcode || v_sourceobjectcode)
          and col_childdom_reldom_object in (select col_id from tbl_dom_object where col_dom_objectdom_model = v_modelid)
          and col_parentdom_reldom_object in (select col_id from tbl_dom_object where col_dom_objectdom_model = v_modelid);
          if v_domrelid is not null then
            update tbl_dom_relationship set col_code = upper(v_targetobjectcode || v_sourceobjectcode), col_name = v_targetobjectcode || v_sourceobjectcode,
            col_childdom_reldom_object = (select col_id from tbl_dom_object where lower(col_code) = lower(v_targetobjectcode) and col_dom_objectdom_model = v_modelid),
            col_parentdom_reldom_object = (select col_id from tbl_dom_object where lower(col_code) = lower(v_sourceobjectcode) and col_dom_objectdom_model = v_modelid),
            col_dom_relfom_rel = (select col_id from tbl_fom_relationship where lower(col_apicode) = lower(v_relappbasecode))
            where col_id = v_domrelid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_dom_relationship(col_code, col_name, col_childdom_reldom_object, col_parentdom_reldom_object, col_dom_relfom_rel)
          values(upper(v_targetobjectcode || v_sourceobjectcode), v_targetobjectcode || v_sourceobjectcode,
          (select col_id from tbl_dom_object where lower(col_code) = lower(v_targetobjectcode) and col_dom_objectdom_model = v_modelid),
          (select col_id from tbl_dom_object where lower(col_code) = lower(v_sourceobjectcode) and col_dom_objectdom_model = v_modelid),
          (select col_id from tbl_fom_relationship where lower(col_apicode) = lower(v_relappbasecode)));
          select gen_tbl_dom_relationship.currval into v_domrelid from dual;
        end;
        begin
          select col_id into v_somrelid from tbl_som_relationship where lower(col_code) = lower(v_targetobjectcode || v_sourceobjectcode)
          and col_childsom_relsom_object in (select col_id from tbl_som_object where col_som_objectsom_model = v_smodelid)
          and col_parentsom_relsom_object in (select col_id from tbl_som_object where col_som_objectsom_model = v_smodelid);
          if v_somrelid is not null then
            update tbl_som_relationship set col_code = upper(v_targetobjectcode || v_sourceobjectcode), col_name = v_targetobjectcode || v_sourceobjectcode,
            col_childsom_relsom_object = (select col_id from tbl_som_object where lower(col_code) = lower(v_targetobjectcode) and col_som_objectsom_model = v_smodelid),
            col_parentsom_relsom_object = (select col_id from tbl_som_object where lower(col_code) = lower(v_sourceobjectcode) and col_som_objectsom_model = v_smodelid),
            col_som_relfom_rel = (select col_id from tbl_fom_relationship where lower(col_apicode) = lower(v_relappbasecode))
            where col_id = v_somrelid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_som_relationship(col_code, col_name, col_childsom_relsom_object, col_parentsom_relsom_object, col_som_relfom_rel)
          values(upper(v_targetobjectcode || v_sourceobjectcode), v_targetobjectcode || v_sourceobjectcode,
          (select col_id from tbl_som_object where lower(col_code) = lower(v_targetobjectcode) and col_som_objectsom_model = v_smodelid),
          (select col_id from tbl_som_object where lower(col_code) = lower(v_sourceobjectcode) and col_som_objectsom_model = v_smodelid),
          (select col_id from tbl_fom_relationship where lower(col_apicode) = lower(v_relappbasecode)));
          select gen_tbl_som_relationship.currval into v_somrelid from dual;
        end;
      end if;
    end if;
  end loop;
  --v_result := f_DOM_addParentsToSOM(SModelId => v_smodelid);
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------

end;