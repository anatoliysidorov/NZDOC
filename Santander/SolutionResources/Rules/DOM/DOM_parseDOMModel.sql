declare
  v_input nclob;
  v_rootelementid Integer;
  v_type nvarchar2(255);
  v_subtype nvarchar2(255);
  v_elementid Integer;
  v_objectelementid Integer;
  v_elementcount number;
  v_modelelementcount number;
  v_objectelementcount number;
  v_attrelementcount number;
  v_linkelementcount number;
  v_relelemetcount number;
  v_relationshipcount number;
  v_objectcount Integer;
  ErrorCode number;
  ErrorMessage nvarchar2(255);
  v_DOMModelCode nvarchar2(255);
  v_DOMModelName nvarchar2(255);
  v_DOMModelDesc nvarchar2(255);
  v_RootFOMObject nvarchar2(255);
  v_CaseType nvarchar2(255);
  v_ObjectCode nvarchar2(255);
  v_ObjectName nvarchar2(255);
  v_ObjectDesc nvarchar2(255);
  v_FOMObjectCode nvarchar2(255);
  v_ParentFOMObject nvarchar2(255);
  v_PartyType nvarchar2(255);
  v_IsSharable number;
  v_IsRoot number;
  v_AttrCode nvarchar2(255);
  v_AttrName nvarchar2(255);
  v_AttrDesc nvarchar2(255);
  v_AttrTypeCode nvarchar2(255);
  v_AttrTypeName nvarchar2(255);
  v_attrcount Integer;
  v_rowcount Integer;
  v_source Integer;
  v_sourceobjectcode nvarchar2(255);
  v_target Integer;
  v_targetobjectcode nvarchar2(255);
  v_relid Integer;
  v_relcode nvarchar2(255);
  v_relname nvarchar2(255);
  v_relappbasecode nvarchar2(255);
  v_MappingName nvarchar2(255);
  v_FOMAttribute nvarchar2(255);
  v_ColumnName nvarchar2(255);
  v_IsInsertable number;
  v_IsUpdatable number;
  v_IsRetrievableInDetail number;
  v_IsRetrievableInList number;
  v_IsSearchable number;
  v_IsSystem number;
  v_IsRequired number;
  v_AttrOrder number;
  v_AttrConfig varchar2(32767);
  v_ParamXML varchar2(32767);
  v_result number;
  v_ObjectAppbaseCode nvarchar2(255);
  v_ObjectDBName nvarchar2(255);
  v_AttrAppbaseCode nvarchar2(255);
  v_AttrDBName nvarchar2(255);
  v_path nvarchar2(255);
  v_rowvalue nvarchar2(32767);
  v_AttrCaseSensitive number;
  v_AttrSearchType nvarchar2(255);

  v_errorCode Integer;
  v_errorMessage nvarchar2(255);

