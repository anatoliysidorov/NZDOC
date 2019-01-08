declare
  v_type                  nvarchar2(20);
  v_modelId               number;
  v_apiCode               nvarchar2(255);
  v_name                  nvarchar2(255);
  v_code                  nvarchar2(255);
  v_columName             nvarchar2(255);
  v_description           nvarchar2(500);
  v_objectApiCode         nvarchar2(255);
  v_objectTypeCode        nvarchar2(255);
  v_dataTypeCode          nvarchar2(255);
  v_config                nvarchar2(32767);
  v_isInsertable          number;
  v_isSearchable          number;
  v_isUpdatable           number;
  v_isRetrievableInDetail number;
  v_isRetrievableInList   number;
  v_isSystem              number;
  v_isRequired            number;
  v_domInsertAttrId         number;
  v_domUpdateAttrId         number;

  v_attrFormatCode nvarchar2(255);
  v_fomAttrId      number;
  v_renderObjectId number;
  v_typeCode       nvarchar2(255);
  v_somObjectId    number;
  v_domObjectId    number;
  v_objectCode     nvarchar2(255);
  v_attrOrder      number;
  v_isRoot        number;
begin
  -- Init
  v_type                  := :Type;
  v_modelId               := :ModelId;
  v_apiCode               := :ApiCode;
  v_name                  := :Name;
  v_code                  := :Code;
  v_description           := :Description;
  v_columName             := :ColumnName;
  v_objectApiCode         := :ObjectApiCode;
  v_objectTypeCode        := :ObjectTypeCode;
  v_objectCode            := :ObjectCode;
  v_dataTypeCode          := :DataTypeCode;
  v_config                := :Config;
  v_isInsertable          := :IsInsertable;
  v_isSearchable          := :IsSearchable;
  v_isUpdatable           := :IsUpdatable;
  v_isRetrievableInDetail := :IsRetrievableInDetail;
  v_isRetrievableInList   := :IsRetrievableInList;
  v_isSystem              := :IsSystem;
  v_isRequired            := :IsRequired;
  :ErrorMessage           := '';
  :ErrorCode              := 0;
  v_attrOrder             := 0;
  v_isRoot                := 0;
  
  if (v_modelId is null or v_apiCode is null) then
    :ErrorCode    := 101;
    :ErrorMessage := 'Input parameters can not be null';
    goto exit_;
  end if;

  if (v_objectTypeCode = 'parentBusinessObject') then
    v_attrFormatCode := v_code;
  else
    -- Calculate correct format code
    v_attrFormatCode := v_objectCode || '_' || v_code;
    v_attrFormatCode := upper(v_attrFormatCode);
    if length(v_attrFormatCode) > 30 then
      v_attrFormatCode := substr(v_attrFormatCode, 1, 15) ||
                          substr(v_attrFormatCode, -15);
    end if;
  end if;

  begin
  
    begin
      select d.col_id, nvl(d.col_isroot, 0)
        into v_domObjectId, v_isRoot
        from tbl_fom_object f
       inner join tbl_dom_object d
          on d.col_dom_objectfom_object = f.col_id
       where upper(f.col_apicode) = upper(v_objectApiCode)
         and upper(d.col_code) = upper(v_objectCode)
         and d.col_dom_objectdom_model =
             (select col_id
                from tbl_dom_model
               where col_dom_modelmdm_model = v_modelId);
    exception
      when no_data_found then
        :ErrorMessage := 'Error on ' || (case when v_type = 'MODIFY' then 'modify' else 'create' end) || ' attribute with code - ' || v_apiCode || ': ';
        :ErrorMessage := :ErrorMessage || 'Object is not found';
        :ErrorCode    := 101;
        goto exit_;
    end;
  
    begin
      select s.col_id
        into v_somObjectId
        from tbl_fom_object f
       inner join tbl_som_object s
          on s.col_som_objectfom_object = f.col_id
       where upper(f.col_apicode) = upper(v_objectApiCode)
         and upper(s.col_code) = upper(v_objectCode)
         and s.col_som_objectsom_model =
             (select col_id
                from tbl_som_model
               where col_som_modelmdm_model = v_modelId);
    exception
      when no_data_found then
        :ErrorMessage := 'Error on ' || (case when v_type = 'MODIFY' then 'modify' else 'create' end) || ' attribute with code - ' || v_apiCode || ': ';
        :ErrorMessage := :ErrorMessage || 'Object is not found';
        :ErrorCode    := 101;
        goto exit_;
    end;

    -- For root order is 100
    -- For none root order is 200
    -- For reference object order is 1000
    if (v_objectTypeCode = 'referenceObject') then
      v_attrOrder := 1000;
    else
      if(v_isRoot = 1) then
        v_attrOrder := 100;
      else
        v_attrOrder := 200;
      end if;
    end if;   
  
    if v_type = 'CREATE' then
    
      -- Create tbl_fom_attribute
      if (v_objectTypeCode IN ('rootBusinessObject', 'businessObject')) then
        insert into tbl_fom_attribute
          (col_code,
           col_name,
           col_apicode,
           col_columnname,
           col_alias,
           col_storagetype,
           col_fom_attributefom_object,
           col_fom_attributedatatype)
        values
          (v_attrFormatCode,
           v_name,
           v_apiCode,
           v_columName,
           -- temporary fix, todo remove it
           (case when lower(v_columName) = 'col_id' then 'ID' else to_char(v_attrFormatCode) end),
           'SIMPLE',
           (select col_id
              from tbl_fom_object
             where upper(col_apicode) = upper(v_objectApiCode)),
           (select col_id
              from tbl_dict_datatype
             where upper(col_code) = upper(v_dataTypeCode)))
        returning col_id into v_fomAttrId;
      else
        select col_id
          into v_fomAttrId
          from tbl_fom_attribute
         where upper(col_apicode) = upper(v_apiCode);
      end if;
    
      --Create tbl_dom_attribute
      insert into tbl_dom_attribute
        (col_code,
         col_name,
         col_description,
         col_isinsertable,
         col_isupdatable,
         col_issearchable,
         col_isretrievableindetail,
         col_isretrievableinlist,
         col_dom_attrfom_attr,
         col_dom_attributedom_object,
         col_config,
         col_issystem,
         col_isrequired,
         col_dorder)
      values
        (v_attrFormatCode,
         v_name,
         v_description,
         v_isInsertable,
         v_isUpdatable,
         v_isSearchable,
         v_isRetrievableInDetail,
         v_isRetrievableInList,
         v_fomAttrId,
         v_domObjectId,
         v_config,
         v_isSystem,
         v_isRequired,
         v_attrOrder);
    
      --Calculate RenderObject.col_id    
      select (case
               when lower(v_typeCode) in
                    ('createdby',
                     'createddate',
                     'modifiedby',
                     'modifieddate') then
                case
                  when lower(v_objectApiCode) = lower('root_Case') then
                   (select ro.col_id
                      from tbl_dom_renderobject ro
                     inner join tbl_dict_datatype dt
                        on ro.col_dom_renderobjectdatatype = dt.col_id
                     where lower(ro.col_code) = lower('CASE' || v_typeCode))
                  else
                   (select ro.col_id
                      from tbl_dom_renderobject ro
                     inner join tbl_dict_datatype dt
                        on ro.col_dom_renderobjectdatatype = dt.col_id
                     where lower(ro.col_code) = lower(v_typeCode))
                end
               when v_objectTypeCode = 'referenceObject' then
                (select ro.col_id
                   from tbl_dom_renderobject ro
                  inner join tbl_dom_referenceobject refo
                     on ro.col_renderobjectfom_object =
                        refo.col_dom_refobjectfom_object
                  inner join tbl_fom_object fo
                     on ro.col_renderobjectfom_object = fo.col_id
                  where lower(col_apicode) = lower(v_objectApiCode))
               when lower(v_objectApiCode) = lower('root_Case') and
                    v_objectTypeCode = 'parentBusinessObject' and
                    lower(v_code) = lower('CASE_CASEID') then
                (select col_id
                   from tbl_dom_renderobject
                  where lower(col_code) = lower('CASEID'))
               else
                null
             end)
        into v_renderObjectId
        from dual;
    
      --Create tbl_dom_attribute
      insert into tbl_som_attribute
        (col_code,
         col_name,
         col_description,
         col_isinsertable,
         col_isupdatable,
         col_issearchable,
         col_isretrievableindetail,
         col_isretrievableinlist,
         col_som_attrfom_attr,
         col_som_attributesom_object,
         col_config,
         col_issystem,
         col_som_attributerenderobject,
         col_som_attributerefobject,
         col_dorder)
      values
        (v_attrFormatCode,
         v_name,
         v_description,
         v_isInsertable,
         v_isUpdatable,
         v_isSearchable,
         v_isRetrievableInDetail,
         v_isRetrievableInList,
         v_fomAttrId,
         v_somObjectId,
         v_config,
         v_isSystem,
         v_renderObjectId,
         (select refo.col_id
            from tbl_dom_referenceobject refo
           inner join tbl_fom_object fo
              on refo.col_dom_refobjectfom_object = fo.col_id
           where lower(fo.col_apicode) = lower(v_objectApiCode)),
          v_attrOrder);
    
      -- Create tbl_dom_insertattr
      if (v_isInsertable = 1) then
        insert into tbl_dom_insertattr
          (col_code,
           col_name,
           col_mappingname,
           col_dom_insertattrdom_config,
           col_dom_insertattrfom_attr,
           col_dom_insertattrdom_attr,
           col_dom_insertattrfom_path,
           col_dorder)
        values
          (v_attrFormatCode,
           v_name,
           upper(v_attrFormatCode),
           (select dc.col_id
              from tbl_dom_config dc
             where dc.col_dom_configdom_model =
                   (select col_id
                      from tbl_dom_model
                     where col_dom_modelmdm_model = v_modelId)
               and dc.col_purpose = 'CREATE'),
           v_fomAttrId,
           (select d.col_id
              from tbl_dom_attribute d
             where d.col_dom_attrfom_attr = v_fomAttrId
               and d.col_dom_attributedom_object = v_domObjectId
               and upper(col_code) = upper(v_attrFormatCode)),
           (select d.col_dom_object_pathtoprntext
              from tbl_dom_object d
             where d.col_id = v_domObjectId),
            v_attrOrder);
      end if;
    
      -- Create v_isUpdatable
      if (v_isUpdatable = 1) then
        insert into tbl_dom_updateattr
          (col_code,
           col_name,
           col_mappingname,
           col_dom_updateattrdom_config,
           col_dom_updateattrfom_attr,
           col_dom_updateattrdom_attr,
           col_dom_updateattrfom_path,
           col_dorder)
        values
          (v_attrFormatCode,
           v_name,
           upper(v_attrFormatCode),
           (select dc.col_id
              from tbl_dom_config dc
             where dc.col_dom_configdom_model =
                   (select col_id
                      from tbl_dom_model
                     where col_dom_modelmdm_model = v_modelId)
               and dc.col_purpose = 'EDIT'),
           v_fomAttrId,
           (select d.col_id
              from tbl_dom_attribute d
             where d.col_dom_attrfom_attr = v_fomAttrId
               and d.col_dom_attributedom_object = v_domObjectId
               and upper(col_code) = upper(v_attrFormatCode)),
           (select d.col_dom_object_pathtoprntext
              from tbl_dom_object d
             where d.col_id = v_domObjectId),
            v_attrOrder);
      end if;
    elsif v_type = 'MODIFY' then
    
      select col_id
        into v_fomAttrId
        from tbl_fom_attribute
       where upper(col_apicode) = upper(v_apiCode);
    
      if (v_objectTypeCode IN ('rootBusinessObject', 'businessObject')) then
        update tbl_fom_attribute
           set col_name = v_name,
               col_fom_attributedatatype = (select col_id
                                            from tbl_dict_datatype
                                            where upper(col_code) = upper(v_dataTypeCode))
         where col_id = v_fomAttrId;
      end if;
    
      update tbl_dom_attribute
         set col_name                  = v_name,
             col_description           = v_description,
             col_isinsertable          = v_isInsertable,
             col_isupdatable           = v_isUpdatable,
             col_issearchable          = v_isSearchable,
             col_isretrievableindetail = v_isRetrievableInDetail,
             col_isretrievableinlist   = v_isRetrievableInList,
             col_config                = v_config,
             col_isrequired            = v_isRequired
       where col_dom_attributedom_object = v_domObjectId
         and upper(col_code) = upper(v_attrFormatCode)
         and col_dom_attrfom_attr = v_fomAttrId;
    
      update tbl_som_attribute
         set col_name                  = v_name,
             col_description           = v_description,
             col_isinsertable          = v_isInsertable,
             col_isupdatable           = v_isUpdatable,
             col_issearchable          = v_isSearchable,
             col_isretrievableindetail = v_isRetrievableInDetail,
             col_isretrievableinlist   = v_isRetrievableInList,
             col_config                = v_config
       where col_som_attributesom_object = v_somObjectId
         and upper(col_code) = upper(v_attrFormatCode)
         and col_som_attrfom_attr = v_fomAttrId;
    
      begin
        select col_id into v_domInsertAttrId
        from tbl_dom_insertattr
        where col_dom_insertattrfom_attr = v_fomAttrId
              and upper(col_code) = upper(v_attrFormatCode)
              and col_dom_insertattrdom_config =
                  (select dc.col_id
                    from tbl_dom_config dc
                    where dc.col_dom_configdom_model =
                          (select col_id
                            from tbl_dom_model
                            where col_dom_modelmdm_model = v_modelId)
                      and dc.col_purpose = 'CREATE');
      exception when no_data_found then
        v_domInsertAttrId := null;
      end;

      if (v_isInsertable = 1) then
        if(v_domInsertAttrId is null) then
          insert into tbl_dom_insertattr
          (
            col_code,
            col_name,
            col_mappingname,
            col_dom_insertattrdom_config,
            col_dom_insertattrfom_attr,
            col_dom_insertattrdom_attr,
            col_dom_insertattrfom_path,
            col_dorder
           )
        values
          (
            v_attrFormatCode,
            v_name,
            upper(v_attrFormatCode),
            (select dc.col_id
                from tbl_dom_config dc
              where dc.col_dom_configdom_model =
                    (select col_id
                        from tbl_dom_model
                      where col_dom_modelmdm_model = v_modelId)
                and dc.col_purpose = 'CREATE'),
            v_fomAttrId,
            (select d.col_id
                from tbl_dom_attribute d
              where d.col_dom_attrfom_attr = v_fomAttrId
                and d.col_dom_attributedom_object = v_domObjectId
                and upper(col_code) = upper(v_attrFormatCode)),
            (select d.col_dom_object_pathtoprntext
                from tbl_dom_object d
              where d.col_id = v_domObjectId),
            v_attrOrder
          );
        else
          update tbl_dom_insertattr
            set col_name = v_name
          where col_id = v_domInsertAttrId;
        end if;       
      else
        if(v_domInsertAttrId is not null) then
          delete from tbl_dom_insertattr
          where col_id = v_domInsertAttrId;
        end if;
      end if;

      begin
        select col_id into v_domUpdateAttrId
        from tbl_dom_updateattr
        where col_dom_updateattrfom_attr = v_fomAttrId
              and upper(col_code) = upper(v_attrFormatCode)
              and col_dom_updateattrdom_config =
                  (select dc.col_id
                      from tbl_dom_config dc
                    where dc.col_dom_configdom_model =
                          (select col_id
                              from tbl_dom_model
                            where col_dom_modelmdm_model = v_modelId)
                      and dc.col_purpose = 'EDIT');
      exception when no_data_found then
        v_domUpdateAttrId := null;
      end;

      if (v_isUpdatable = 1) then
        if(v_domUpdateAttrId is null) then
          insert into tbl_dom_updateattr
          (
            col_code,
            col_name,
            col_mappingname,
            col_dom_updateattrdom_config,
            col_dom_updateattrfom_attr,
            col_dom_updateattrdom_attr,
            col_dom_updateattrfom_path,
            col_dorder
          )
        values
          (
            v_attrFormatCode,
            v_name,
            upper(v_attrFormatCode),
            (select dc.col_id
              from tbl_dom_config dc
              where dc.col_dom_configdom_model =
                    (select col_id
                      from tbl_dom_model
                      where col_dom_modelmdm_model = v_modelId)
                and dc.col_purpose = 'EDIT'),
            v_fomAttrId,
            (select d.col_id
              from tbl_dom_attribute d
              where d.col_dom_attrfom_attr = v_fomAttrId
                and d.col_dom_attributedom_object = v_domObjectId
                and upper(col_code) = upper(v_attrFormatCode)),
            (select d.col_dom_object_pathtoprntext
              from tbl_dom_object d
              where d.col_id = v_domObjectId),
            v_attrOrder
          );
        else 
          update tbl_dom_updateattr
           set col_name = v_name
          where col_id = v_domUpdateAttrId;
        end if;
       
      else
        if(v_domUpdateAttrId is not null) then
          delete from tbl_dom_updateattr
          where col_id = v_domUpdateAttrId;
        end if;
      end if;

      if (v_isSearchable = 1) then
        update tbl_som_searchattr
           set col_name = v_name
         where col_som_searchattrfom_attr = v_fomAttrId
           and upper(col_code) = upper(v_attrFormatCode)
           and col_som_searchattrsom_config in
               (select sc.col_id
                  from tbl_som_model sm
                 inner join tbl_som_config sc
                    on sm.col_id = sc.col_som_configsom_model
                 where sm.col_som_modelmdm_model = v_modelId);
      else
        delete from tbl_som_searchattr
         where col_som_searchattrfom_attr = v_fomAttrId
           and upper(col_code) = upper(v_attrFormatCode)
           and col_som_searchattrsom_config in
               (select sc.col_id
                  from tbl_som_model sm
                 inner join tbl_som_config sc
                    on sm.col_id = sc.col_som_configsom_model
                 where sm.col_som_modelmdm_model = v_modelId);
      end if;
    
      if (v_isRetrievableInList = 1) then
        update tbl_som_resultattr
           set col_name = v_name
         where col_som_resultattrfom_attr = v_fomAttrId
           and upper(col_code) = upper(v_attrFormatCode)
           and col_som_resultattrsom_config in
               (select sc.col_id
                  from tbl_som_model sm
                 inner join tbl_som_config sc
                    on sm.col_id = sc.col_som_configsom_model
                 where sm.col_som_modelmdm_model = v_modelId);
      else
        delete from tbl_som_resultattr
         where col_som_resultattrfom_attr = v_fomAttrId
           and upper(col_code) = upper(v_attrFormatCode)
           and col_som_resultattrsom_config in
               (select sc.col_id
                  from tbl_som_model sm
                 inner join tbl_som_config sc
                    on sm.col_id = sc.col_som_configsom_model
                 where sm.col_som_modelmdm_model = v_modelId);
      end if;
    
    end if;
  
  exception
    when OTHERS then
      :ErrorMessage := 'Error on ' || (case
                         when v_type = 'MODIFY' then
                          'modify'
                         else
                          'create'
                       end) || ' attribute with code - ' || v_apiCode || ' ' ||
                       SUBSTR(SQLERRM, 1, 150);
      :ErrorCode    := 101;
  end;
  
  <<exit_>>
  NULL;
end;