DECLARE
  v_input   nclob;
  v_modelId number;

  v_typeName     nvarchar2(255);
  v_actionName   nvarchar2(255);
  v_errorMessage nvarchar2(255);
  v_errorCode    number;

  v_tmp_apiCode               nvarchar2(255);
  v_tmp_name                  nvarchar2(255);
  v_tmp_code                  nvarchar2(255);
  v_tmp_DBName                nvarchar2(255);
  v_tmp_description           nvarchar2(500);
  v_tmp_objectType            nvarchar2(255);
  v_tmp_objectApiCode         nvarchar2(255);
  v_tmp_objectTypeCode        nvarchar2(255);
  v_tmp_objectCode            nvarchar2(255);
  v_tmp_dataTypeCode          nvarchar2(255);
  v_tmp_config                nvarchar2(32767);
  v_tmp_isInsertable          number;
  v_tmp_isSearchable          number;
  v_tmp_isUpdatable           number;
  v_tmp_isRetrievableInDetail number;
  v_tmp_isRetrievableInList   number;
  v_tmp_isSystem              number;
  v_tmp_isRequired            number;
  v_tmp_targetApiCode         nvarchar2(255);
  v_tmp_sourceApiCode         nvarchar2(255);
  v_tmp_sourceCode            nvarchar2(255);
  v_tmp_targetCode            nvarchar2(255);

  v_res         number;
  v_message     nclob;
  v_somObjectId number;
  v_searchCode  nvarchar2(255);
  v_searchNewId number;
  v_somModelId  number;
  v_isCreateModel number;
  v_modelCode nvarchar2(255);
  v_modelName nvarchar2(255);
  v_domModelId number;
  v_errorXMLData nclob;

  FUNCTION createXMLError(v_errorMessage IN nvarchar2, 
                          v_typeName IN nvarchar2,
                          v_tmp_apiCode IN nvarchar2)
    RETURN nclob AS
    v_errorXMLMsg nclob;
  BEGIN
    v_errorXMLMsg := v_errorXMLMsg || '<Parameter>';
    v_errorXMLMsg := v_errorXMLMsg || '<ErrorMessage>' || v_errorMessage || '</ErrorMessage>';
    v_errorXMLMsg := v_errorXMLMsg || to_nclob('<ErrorCode>2</ErrorCode>');
    v_errorXMLMsg := v_errorXMLMsg || '<Type>' || lower(v_typeName) || '</Type>';
    v_errorXMLMsg := v_errorXMLMsg || '<AppbaseCode>' || v_tmp_apiCode || '</AppbaseCode>';
    v_errorXMLMsg := v_errorXMLMsg || to_nclob('</Parameter>');
    RETURN v_errorXMLMsg;
  END createXMLError;