begin

  v_errorCode:= 0;
  v_errorMessage := '';

  v_input := :Input;

  delete from tbl_dom_modelcache;
  v_rootelementid := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => '/mxGraphModel/root/mxCell[1]/@id');
  v_DOMModelCode := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => '/mxGraphModel/root/mxCell[1]/@DataModelCode');
  v_type := 'model';
  --dbms_output.put_line('RootElementId = ' || v_rootelementid);
  --dbms_output.put_line('DOMModelCode = ' || v_DOMModelCode);
  v_ParamXML := '<Parameters>';
  v_ParamXML := v_ParamXML || '<Parameter name="Name" value="' || v_DOMModelCode || '"></Parameter>';
  v_ParamXML := v_ParamXML || '<Parameter name="Code" value="' || v_DOMModelCode || '"></Parameter>';
  v_ParamXML := v_ParamXML || '<Parameter name="Desc" value="' || v_DOMModelCode || '"></Parameter>';
  v_ParamXML := v_ParamXML || '<Parameter name="RootFOMObject" value="CASE"></Parameter>';
  v_ParamXML := v_ParamXML || '<Parameter name="CaseType" value="' || v_DOMModelCode || '"></Parameter>';
  v_ParamXML := v_ParamXML || '</Parameters>';
  insert into tbl_dom_modelcache(col_elementid, col_type, col_paramxml)
  values(v_rootelementid, 'model', v_ParamXML);
  v_elementcount := 2;
  v_AttrOrder := 0;
  while (true)
  loop
  v_elementid := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/@id');
  v_type := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/@type');
  v_subtype := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/@subType');
  --dbms_output.put_line('ElementId = ' || v_elementid);
  if v_elementid is null then
    exit;
  end if;
  if v_type = 'object' and (v_subtype = 'businessObject' or v_subtype = 'parentBusinessObject' or v_subtype = 'rootBusinessObject' or v_subtype = 'referenceObject') then
    v_ObjectCode := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/@CODE');
    v_ObjectName := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/@NAME');
    v_ObjectDesc := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/@DESCRIPTION');
    v_ObjectAppbaseCode := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/@AppbaseCode');
    --if v_ObjectCode is not null then
    --dbms_output.put_line('ObjectCode = ' || v_ObjectCode);
    --end if;
    if v_ObjectCode is null then
    v_elementcount := v_elementcount + 1;
    continue;
    end if;
    if v_ObjectAppbaseCode is null then
    v_ObjectAppbaseCode := 'root_' || initcap(v_ObjectCode);
    end if;
    v_objectDBName := 'tbl_' || substr(v_ObjectAppbaseCode, 6, length(v_ObjectAppbaseCode) - 5);
    v_ParentFOMObject := v_ObjectCode;
    v_IsRoot := case
          when v_subtype = 'parentBusinessObject' then 2
          when v_subtype = 'rootBusinessObject' then 1
          when v_subtype = 'businessObject' then 0
          else 0
          end;
    v_IsRoot := case
          when f_UTIL_extract_value_xml(Input => xmltype(v_input),
                       Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/@subType') = 'parentBusinessObject'
          then 2
          when lower(f_UTIL_extract_value_xml(Input => xmltype(v_input),
                       Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/@isRoot')) = 'true'
          then 1
          else 0
          end;
    if v_IsRoot = 1 then
    v_ParentFOMObject := 'CASE';
    end if;
    begin
    select col_code into v_FOMObjectCode from tbl_fom_object where lower(col_apicode) = lower(v_ObjectAppbaseCode);
    exception
    when NO_DATA_FOUND then
    v_FOMObjectCode := upper(v_ObjectCode);
    end;
    v_ParamXML := '<Parameters>';
    v_ParamXML := v_ParamXML || '<Parameter name="Code" value="' || upper(v_ObjectCode) || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="Name" value="' || v_ObjectName || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="Description" value="' || v_ObjectDesc || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="AppbaseCode" value="' || v_ObjectAppbaseCode || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="DBName" value="' || v_ObjectDBName || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="FOMObjectCode" value="' || v_FOMObjectCode || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="ParentFOMObject" value="' || upper(v_ParentFOMObject) || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="PartyType" value="' || upper(v_ObjectCode) || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="IsSharable" value=""></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="IsRoot" value="' || to_char(v_IsRoot) || '"></Parameter>';
    v_ParamXML := v_ParamXML || '</Parameters>';
    insert into tbl_dom_modelcache(col_elementid, col_parentelementid, col_type, col_subtype, col_paramxml, col_appbasecode, col_dbname)
    values(v_elementid, v_rootelementid, 'object', v_subtype, v_paramxml, v_ObjectAppbaseCode, v_ObjectDBName);
    v_objectelementid := v_elementid;
    v_attrelementcount := 1;
    while (true)
    loop
    v_AttrCode := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@CODE');
    if v_AttrCode is null then
      exit;
    end if;
    v_AttrName := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@NAME');
    v_MappingName := upper(v_ObjectCode || '_' || v_AttrCode);
    v_FOMAttribute := v_ObjectCode || '_' || v_AttrCode;
    v_AttrDesc := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@DESCRIPTION');
    v_AttrAppbaseCode := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@AppbaseCode');
    if v_AttrAppbaseCode is null then
      v_AttrAppbaseCode := 'root_' || initcap(v_ObjectCode) || '_' || initcap(v_AttrCode);
    end if;
    begin
      select col_columnname into v_AttrDBName from tbl_fom_attribute where lower(col_apicode) = lower(v_AttrAppbaseCode);
      exception
      when NO_DATA_FOUND then
      v_AttrDBName := 'col_' || lower(v_AttrCode);
    end;
    v_ColumnName := v_AttrDBName;
    v_AttrTypeCode := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@TYPECODE');
    v_AttrTypeName := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@TYPENAME');
    v_IsInsertable := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@IsUseOnCreate');
    v_IsUpdatable := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@IsUseOnUpdate');
    if v_type = 'object' and v_subtype = 'referenceObject' then
      begin
      select ra.col_useoncreate, ra.col_useonupdate
      into v_IsInsertable, v_IsUpdatable
      from tbl_dom_referenceattr ra
      inner join tbl_dom_referenceobject ro on ra.col_dom_refattrdom_refobject = ro.col_id
      inner join tbl_fom_attribute fa on ra.col_dom_refattrfom_attr = fa.col_id
      inner join tbl_fom_object fo on ro.col_dom_refobjectfom_object = fo.col_id
      where lower(fa.col_apicode) = lower(v_AttrAppbaseCode)
      and lower(fo.col_apicode) = lower(v_ObjectAppbaseCode);
      exception
      when NO_DATA_FOUND then
      v_IsInsertable := 0;
      v_IsUpdatable := 0;
      end;
    end if;
    v_IsRetrievableInDetail := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@IsUseOnDetail');
    v_IsRetrievableInList := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                              Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@IsUseOnList');
    v_IsSearchable := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                           Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@IsUseOnSearch');
    v_IsSystem := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                           Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@IsSystem');
    v_IsRequired := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                           Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/@IsRequired');
    v_AttrConfig := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/Object');
    v_AttrOrder := v_AttrOrder + 1;
    if v_subtype = 'referenceObject' then
      v_AttrOrder := v_AttrOrder + 1000;
    end if;
    v_rowcount := 1;
    v_AttrCaseSensitive := null;
    v_AttrSearchType := null;
    while (true)
    loop
      v_path := '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/Array/Object[' || to_char(v_attrelementcount) || ']/Object/Object[' || to_char(v_rowcount) || ']';
      v_rowvalue := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => v_path);
      if v_rowvalue is null then
      exit;
      end if;
      if v_AttrCaseSensitive is null then
      v_AttrCaseSensitive := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => v_path || '/@CASESENSITIVE');
      end if;
      if v_AttrSearchType is null then
      v_AttrSearchType := f_UTIL_extract_value_xml(Input => xmltype(v_input), Path => v_path || '/@SEARCHTYPE');
      end if;
      v_rowcount := v_rowcount + 1;
    end loop;
    if v_AttrCaseSensitive is null then
      v_AttrCaseSensitive := 1;
    end if;
    if v_AttrSearchType is null then
      v_AttrSearchType := 0;
    end if;
    v_ParamXML := '<Parameters>';
    v_ParamXML := v_ParamXML || '<Parameter name="Code" value="' || v_AttrCode || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="Name" value="' || v_AttrName || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="TypeCode" value="' || v_AttrTypeCode || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="TypeName" value="' || v_AttrTypeName || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="Description" value="' || v_AttrDesc || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="AppbaseCode" value="' || v_AttrAppbaseCode || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="DBName" value="' || v_AttrDBName || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="ColumnName" value="' || v_ColumnName || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="CaseSensitive" value="' || v_AttrCaseSensitive || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="SearchType" value="' || v_AttrSearchType || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="MappingName" value="' || v_MappingName || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="FOMAttribute" value="' || v_FOMAttribute || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="IsInsertable" value="' || v_IsInsertable || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="IsUpdatable" value="' || v_IsUpdatable || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="IsRetrievableInDetail" value="' || v_IsRetrievableInDetail || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="IsRetrievableInList" value="' || v_IsRetrievableInList || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="IsSearchable" value="' || v_IsSearchable || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="IsSystem" value="' || v_IsSystem || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="IsRequired" value="' || v_IsRequired || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="Order" value="' || v_AttrOrder || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="AttrConfig">' || '<![CDATA[' || v_AttrConfig || ']]>' || '</Parameter>';
    v_ParamXML := v_ParamXML || '</Parameters>';
    if v_AttrOrder > 1000 then
      v_AttrOrder := v_AttrOrder - 1000;
    end if;
    insert into tbl_dom_modelcache(col_elementid, col_parentelementid, col_type, col_paramxml, col_appbasecode, col_dbname)
    values(v_elementid, v_objectelementid, 'attribute', v_paramxml, v_AttrAppbaseCode, v_AttrDBName);
    v_attrelementcount := v_attrelementcount + 1;
    end loop;
  elsif v_type = 'connection' then
    v_relcode := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/@CODE');
    v_relname := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/@NAME');
    v_relappbasecode := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/Object/@AppbaseCode');
    v_source := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/@source');
    v_target := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                         Path => '/mxGraphModel/root/mxCell[' || to_char(v_elementcount) || ']/@target');
    v_ParamXML := '<Parameters>';
    v_ParamXML := v_ParamXML || '<Parameter name="Code" value="' || v_relcode || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="Name" value="' || v_relname || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="AppbaseCode" value="' || v_relappbasecode || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="ForeignKeyName" value=""></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="Source" value="' || v_source || '"></Parameter>';
    v_ParamXML := v_ParamXML || '<Parameter name="Target" value="' || v_target || '"></Parameter>';
    v_ParamXML := v_ParamXML || '</Parameters>';
    insert into tbl_dom_modelcache(col_elementid, col_parentelementid, col_type, col_paramxml)
    values(v_elementid, v_rootelementid, 'relationship', v_paramxml);
  end if;
  v_elementcount := v_elementcount + 1;
  end loop;

  for rec in (select col_elementid as ElementId, extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value') as Code,
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Name"]/@value') as Name,
        extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="AppbaseCode"]/@value') as AppbaseCode,
        col_parentelementid as ParentElementId, col_paramxml as ParamXML
        from tbl_dom_modelcache
        where col_type = 'relationship')
  loop
  v_relid := rec.ElementId;
  v_relcode := rec.Code;
  v_relname := rec.Name;
  v_relappbasecode := rec.AppbaseCode;
  if v_relappbasecode is null then
    v_relappbasecode := 'root_' || lower(v_relcode);
  end if;
  begin
    select col_elementid,
    extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value')
    into v_source, v_sourceobjectcode
    from tbl_dom_modelcache
    where col_elementid =
    (select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Source"]/@value') from tbl_dom_modelcache where col_elementid = rec.ElementId)
    and col_type = 'object';
    exception
    when NO_DATA_FOUND then
    v_source := null;
  end;
  begin
    select col_elementid,
    extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Code"]/@value')
    into v_target, v_targetobjectcode
    from tbl_dom_modelcache
    where col_elementid =
    (select extractvalue(xmltype(col_paramxml), 'Parameters/Parameter[@name="Target"]/@value') from tbl_dom_modelcache where col_elementid = rec.ElementId)
    and col_type = 'object';
    exception
    when NO_DATA_FOUND then
    v_target := null;
  end;
  update tbl_dom_modelcache
  set col_paramxml = (updatexml(xmltype(col_paramxml), 'Parameters/Parameter[@name="ParentFOMObject"]/@value', cast(v_sourceobjectcode as varchar2(4000)))).getClobval()
  where col_type = 'object'
  and col_subtype in ('businessObject', 'rootBusinessObject')
  and col_elementid = v_target
  and exists(select col_elementid from tbl_dom_modelcache where col_type = 'object' and col_subtype in ('businessObject', 'rootBusinessObject') and col_elementid = v_source);
  update tbl_dom_modelcache
  set col_paramxml = (updatexml(xmltype(col_paramxml), 'Parameters/Parameter[@name="ParentFOMObject"]/@value', cast(v_targetobjectcode as varchar2(4000)))).getClobval()
  where col_type = 'object'
  and col_subtype in ('referenceObject')
  and col_elementid = v_source
  and exists(select col_elementid from tbl_dom_modelcache where col_type = 'object' and col_subtype in ('businessObject', 'rootBusinessObject') and col_elementid = v_target);
  if v_relcode is null and v_relname is null then
    v_relcode := case when length(v_targetobjectcode || v_sourceobjectcode) <= 25 then v_targetobjectcode || v_sourceobjectcode
            else substr(v_targetobjectcode,1,6) || substr(v_targetobjectcode,-6) || substr(v_sourceobjectcode,1,6) || substr(v_sourceobjectcode,-6)
            end;
    v_relname := case when length(v_targetobjectcode || v_sourceobjectcode) <= 25 then initcap(v_targetobjectcode) || initcap(v_sourceobjectcode)
            else substr(initcap(v_targetobjectcode),1,6) || substr(initcap(v_targetobjectcode),-6) || substr(initcap(v_sourceobjectcode),1,6) || substr(initcap(v_sourceobjectcode),-6)
            end;
    update tbl_dom_modelcache
    set col_paramxml = (updatexml(xmltype(col_paramxml),
              'Parameters/Parameter[@name="Code"]/@value', cast(v_relcode as varchar2(4000)),
              'Parameters/Parameter[@name="Name"]/@value', cast(v_relname as varchar2(4000)),
              'Parameters/Parameter[@name="AppbaseCode"]/@value', cast(lower(v_relappbasecode) as varchar2(4000)),
              'Parameters/Parameter[@name="ForeignKeyName"]/@value', 'col_' || cast(lower(v_relcode) as varchar2(4000))).getClobval())
    where col_elementid = rec.ElementId;
  else
    update tbl_dom_modelcache
    set col_paramxml = (updatexml(xmltype(col_paramxml),
              'Parameters/Parameter[@name="AppbaseCode"]/@value', cast(lower(v_relappbasecode) as varchar2(4000)),
              'Parameters/Parameter[@name="ForeignKeyName"]/@value', 'col_' || cast(lower(v_relcode) as varchar2(4000))).getClobval())
    where col_elementid = rec.ElementId;
  end if;
  update tbl_dom_modelcache
  set col_appbasecode = lower(v_relappbasecode), col_dbname = 'col_' || lower(v_relcode)
  where col_elementid = rec.ElementId;
  end loop;

  <<exit_>>
  :errorCode := v_errorCode;
  :errorMessage := v_errorMessage;

exception
  when OTHERS then
   :errorCode := 202;
   :errorMessage := Dbms_Utility.format_error_stack;
   
end;