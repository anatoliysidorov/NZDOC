declare
  v_type        nvarchar2(20);
  v_modelId     number;
  v_apiCode     nvarchar2(255);
  v_name        nvarchar2(255);
  v_code        nvarchar2(255);
  v_tableName   nvarchar2(255);
  v_isRoot      number;
  v_description nvarchar2(255);
  v_objectType  nvarchar2(255);

  v_fomObjectId number;
  v_domObjectId number;
  v_somObjectId number;
  v_renderControlId number;
  v_refoId number;
  v_roId number;
  v_refAttrCode nvarchar2(255);
begin
  -- Init
  v_type        := :Type;
  v_modelId     := :ModelId;
  v_apiCode     := :ApiCode;
  v_name        := :Name;
  v_code        := :Code;
  v_tableName   := :TableName;
  v_description := :Description;
  v_objectType  := :ObjectType;
  :ErrorMessage := '';
  :ErrorCode    := 0;
  
  if (v_modelId is null or v_apiCode is null) then
    :ErrorCode    := 101;
    :ErrorMessage := 'Input parameters can not be null';
    goto exit_;
  end if;

  begin
  
    if v_type = 'CREATE' then
      if(v_objectType = 'rootBusinessObject') then
        v_isRoot := 1;
      elsif (v_objectType = 'parentBusinessObject') then
        v_isRoot := 2;
      end if;

      -- Create tbl_fom_object only for custom objects 
      -- (for referenceObject it was created)
      if (v_objectType IN ('rootBusinessObject', 'businessObject')) then
        insert into tbl_fom_object
          (col_code,
           col_name,
           col_apicode,
           col_tablename,
           col_alias,
           col_xmlalias)
        values
          (upper(v_code),
           v_name,
           v_apiCode,
           v_tableName,
           't_' || upper(v_code),
           'xml_' || upper(v_code))
        returning col_id into v_fomObjectId;
      else
        select col_id
          into v_fomObjectId
          from tbl_fom_object
         where upper(col_apicode) = upper(v_apiCode);
      end if;
    
      -- Create tbl_dom_object 
      insert into tbl_dom_object
        (col_code,
         col_name,
         col_description,
         col_type,
         col_dom_objectdom_model,
         col_dom_objectfom_object,
         col_isroot)
      values
        (upper(v_code),
         v_name,
         v_description,
         v_objectType,
         (select col_id
            from tbl_dom_model
           where col_dom_modelmdm_model = v_modelId),
         v_fomObjectId,
         v_isRoot)
      returning col_id into v_domObjectId;
    
      -- Create tbl_som_object
      insert into tbl_som_object
        (col_code,
         col_name,
         col_description,
         col_type,
         col_som_objectsom_model,
         col_som_objectfom_object,
         col_isroot)
      values
        (upper(v_code),
         v_name,
         v_description,
         v_objectType,
         (select col_id
            from tbl_som_model
           where col_som_modelmdm_model = v_modelId),
         v_fomObjectId,
         v_isRoot)
      returning col_id into v_somObjectId;      
    
      if (v_objectType IN ('referenceObject')) then
        -- Add renderer for referenceObject
        begin
          select rc.col_id   as RCId,
                 refo.COL_ID as REFOId,
                 ro.col_id   as ROId
            into v_renderControlId, v_refoId, v_roId
            from tbl_dom_rendercontrol rc
           inner join tbl_dom_renderobject ro
              on rc.col_rendercontrolrenderobject = ro.col_id
           inner join tbl_fom_object fo
              on fo.col_id = ro.col_renderobjectfom_object
            left join tbl_dom_referenceobject refo
              on ro.col_renderobjectfom_object =
                 refo.col_dom_refobjectfom_object
           where rc.col_isdefault = 1
             and fo.col_id = v_fomObjectId;
        exception
          when no_data_found then
            v_renderControlId := null;
            v_refoId := null;
            v_roId := null;
        end;
      
        if (v_renderControlId is not null) then
          v_refAttrCode := 'RC_' || v_code;
        
          insert into tbl_som_attribute
            (col_code,
             col_name,
             col_som_attributerenderobject,
             col_som_attributerefobject,
             col_som_attributesom_object)
          values
            (v_refAttrCode, v_name, v_roId, v_refoId, v_somObjectId);
        end if;
      end if;
    elsif v_type = 'MODIFY' then
      --Get fomObjectId
      select col_id
        into v_fomObjectId
        from tbl_fom_object
       where upper(col_apicode) = upper(v_apiCode);
    
      -- Update only custom object data
      if (v_objectType IN ('rootBusinessObject', 'businessObject')) then
        update tbl_fom_object
           set col_name = v_name
         where col_id = v_fomObjectId;
      end if;
    
      update tbl_dom_object
         set col_name = v_name, col_description = v_description
       where col_dom_objectfom_object = v_fomObjectId
         and upper(col_code) = v_code
         and col_dom_objectdom_model =
             (select col_id
                from tbl_dom_model
               where col_dom_modelmdm_model = v_modelId);
    
      update tbl_som_object
         set col_name = v_name, col_description = v_description
       where col_som_objectfom_object = v_fomObjectId
         and upper(col_code) = v_code
         and col_som_objectsom_model =
             (select col_id
                from tbl_som_model
               where col_som_modelmdm_model = v_modelId);
          
    end if;
  exception
    when OTHERS then
      :ErrorMessage := 'Error on ' || (case
                         when v_type = 'MODIFY' then
                          'modify'
                         else
                          'create'
                       end) || ' object with code - ' || v_apiCode || ' ' ||
                       SUBSTR(SQLERRM, 1, 150);
      :ErrorCode    := 101;
  end;
  
  <<exit_>>
  NULL;
end;