declare
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
  ErrorMessage nvarchar2(2550);
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
  v_modelparamxml varchar2(32767);
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

  v_errorCode Integer;
  v_errorMesssage nvarchar2(255);

begin

  v_errorCode := 0;
  v_errorMesssage := '';
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
    if v_type = 'model' then
      begin
        select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Name"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Desc"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="RootFOMObject"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="CaseType"]/@value')
        into v_modelname, v_modelcode, v_description, v_rootfomobject, v_casetype
        from tbl_dom_modelcache where col_elementid = v_elementid and col_type = 'model';
        exception
        when NO_DATA_FOUND then
        v_modelname := null;
        v_modelcode := null;
        v_description := null;
        v_rootfomobject := null;
        v_casetype := null;
        rollback;
        v_errorCode := 301;
        v_errorMesssage := 'Error when try to parse ''model'' part of xml';
        goto exit_;
      end;
      v_code := v_modelcode;
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
      if v_casetype is not null then
        begin
          select col_id into v_casetypeid from tbl_dict_casesystype where lower(col_code) = lower(v_casetype);
          exception
          when NO_DATA_FOUND then
          v_casetypeid := null;
        end;
      end if;
      if v_modeloverwrite = 1 and v_casetypeid is not null then
        begin
        select col_casesystypemodel into v_cmodelid from tbl_dict_casesystype where col_id = v_casetypeid;
          exception
          when NO_DATA_FOUND then
          v_cmodelid := null;
        end;
        v_result := f_dom_clearDOMModel(ModelId => v_cmodelid, DeleteFOM => 1);
      end if;
    elsif v_type = 'object' then
      begin
        select
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Name"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Desc"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="DBName"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="FOMObjectCode"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="ParentFOMObject"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="PartyType"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsSharable"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsRoot"]/@value')
        into v_objectcode, v_objectname, v_objectdesc, v_objectappbasecode, v_objectdbname, v_fomobjectcode, v_parentfomobject, v_partytype, v_issharable, v_isroot
        from tbl_dom_modelcache where col_elementid = v_elementid and col_type = 'object';
        exception
        when NO_DATA_FOUND then
        v_objectcode := null;
        v_objectname := null;
        v_objectdesc := null;
        v_objectappbasecode := null;
        v_objectdbname := null;
        v_fomobjectcode := null;
        v_parentfomobject := null;
        v_partytype := null;
        v_issharable := null;
        v_isroot := null;
        rollback;
        v_errorCode := 302;
        v_errorMesssage := 'Error when try to parse ''object'' part of xml';
        goto exit_;
      end;
      v_code := v_objectcode;
      begin
        select col_id into v_fomobjectid from tbl_fom_object where lower(col_apicode) = lower(v_objectappbasecode);
        if v_fomobjectid is not null then
          null;
        end if;
        exception
        when NO_DATA_FOUND then
          v_fomobjectid := null;
          insert into tbl_fom_object(col_code, col_name, col_apicode, col_tablename, col_alias, col_xmlalias, col_isadded, col_isdeleted)
          values(upper(v_fomobjectcode), v_objectname, v_objectappbasecode, v_objectdbname, 't_' || v_fomobjectcode, 'xml_' || v_fomobjectcode, 0, 0);
          select gen_tbl_fom_object.currval into v_fomobjectid from dual;
      end;
      begin
        select col_id into v_partytypeid from tbl_dict_partytype where lower(col_code) = lower(v_partytype);
        exception
        when NO_DATA_FOUND then
          v_partytypeid := null;
      end;
    elsif v_type = 'attribute' then
      begin
        select
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Name"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="TypeCode"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="TypeName"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Description"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="DBName"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="ColumnName"]/@value'),
        case when extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="CaseSensitive"]/@value') = 1 then 0 else 1 end,
        case when lower(extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="SearchType"]/@value')) = 'like' then 1 else 0 end,
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="MappingName"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="FOMAttribute"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsInsertable"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsUpdatable"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsRetrievableInDetail"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsRetrievableInList"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsSearchable"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsSystem"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="IsRequired"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Order"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AttrConfig"]')
        into v_attrcode, v_attrname, v_attrtypecode, v_attrtypename, v_attrdesc, v_attrappbasecode, v_attrdbname, v_columnname,
        v_isCaseInSensitive, v_islike, v_mappingname, v_fomattribute,
        v_isinsertable, v_isupdatable, v_isretrievableindetail, v_isretrievableinlist,
        v_issearchable, v_issystem, v_isrequired, v_attrorder, v_attrconfig
        from tbl_dom_modelcache where col_id = rec.ID and col_type = 'attribute';
        exception
        when NO_DATA_FOUND then
        v_attrcode := null;
        v_attrname := null;
        v_attrtypecode := null;
        v_attrtypename := null;
        v_attrdesc := null;
        v_attrappbasecode := null;
        v_attrdbname := null;
        v_columnname := null;
        v_isCaseInSensitive := null;
        v_islike := null;
        v_mappingname := null;
        v_fomattribute := null;
        v_isinsertable := null;
        v_isupdatable := null;
        v_isretrievableindetail := null;
        v_isretrievableinlist := null;
        v_issearchable := null;
        v_issystem := null;
        v_isrequired := null;
        v_attrorder := null;
        v_attrconfig := null;
        rollback;
        v_errorCode := 303;
        v_errorMesssage := 'Error when try to parse ''attribute'' part of xml';
        goto exit_;
      end;

      -- Before Oracle version 12.2, identifiers are not allowed to exceed 30 characters in length.
      if length(v_fomattribute) > 30 then
         v_fomattribute := substr(v_fomattribute,1,15) || substr(v_fomattribute,-15);
      end if;
      if length(v_mappingname) > 30 then
         v_mappingname := substr(v_mappingname,1,15) || substr(v_mappingname,-15);
      end if;

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
          if v_fomattribute is not null then
            begin
              select col_id into v_fomattributeid from tbl_fom_attribute where lower(col_code) = lower(v_fomattribute);
              exception
              when NO_DATA_FOUND then
              if (UPPER(v_fomobjectcode) != 'CASE') then -- temporary!
                begin
                  insert into tbl_fom_attribute(col_code, col_name, col_apicode, col_columnname, col_alias, col_storagetype, col_fom_attributefom_object, col_fom_attributedatatype)
                  values(v_fomattribute, v_attrname, v_attrappbasecode, v_columnname, v_fomattribute, 'SIMPLE', v_fomobjectid,
                  (select col_id from tbl_dict_datatype where lower(col_code) = lower(v_attrtypecode)));
                  select gen_tbl_fom_attribute.currval into v_fomattributeid from dual;
                end;
              end if;
            end;
          end if;
      end;
    elsif v_type = 'relationship' then
      begin
        select
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Name"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="ForeignKeyName"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Source"]/@value'),
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Target"]/@value')
        into v_relcode, v_relname, v_relappbasecode, v_relforeignkeyname, v_sourceid, v_targetid
        from tbl_dom_modelcache where col_id = rec.ID and col_type = 'relationship';
        exception
        when NO_DATA_FOUND then
        v_relcode := null;
        v_relname := null;
        v_relappbasecode := null;
        v_relforeignkeyname := null;
        v_sourceid := null;
        v_targetid := null;
        rollback;
        v_errorCode := 304;
        v_errorMesssage := 'Error when try to parse ''relationship'' part of xml';
        goto exit_;
      end;
      begin
        select col_paramxml into v_relparamxml from tbl_dom_modelcache where col_elementid = v_sourceid and col_type = 'object';
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
      if v_source is not null and v_target is not null then
        begin
          select col_id into v_fomrelid from tbl_fom_relationship where lower(col_apicode) = lower(v_relappbasecode);
          if v_fomrelid is not null then
            null;
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
            col_name = v_objectname,
            col_description = 'Automatically created when Data Model was updated',
            col_som_configfom_object = (select col_id from tbl_fom_object where lower(col_code) = lower(v_code)),
            col_som_configsom_model = v_smodelid
            where col_id = v_sconfigid;
          end if;
          exception
          when NO_DATA_FOUND then
          insert into tbl_som_config(col_code, col_name, col_description, col_som_configfom_object, col_som_configsom_model, col_isshowinnavmenu)
          values((select col_code from tbl_som_model where col_id = v_smodelid) || '_' || v_code,
                v_objectname,
                'Automatically created when Data Model was updated',
                (select col_id from tbl_fom_object where lower(col_code) = lower(v_code)), v_smodelid,
        (case when v_subtype = 'rootBusinessObject' then 1 else 0 end));
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
      elsif v_subtype = 'referenceObject' then
        begin
          select sc.col_id into v_result from tbl_som_config sc inner join tbl_fom_object fo on sc.col_som_configfom_object = fo.col_id where fo.col_code = v_parentfomobject;
          exception
          when NO_DATA_FOUND then
          v_result := null;
        end;
        v_result := f_RDR_AddRefObjRdrsToSResAttr(FomObjectCode => v_fomobjectcode, ObjectName => v_objectname, PathToParentId => v_pathtoparentid, SConfigId => v_result);
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
      v_pathtoparentid := f_dom_createFOMPath(ObjectCode => v_code, ParentObjectCode => v_parentfomobject);

      -- don't change Attribute Code for Parent Business Object - FOM_Attributes.col_code has correct Code for Parent BO (for example: CASE_ID, CASE_SUMMARY)
      if (v_objectsubtype = 'parentBusinessObject') then
        v_attrcode := v_attrcode;
      else
        v_attrcode := v_code || '_' || v_attrcode;
        if length(v_attrcode) > 30 then
           v_attrcode := substr(v_attrcode,1,15) || substr(v_attrcode,-15);
        end if;
      end if;

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
            col_som_attrfom_attr, col_som_attributesom_object, col_config, col_issystem, col_som_attributerenderobject, col_som_attributerefobject)
            values(v_attrcode, v_attrname, v_attrdesc, v_isinsertable, v_isupdatable, v_issearchable, v_isretrievableindetail, v_isretrievableinlist, v_attrorder,
            v_fomattributeid, (select col_id from tbl_som_object where lower(col_code) = lower(v_code) and col_som_objectsom_model = v_smodelid), v_attrconfig, v_issystem,
            (case when lower(v_attrtypecode) in ('createdby', 'createddate', 'modifiedby', 'modifieddate') then
            case when lower(v_objectappbasecode) = lower('root_Case') then
            (select ro.col_id from tbl_dom_renderobject ro inner join tbl_dict_datatype dt on ro.col_dom_renderobjectdatatype = dt.col_id where lower(ro.col_code) = lower('CASE' || v_attrtypecode))
            else
            (select ro.col_id from tbl_dom_renderobject ro inner join tbl_dict_datatype dt on ro.col_dom_renderobjectdatatype = dt.col_id where lower(ro.col_code) = lower(v_attrtypecode))
            end
            when v_objectsubtype = 'referenceObject' then
            (select ro.col_id from tbl_dom_renderobject ro inner join tbl_dom_referenceobject refo on ro.col_renderobjectfom_object = refo.col_dom_refobjectfom_object
            inner join tbl_fom_object fo on ro.col_renderobjectfom_object = fo.col_id
            where lower(col_apicode) = lower(v_objectappbasecode))
            when lower(v_objectappbasecode) = lower('root_Case') and v_objectsubtype = 'parentBusinessObject' and lower(v_attrcode) = lower('CASE_CASEID') then
            (select col_id from tbl_dom_renderobject where lower(col_code) = lower('CASEID'))
            else null end),
            (select refo.col_id from tbl_dom_referenceobject refo inner join tbl_fom_object fo on refo.col_dom_refobjectfom_object = fo.col_id where lower(fo.col_apicode) = lower(v_objectappbasecode)));
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
          if v_attrtypecode = 'CREATEDBY' or v_attrtypecode = 'CREATEDDATE' or v_attrtypecode = 'MODIFIEDBY' or v_attrtypecode = 'MODIFIEDDATE' then
            v_result := f_RDR_AddBORdrToSResAttr(AttrTypeCode => v_attrtypecode, FomAttributeId => v_fomattributeid, PathId => v_pathtoparentid, SConfigId => v_sconfigid);
          else
            insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrsom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_sorder)
            values(v_attrcode, v_attrname, v_fomattributeid, v_somattrid, v_pathtoparentid, v_sconfigid, v_attrorder);
          end if;
          select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
        end;
      elsif v_isretrievableinlist = 1 and v_objecttype = 'object' and v_objectsubtype = 'parentBusinessObject' and v_rootonly = 0 then
        IF (UPPER(v_rootfomobject) = 'CASE') THEN
           IF (upper(v_attrcode) = 'CASE_SUMMARY' or upper(v_attrcode) = 'SUMMARY') THEN
             if v_pathtoparentid is null then
               begin
                 select col_som_configfom_object into v_objectid from tbl_som_config where col_id = v_srootconfigid;
                 exception
                 when NO_DATA_FOUND then
                 v_objectid := null;
               end;
               if v_objectid is not null then
                 begin
                   select col_code into v_objectcode from tbl_fom_object where col_id = v_objectid;
                   exception
                   when NO_DATA_FOUND then
                   v_objectcode := null;
                 end;
                 if v_objectcode is not null then
                   v_pathtoparentid := f_dom_createFOMPath(ObjectCode => v_objectcode, ParentObjectCode => 'CASE');
                 end if;
               end if;
             end if;
             insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrsom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_sorder)
             values(v_attrcode, v_attrname, v_fomattributeid, v_somattrid, v_pathtoparentid, v_srootconfigid, v_attrorder);
             select gen_tbl_som_resultattr.currval into v_resultattrid from dual;
           END IF;
        END IF;
      elsif v_isretrievableinlist = 1 and v_objecttype = 'object' and v_objectsubtype = 'referenceObject' and v_rootonly = 0 then
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
          insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrsom_attr, col_som_resultattrfom_path, col_som_resultattrrefobject, col_som_resultattrsom_config, col_sorder)
          values(v_attrcode, v_attrname, v_fomattributeid, v_somattrid, v_pathtoparentid,
          (select refo.col_id from tbl_dom_referenceobject refo inner join  tbl_fom_object fo on refo.col_dom_refobjectfom_object = fo.col_id where lower(fo.col_apicode) = lower(v_objectappbasecode)),
          v_result, v_attrorder);
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
          if v_attrtypecode = 'CREATEDBY' or v_attrtypecode = 'CREATEDDATE' or v_attrtypecode = 'MODIFIEDBY' or v_attrtypecode = 'MODIFIEDDATE' then
            v_result := f_RDR_AddBORdrToSSrchAttr(AttrTypeCode => v_attrtypecode, FomAttributeId => v_fomattributeid, PathId => v_pathtoparentid, SConfigId => v_sconfigid);
          else
            insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config, col_sorder, col_iscaseincensitive, col_islike)
            values(v_attrcode, v_attrname, v_fomattributeid, v_pathtoparentid, v_sconfigid, v_attrorder, v_isCaseInSensitive, v_isLike);
          end if;
          select gen_tbl_som_searchattr.currval into v_searchattrid from dual;
        end;
      elsif v_issearchable = 1 and v_objecttype = 'object' and v_objectsubtype = 'parentBusinessObject' and v_rootonly = 0 then
        IF (UPPER(v_rootfomobject) = 'CASE') THEN
            IF (upper(v_attrcode) = 'CASE_SUMMARY') THEN
             insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config, col_sorder)
             values(v_attrcode, v_attrname, v_fomattributeid, v_pathtoparentid, v_srootconfigid, v_attrorder);
             select gen_tbl_som_searchattr.currval into v_searchattrid from dual;
           END IF;
        END IF;
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
          insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrfom_path, col_som_searchattrrefobject, col_som_searchattrsom_config, col_sorder)
          values(v_attrcode, v_attrname, v_fomattributeid, v_pathtoparentid,
          (select refo.col_id from tbl_dom_referenceobject refo inner join  tbl_fom_object fo on refo.col_dom_refobjectfom_object = fo.col_id where lower(fo.col_apicode) = lower(v_objectappbasecode)),
          v_result, v_attrorder);
          select gen_tbl_som_searchattr.currval into v_searchattrid from dual;
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
  begin
    select col_som_configfom_object into v_result from tbl_som_config where col_id = v_srootconfigid;
    exception
    when NO_DATA_FOUND then
    v_result := null;
  end;
  v_result := f_RDR_AddCaseRdrsToSResAttr(RootFomObject => v_result, SConfigId => v_srootconfigid);
  v_result := f_RDR_NormalizeSomResAttrOrder(CaseTypeId => v_casetypeid);
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  <<exit_>>
    :errorCode := v_errorCode;
    :errorMessage := v_errorMesssage;
    --null;
  exception
    when OTHERS then
      rollback;
      :errorCode := 305;
      :errorMessage := Dbms_Utility.format_error_stack;
end;