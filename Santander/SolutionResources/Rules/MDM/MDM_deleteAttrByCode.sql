declare
  v_apiCode        nvarchar2(255);
  v_objectTypeCode nvarchar2(255);
  v_objectApiCode  nvarchar2(255);
  v_code           nvarchar2(255);
  v_modelId        number;
  v_fomAttrId      number;
  v_domObjectId    number;
  v_somObjectId    number;
  v_attrFormatCode nvarchar2(255);
  v_objectCode     nvarchar2(255);
  v_isCalcCode     number;
begin

  -- Init
  v_modelId        := :ModelId;
  v_apiCode        := :ApiCode;
  v_code           := :Code;
  v_objectTypeCode := :ObjectTypeCode;
  v_objectApiCode  := :ObjectApiCode;
  v_objectCode     := :ObjectCode;
  v_isCalcCode     := :CalcCode;
  :ErrorMessage    := '';
  :ErrorCode       := 0;

  if (v_modelId is null or v_apiCode is null) then
    :ErrorCode    := 101;
    :ErrorMessage := 'Input parameters can not be null';
    goto exit_;
  end if;

  if (v_isCalcCode = 1) then
    -- Calculate correct format code
    v_attrFormatCode := v_objectCode || '_' || v_code;
    if length(v_attrFormatCode) > 30 then
      v_attrFormatCode := substr(v_attrFormatCode, 1, 15) ||
                          substr(v_attrFormatCode, -15);
    end if;
  else
    v_attrFormatCode := v_code;
  end if;

  begin
  
    begin
      select col_id
        into v_fomAttrId
        from tbl_fom_attribute
       where upper(col_apicode) = upper(v_apiCode);
    exception
      when no_data_found then
        v_fomAttrId   := null;
        :ErrorMessage := 'Parent Object is not found';
        :ErrorCode    := 101;
        goto exit_;
    end;
  
    begin
      select d.col_id
        into v_domObjectId
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
        v_domObjectId := null;
        :ErrorMessage := 'Object is not found';
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
        v_somObjectId := null;
        :ErrorMessage := 'Object is not found';
        :ErrorCode    := 101;
        goto exit_;
    end;
  
    delete from tbl_dom_insertattr
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
    
    delete from tbl_dom_updateattr
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
  
    delete from tbl_uielement_dom_attribute
     where col_dom_attribute_id in
           (select col_id
              from tbl_dom_attribute
             where col_dom_attributedom_object = v_domObjectId
               and upper(col_code) = upper(v_attrFormatCode)
               and col_dom_attrfom_attr = v_fomAttrId);
  
  
    delete from tbl_som_searchattr
     where col_som_searchattrfom_attr = v_fomAttrId
       and upper(col_code) = upper(v_attrFormatCode)
       and col_som_searchattrsom_config in
           (select sc.col_id
              from tbl_som_model sm
             inner join tbl_som_config sc
                on sm.col_id = sc.col_som_configsom_model
             where sm.col_som_modelmdm_model = v_modelId);
  
    delete from tbl_som_resultattr
     where col_som_resultattrfom_attr = v_fomAttrId
       and upper(col_code) = upper(v_attrFormatCode)
       and col_som_resultattrsom_config in
           (select sc.col_id
              from tbl_som_model sm
             inner join tbl_som_config sc
                on sm.col_id = sc.col_som_configsom_model
             where sm.col_som_modelmdm_model = v_modelId);
  
    delete from tbl_dom_attribute
     where col_dom_attributedom_object = v_domObjectId
       and upper(col_code) = upper(v_attrFormatCode)
       and col_dom_attrfom_attr = v_fomAttrId;
  
    delete from tbl_som_attribute
     where col_som_attributesom_object = v_somObjectId
       and upper(col_code) = upper(v_attrFormatCode)
       and col_som_attrfom_attr = v_fomAttrId;
  
    if (v_objectTypeCode IN ('rootBusinessObject', 'businessObject')) then
      delete from tbl_fom_attribute where col_id = v_fomAttrId;    
    end if;
  
  exception
    when OTHERS then
      :ErrorMessage := 'Error on delete attribute with code - ' ||
                       v_apiCode || ' ' || SUBSTR(SQLERRM, 1, 150);
      :ErrorCode    := 101;
    
  end;

  <<exit_>>
  NULL;

end;