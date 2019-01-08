declare
  v_apiCode     nvarchar2(255);
  v_objectType  nvarchar2(255);
  v_modelId     number;
  v_fomObjectId number;
  v_code        nvarchar2(255);
  v_somAttrCode nvarchar2(255);
  v_somAttrId   number;
begin

  -- Init
  v_modelId     := :ModelId;
  v_apiCode     := :ApiCode;
  v_objectType  := :ObjectType;
  v_code        := :Code;
  :ErrorMessage := '';
  :ErrorCode    := 0;

  if (v_modelId is null or v_apiCode is null) then
    :ErrorCode    := 101;
    :ErrorMessage := 'Input parameters can not be null';
    goto exit_;
  end if;

  begin
  
    begin
      select col_id into v_fomObjectId
      from tbl_fom_object
      where upper(col_apicode) = upper(v_apiCode);
    exception when no_data_found then
      v_fomObjectId := null;
    end;  
    
    if(v_fomObjectId is null) then
      :ErrorCode    := 101;
      :ErrorMessage := 'Object is not found';
      goto exit_;          
    end if;
  
    -- clean search configs
    delete from tbl_som_resultattr
     where col_som_resultattrsom_config in
           (select col_id
              from tbl_som_config
             where col_som_configfom_object = v_fomObjectId
               and col_som_configsom_model =
                   (select col_id
                      from tbl_som_model
                     where col_som_modelmdm_model = v_modelId));
  
    delete from tbl_som_searchattr
     where col_som_searchattrsom_config in
           (select col_id
              from tbl_som_config
             where col_som_configfom_object = v_fomObjectId
               and col_som_configsom_model =
                   (select col_id
                      from tbl_som_model
                     where col_som_modelmdm_model = v_modelId));
  
    delete from tbl_mdm_searchpage
     where col_searchpagesom_config in
           (select col_id
              from tbl_som_config
             where col_som_configfom_object = v_fomObjectId
               and col_som_configsom_model =
                   (select col_id
                      from tbl_som_model
                     where col_som_modelmdm_model = v_modelId));
                    
    delete from tbl_fom_uielement
      where col_fom_uielementsom_config in
          (select col_id
              from tbl_som_config
             where col_som_configfom_object = v_fomObjectId
               and col_som_configsom_model =
                   (select col_id
                      from tbl_som_model
                     where col_som_modelmdm_model = v_modelId));

  delete from tbl_som_config
     where col_som_configfom_object = v_fomObjectId
       and col_som_configsom_model =
           (select col_id
              from tbl_som_model
             where col_som_modelmdm_model = v_modelId);    
  
    -- clean forms
    delete from tbl_uielement_dom_attribute
     where col_fom_uielement_id in
           (select col_id
              from tbl_fom_uielement
             where col_uielementform in
                   (select col_id
                      from tbl_mdm_form
                     where col_mdm_formdom_object =
                           (select col_id
                              from tbl_dom_object
                             where col_dom_objectfom_object = v_fomObjectId
                               and upper(col_code) = v_code
                               and col_dom_objectdom_model =
                                   (select col_id
                                      from tbl_dom_model
                                     where col_dom_modelmdm_model = v_modelId))));
  
    delete from tbl_fom_uielement
     where col_uielementform in
           (select col_id
              from tbl_mdm_form
             where col_mdm_formdom_object =
                   (select col_id
                      from tbl_dom_object
                     where col_dom_objectfom_object = v_fomObjectId
                       and upper(col_code) = v_code
                       and col_dom_objectdom_model =
                           (select col_id
                              from tbl_dom_model
                             where col_dom_modelmdm_model = v_modelId)));
  
    delete from tbl_assocpage
     where col_assocpagemdm_form in
           (select col_id
              from tbl_mdm_form
             where col_mdm_formdom_object =
                   (select col_id
                      from tbl_dom_object
                     where col_dom_objectfom_object = v_fomObjectId
                       and upper(col_code) = v_code
                       and col_dom_objectdom_model =
                           (select col_id
                              from tbl_dom_model
                             where col_dom_modelmdm_model = v_modelId)));
  
    delete from tbl_mdm_form
     where col_mdm_formdom_object =
           (select col_id
              from tbl_dom_object
             where col_dom_objectfom_object = v_fomObjectId
               and upper(col_code) = v_code
               and col_dom_objectdom_model =
                   (select col_id
                      from tbl_dom_model
                     where col_dom_modelmdm_model = v_modelId));
  
    if (v_objectType IN ('referenceObject')) then
      -- Remove renderers for refernceObject
      begin
        select upper(col_code), col_id
          into v_somAttrCode, v_somAttrId
          from tbl_som_attribute
         where col_som_attributesom_object =
               (select col_id
                  from tbl_som_object
                 where col_som_objectfom_object = v_fomObjectId
                   and upper(col_code) = v_code
                   and col_som_objectsom_model =
                       (select col_id
                          from tbl_som_model
                         where col_som_modelmdm_model = v_modelId));
       exception when no_data_found then
         v_somAttrCode := null;
         v_somAttrId := null;
       end;

       if(v_somAttrCode is not null) then  
          delete from tbl_som_resultattr
           where col_resultattrresultattrgroup =
                 (select col_id
                    from tbl_som_resultattr
                   where upper(col_code) = v_somAttrCode);
        
          delete from tbl_som_searchattr
           where col_searchattrsearchattrgroup =
                 (select col_id
                    from tbl_som_searchattr
                   where upper(col_code) = v_somAttrCode);
      
          delete from tbl_som_resultattr where upper(col_code) = v_somAttrCode;
        
          delete from tbl_som_searchattr where upper(col_code) = v_somAttrCode;
        
          delete from tbl_som_attribute where col_id = v_somAttrId;      
      end if;
    end if;
  
    -- delete dom_object 
    delete from tbl_dom_object
     where col_dom_objectfom_object = v_fomObjectId
       and upper(col_code) = v_code
       and col_dom_objectdom_model =
           (select col_id
              from tbl_dom_model
             where col_dom_modelmdm_model = v_modelId);
  
    -- delete tbl_som_object
    delete from tbl_som_object
     where col_som_objectfom_object = v_fomObjectId
       and upper(col_code) = v_code
       and col_som_objectsom_model =
           (select col_id
              from tbl_som_model
             where col_som_modelmdm_model = v_modelId);
  
    if (v_objectType IN ('rootBusinessObject', 'businessObject')) then
      -- delete tbl_fom_object 
      delete from tbl_fom_object where col_id = v_fomObjectId;
    end if;
  
  exception
    when OTHERS then
      :ErrorMessage := 'Error on delete object with code - ' || v_apiCode || ' ' ||
                       SUBSTR(SQLERRM, 1, 150);
      :ErrorCode    := 101;
    
  end;

  <<exit_>>
  NULL;
end;