BEGIN
  v_input       := :InputXML;
  v_modelId     := :ModelId;
  :ErrorMessage := '';
  :ErrorCode    := 0;
  :ExecutionLog := '';
  :ErrorXMLData := '';
  v_message     := null;
  v_isCreateModel := :IsCreateModel; 
  v_errorXMLData := '';

  if (v_input is null or v_modelId is null) then
    :ErrorCode    := 101;
    :ErrorMessage := 'Input parameters can not be null';
    goto exit_;
  end if;

  SAVEPOINT startPoint;

  begin

    -- Create Model
    if(v_isCreateModel = 1) then
      begin
        select 
          col_code, col_name into
          v_modelCode, v_modelName
        from tbl_mdm_model
        where col_id = v_modelId;
      exception
        when no_data_found then
          v_modelCode := null;
          v_modelName := null;
      end;

      if(v_modelCode is not null and v_modelName is not null) then
        insert into tbl_dom_model(
          col_code,
          col_name,
          col_dom_modelmdm_model
        ) values (
          v_modelCode,
          v_modelName,
          v_modelId
        ) returning col_id into v_domModelId;

        insert into tbl_som_model(
          col_code,
          col_name,
          col_som_modelmdm_model
        ) values (
          v_modelCode,
          v_modelName,
          v_modelId
        );

        insert into tbl_dom_config(
          col_code,
          col_name,
          col_dom_configdom_model,
          col_purpose
        ) values (
          'CREATE_' || v_modelCode,
          'Create ' || v_modelName,
          v_domModelId,
          'CREATE' 
        );

        insert into tbl_dom_config(
          col_code,
          col_name,
          col_dom_configdom_model,
          col_purpose
        ) values (
          'UPDATE_' || v_modelCode,
          'Update ' || v_modelName,
          v_domModelId,
          'EDIT' 
        );
      end if;

    end if;

    for rec IN (select s.TypeName as TypeName,
                      s.ActionName as ActionName,
                      s.ErrorCode as ErrorCode,
                      s.ErrorMessage as ErrorMessage,
                      s.DataBaseName as DataBaseName,
                      s.FullData as FullData,
                      (case
                        when s.TypeName = 'OBJECT' and
                              s.ActionName in ('CREATE', 'MODIFY') then 1
                        when s.TypeName = 'RELATIONSHIP' and
                              s.ActionName in ('CREATE', 'MODIFY') then  2
                        when s.TypeName = 'ATTRIBUTE' and
                              s.ActionName in ('CREATE', 'MODIFY') then  3
                        when s.TypeName = 'OBJECT' and s.ActionName = 'DELETE' then 3
                        when s.TypeName = 'RELATIONSHIP' and
                              s.ActionName = 'DELETE' then 2
                        when s.TypeName = 'ATTRIBUTE' and
                              s.ActionName = 'DELETE' then 1
                      end) as CustomOrder
                  from (select d.extract('Item/Parameter[@name="TypeName"]/@value')
                              .getStringVal() as TypeName,
                              d.extract('Item/Parameter[@name="ActionName"]/@value')
                              .getStringVal() as ActionName,
                              to_number(d.extract('Item/Parameter[@name="ErrorCode"]/@value')
                                        .getStringVal()) as ErrorCode,
                              d.extract('Item/Parameter[@name="ErrorMessage"]/@value')
                              .getStringVal() as ErrorMessage,
                              d.extract('Item/Parameter[@name="DataBaseName"]/@value')
                              .getStringVal() as DataBaseName,
                              d.extract('Item/FullData').getStringVal() as FullData
                          from table(XMLSequence(extract(XMLType(v_input),
                                                        '/Parameters/Item'))) d) s
                order by CustomOrder) loop
      v_errorCode    := rec.ErrorCode;
      v_errorMessage := rec.ErrorMessage;
      v_typeName     := rec.TypeName;
      v_actionName   := rec.ActionName;
      v_tmp_apiCode    := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                            Path  => 'FullData/Parameter[@name="AppbaseCode"]/@value');

      -- If in appBase element wasn't created, we return the error
      if (v_errorCode > 0) then
        -- v_message := f_UTIL_addToMessage(originalMsg => v_message,
        --                                 newMsg      => v_errorMessage);
        if(v_errorXMLData is null) then
          v_errorXMLData := '<Parameters>';
        end if;
        v_errorXMLData := v_errorXMLData || createXMLError(v_errorMessage, v_typeName, v_tmp_apiCode);
        continue;
      end if;
    
      -- If Object - Reference, Base, Root, Parent
      if (v_typeName = 'OBJECT') then
        v_tmp_objectType := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                    Path  => 'FullData/Parameter[@name="TypeCode"]/@value');
        v_tmp_code       := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                    Path  => 'FullData/Parameter[@name="Code"]/@value');
        if v_actionName in ('CREATE', 'MODIFY') then
          -- Init Values                    
          v_tmp_name := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                Path  => 'FullData/Parameter[@name="Name"]/@value');
        
          v_tmp_description := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                        Path  => 'FullData/Parameter[@name="Description"]/@value');
          v_tmp_DBName      := rec.DataBaseName;
        
          v_res := f_mdm_modifyobject(apicode      => v_tmp_apiCode,
                                      code         => v_tmp_code,
                                      description  => v_tmp_description,
                                      errorcode    => v_errorCode,
                                      errormessage => v_errorMessage,
                                      modelid      => v_modelId,
                                      name         => v_tmp_name,
                                      objecttype   => v_tmp_objectType,
                                      tablename    => v_tmp_DBName,
                                      type         => v_actionName);
        else
        
          -- Delete all linked attributes
          for attrRec in (select f.col_apicode AS apiCode, d.col_code AS code
                            from tbl_fom_attribute f
                          inner join tbl_dom_attribute d
                              ON d.col_dom_attrfom_attr = f.col_id
                          where d.col_dom_attributedom_object =
                                (select col_id
                                    from tbl_dom_object
                                  where upper(col_code) = upper(v_tmp_code)
                                    and col_dom_objectdom_model =
                                        (select col_id
                                            from tbl_dom_model
                                          where col_dom_modelmdm_model =
                                                v_modelId))
                            and f.col_fom_attributefom_object =
                                (select col_id
                                    from tbl_fom_object
                                  where upper(col_apicode) =
                                        upper(v_tmp_apiCode))) loop
          
            v_res := f_mdm_deleteattrbycode(apicode        => attrRec.apiCode,
                                            errorcode      => v_errorCode,
                                            errormessage   => v_errorMessage,
                                            modelid        => v_modelId,
                                            code           => attrRec.code,
                                            objectcode     => v_tmp_code,
                                            objectapicode  => v_tmp_apiCode,
                                            objecttypecode => v_tmp_objectType,
                                            calccode       => 0);
          
            if (v_errorCode > 0) then
              v_message := f_UTIL_addToMessage(originalMsg => v_message,
                                              newMsg      => v_errorMessage);
            end if;
          end loop;
        
          v_res := f_mdm_deleteobjectbycode(apicode      => v_tmp_apiCode,
                                            errorcode    => v_errorCode,
                                            errormessage => v_errorMessage,
                                            modelid      => v_modelId,
                                            code         => v_tmp_code,
                                            objecttype   => v_tmp_objectType);
        end if;
      end if;
    
      if (v_typeName = 'ATTRIBUTE') then
        v_tmp_apiCode        := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                        Path  => 'FullData/Parameter[@name="AppbaseCode"]/@value');
        v_tmp_objectApiCode  := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                        Path  => 'FullData/Parameter[@name="ObjectAppbaseCode"]/@value');
        v_tmp_objectTypeCode := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                        Path  => 'FullData/Parameter[@name="ObjectTypeCode"]/@value');
        v_tmp_code           := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                        Path  => 'FullData/Parameter[@name="Code"]/@value');
        v_tmp_objectCode     := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                        Path  => 'FullData/Parameter[@name="ObjectCode"]/@value');
        if v_actionName in ('CREATE', 'MODIFY') then
          -- Init Values                    
          v_tmp_name := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                Path  => 'FullData/Parameter[@name="Name"]/@value');
        
          v_tmp_description := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                        Path  => 'FullData/Parameter[@name="Description"]/@value');
          v_tmp_DBName      := rec.DataBaseName;
        
          v_tmp_dataTypeCode          := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                                  Path  => 'FullData/Parameter[@name="TypeCode"]/@value');      

          v_tmp_isInsertable          := to_number(f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                                            Path  => 'FullData/Parameter[@name="IsInsertable"]/@value'));
          v_tmp_isSearchable          := to_number(f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                                            Path  => 'FullData/Parameter[@name="IsSearchable"]/@value'));
          v_tmp_isUpdatable           := to_number(f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                                            Path  => 'FullData/Parameter[@name="IsUpdatable"]/@value'));
          v_tmp_isRetrievableInDetail := to_number(f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                                            Path  => 'FullData/Parameter[@name="IsRetrievableInDetail"]/@value'));
          v_tmp_isRetrievableInList   := to_number(f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                                            Path  => 'FullData/Parameter[@name="IsRetrievableInList"]/@value'));
          v_tmp_isSystem              := to_number(f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                                            Path  => 'FullData/Parameter[@name="IsSystem"]/@value'));
          v_tmp_isRequired            := to_number(f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                                            Path  => 'FullData/Parameter[@name="IsRequired"]/@value'));

          select 
            extractvalue(xmltype(rec.FullData), 'FullData/Parameter[@name="AttrConfig"]') into v_tmp_config
          from dual;
        
          v_res := f_mdm_modifyattr(apicode               => v_tmp_apiCode,
                                    code                  => v_tmp_code,
                                    columnname            => v_tmp_DBName,
                                    config                => v_tmp_config,
                                    datatypecode          => v_tmp_dataTypeCode,
                                    description           => v_tmp_description,
                                    errorcode             => v_errorCode,
                                    errormessage          => v_errorMessage,
                                    isinsertable          => v_tmp_isInsertable,
                                    isrequired            => v_tmp_isRequired,
                                    isretrievableindetail => v_tmp_isRetrievableInDetail,
                                    isretrievableinlist   => v_tmp_isRetrievableInList,
                                    issearchable          => v_tmp_isSearchable,
                                    issystem              => v_tmp_isSystem,
                                    isupdatable           => v_tmp_isUpdatable,
                                    modelid               => v_modelId,
                                    name                  => v_tmp_name,
                                    objectapicode         => v_tmp_objectApiCode,
                                    objecttypecode        => v_tmp_objectTypeCode,
                                    objectcode            => v_tmp_objectCode,
                                    type                  => v_actionName);
        else
          v_res := f_mdm_deleteattrbycode(apicode        => v_tmp_apiCode,
                                          errorcode      => v_errorCode,
                                          errormessage   => v_errorMessage,
                                          modelid        => v_modelId,
                                          code           => v_tmp_code,
                                          objectcode     => v_tmp_objectCode,
                                          objectapicode  => v_tmp_objectApiCode,
                                          objecttypecode => v_tmp_objectTypeCode,
                                          calccode       => 1);
        end if;
      end if;
    
      if (v_typeName = 'RELATIONSHIP') then
        v_tmp_apiCode := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                  Path  => 'FullData/Parameter[@name="AppbaseCode"]/@value');
        if v_actionName in ('CREATE', 'MODIFY') then
          -- Init Values                    
          v_tmp_name          := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                          Path  => 'FullData/Parameter[@name="Name"]/@value');
          v_tmp_code          := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                          Path  => 'FullData/Parameter[@name="Code"]/@value');
          v_tmp_targetApiCode := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                          Path  => 'FullData/Parameter[@name="TargetAppbaseCode"]/@value');
          v_tmp_sourceApiCode := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                          Path  => 'FullData/Parameter[@name="SourceAppbaseCode"]/@value');
        
          v_tmp_targetCode := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                      Path  => 'FullData/Parameter[@name="TargetCode"]/@value');
          v_tmp_sourceCode := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                      Path  => 'FullData/Parameter[@name="SourceCode"]/@value');
          v_tmp_DBName     := rec.DataBaseName;
        
          v_res := f_mdm_modifyrelation(apicode        => v_tmp_apiCode,
                                        code           => v_tmp_code,
                                        errorcode      => v_errorCode,
                                        errormessage   => v_errorMessage,
                                        foreignkeyname => v_tmp_DBName,
                                        modelid        => v_modelId,
                                        name           => v_tmp_name,
                                        sourceapicode  => v_tmp_sourceApiCode,
                                        targetapicode  => v_tmp_targetApiCode,
                                        targetcode     => v_tmp_targetCode,
                                        sourcecode     => v_tmp_sourceCode,
                                        type           => v_actionName);
        else
          v_res := f_mdm_deleterelationbycode(apicode      => v_tmp_apiCode,
                                              errorcode    => v_errorCode,
                                              errormessage => v_errorMessage,
                                              modelid      => v_modelId);
        end if;
      end if;
    
      if (v_errorCode > 0) then
        -- v_message := f_UTIL_addToMessage(originalMsg => v_message,
        --                                 newMsg      => v_errorMessage);
        if(v_errorXMLData is null) then
          v_errorXMLData := '<Parameters>';
        end if;
        v_errorXMLData := v_errorXMLData || createXMLError(v_errorMessage, v_typeName, v_tmp_apiCode);
      end if;
    
    end loop;

    -- Add new Search Configs
    for rec IN (select s.TypeName     as TypeName,
                      s.ActionName   as ActionName,
                      s.ErrorCode    as ErrorCode,
                      s.ErrorMessage as ErrorMessage,
                      s.FullData     as FullData
                  from (select d.extract('Item/Parameter[@name="TypeName"]/@value')
                              .getStringVal() as TypeName,
                              d.extract('Item/Parameter[@name="ActionName"]/@value')
                              .getStringVal() as ActionName,
                              to_number(d.extract('Item/Parameter[@name="ErrorCode"]/@value')
                                        .getStringVal()) as ErrorCode,
                              d.extract('Item/Parameter[@name="ErrorMessage"]/@value')
                              .getStringVal() as ErrorMessage,
                              d.extract('Item/FullData').getStringVal() as FullData
                          from table(XMLSequence(extract(XMLType(v_input),
                                                        '/Parameters/Item'))) d) s
                where to_number(s.ErrorCode) = 0
                  and s.TypeName = 'OBJECT'
                  and s.ActionName = 'CREATE') loop
      v_tmp_objectType := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                  Path  => 'FullData/Parameter[@name="TypeCode"]/@value');
    
      if (v_tmp_objectType IN ('rootBusinessObject', 'businessObject')) then
        v_tmp_apiCode := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                  Path  => 'FullData/Parameter[@name="AppbaseCode"]/@value');
        v_tmp_name    := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                  Path  => 'FullData/Parameter[@name="Name"]/@value');
        v_tmp_code    := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                  Path  => 'FullData/Parameter[@name="Code"]/@value');
        begin
          select so.col_id, sm.col_code || '_' || v_tmp_code, sm.col_id
            into v_somObjectId, v_searchCode, v_somModelId
            from tbl_som_object so
          inner join tbl_som_model sm
              on sm.col_id = so.col_som_objectsom_model
            and sm.col_som_modelmdm_model = v_modelId
          where col_som_objectfom_object =
                (select col_id
                    from tbl_fom_object
                  where upper(col_apicode) = upper(v_tmp_apiCode));
        exception
          when NO_DATA_FOUND then
            v_somObjectId := null;
        end;
      
        if (v_somObjectId is not null) then
        
          v_res := f_som_createsearchconfig(code         => v_searchCode,
                                            description  => 'Automatically created when Data Model was updated',
                                            errorcode    => v_errorCode,
                                            errormessage => v_errorMessage,
                                            modelid      => v_somModelId,
                                            name         => v_tmp_name,
                                            new_id       => v_searchNewId,
                                            somobjectid  => v_somObjectId);
        
          if (v_errorCode > 0) then
            -- v_message := f_UTIL_addToMessage(originalMsg => v_message,
            --                                 newMsg      => v_errorMessage);
            if(v_errorXMLData is null) then
              v_errorXMLData := '<Parameters>';
            end if;
            v_errorXMLData := v_errorXMLData || createXMLError(v_errorMessage, v_typeName, v_tmp_apiCode);
          end if;
        
        end if;
      
      end if;
    end loop;

    -- Clean all search and from queries for som_config
    update tbl_som_config set
      col_srchqry = null, 
      col_fromqry = null
    where col_id in (select sc.col_id 
                    from tbl_som_config sc
                    inner join tbl_som_model sm on sm.col_id = sc.col_som_configsom_model
                    where sm.col_som_modelmdm_model = v_modelId);

  exception
    when OTHERS then
      ROLLBACK TO startPoint;
      :ErrorMessage := 'Error on update model  - ' ||
                       SUBSTR(SQLERRM, 1, 150);
      :ErrorCode    := 101;
      goto exit_;
  end;

  if (v_message is not null or v_errorXMLData is not null) then
    ROLLBACK TO startPoint;
    :ErrorMessage := 'There are an error on update model.';
    :ErrorCode    := 101;

    if(v_errorXMLData is not null ) then
      v_errorXMLData := v_errorXMLData || to_nclob('</Parameters>');
      :ErrorXMLData :=  dbms_xmlgen.CONVERT(v_errorXMLData);
    end if;

    if(v_message is not null) then
      :ExecutionLog := v_message;
      insert into tbl_mdm_log
        (col_mdm_logmdm_model, col_message)
      values
        (v_modelId,
        '<ErrorMessage>' || :ErrorMessage || '</ErrorMessage>' || '<Input>' ||
        v_input || '</Input>');
    end if;
  end if;

  <<exit_>>
  NULL;


END;