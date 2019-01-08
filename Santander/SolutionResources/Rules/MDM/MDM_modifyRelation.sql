declare
  v_type             nvarchar2(20);
  v_modelId          number;
  v_name             nvarchar2(255);
  v_code             nvarchar2(255);
  v_fomRelationId    number;
  v_fomPathId        number;
  v_parentFOMPathId  number;
  v_parentObjectCode nvarchar2(255);
  v_apiCode          nvarchar2(255);
  v_targetApiCode    nvarchar2(255);
  v_sourceApiCode    nvarchar2(255);
  v_foreignKey       nvarchar2(255);
  v_domModelID       number;
  v_somModelID       number;
  v_sourceType       nvarchar2(255);
  v_targetCode       nvarchar2(255);
  v_sourceCode       nvarchar2(255);
  -- v_childObjectId number;
begin
  -- Init
  v_type             := :Type;
  v_modelId          := :ModelId;
  :ErrorMessage      := '';
  :ErrorCode         := 0;
  v_parentFOMPathId  := NULL;
  v_parentObjectCode := NULL;

  v_apiCode       := :ApiCode;
  v_name          := :Name;
  v_code          := :Code;
  v_targetApiCode := :TargetApiCode;
  v_sourceApiCode := :SourceApiCode;
  v_foreignKey    := :ForeignKeyName;
  v_targetCode    := :TargetCode;
  v_sourceCode    := :SourceCode;

  if (v_modelId is null or v_apiCode is null or v_sourceApiCode is null or
     v_targetApiCode is null) then
    :ErrorCode    := 101;
    :ErrorMessage := 'Input parameters can not be null';
    goto exit_;
  end if;

  begin
  
    if v_type = 'CREATE' then
      begin
        select col_code
          into v_parentObjectCode
          from tbl_fom_object
         where upper(col_apicode) = upper(v_targetApiCode);
      exception
        when no_data_found then
          v_parentObjectCode := null;
          :ErrorMessage := 'Error on ' || (case when v_type = 'MODIFY' then 'modify' else 'create' end) || ' relation with code - ' || v_apiCode || ': ';
          :ErrorMessage :=  :ErrorMessage  || 'Parent Object is not found';
          :ErrorCode    := 101;
          goto exit_;
      end;
    
      begin
        select col_id
          into v_domModelID
          from tbl_dom_model
         where col_dom_modelmdm_model = v_modelId;
      exception
        when no_data_found then
          v_domModelID  := null;
          :ErrorMessage := 'Error on ' || (case when v_type = 'MODIFY' then 'modify' else 'create' end) || ' relation with code - ' || v_apiCode || ': ';
          :ErrorMessage :=  :ErrorMessage  || 'DOM_Model is not found';
          :ErrorCode    := 101;
          goto exit_;
      end;
    
      begin
        select col_id
          into v_somModelID
          from tbl_som_model
         where col_som_modelmdm_model = v_modelId;
      exception
        when no_data_found then
          v_somModelID  := null;
          :ErrorMessage := 'Error on ' || (case when v_type = 'MODIFY' then 'modify' else 'create' end) || ' relation with code - ' || v_apiCode || ': ';
          :ErrorMessage :=  :ErrorMessage  || 'SOM_Model is not found';
          :ErrorCode    := 101;
          goto exit_;
      end;
    
      insert into tbl_fom_relationship
        (col_code,
         col_name,
         col_apicode,
         col_foreignkeyname,
         col_childfom_relfom_object,
         col_parentfom_relfom_object)
      values
        (upper(v_code),
         v_name,
         v_apiCode,
         v_foreignKey,
         (select col_id
            from tbl_fom_object
           where lower(col_apicode) = lower(v_targetApiCode)),
         (select col_id
            from tbl_fom_object
           where lower(col_apicode) = lower(v_sourceApiCode)))
      returning col_id into v_fomRelationId;
    
      if (v_parentObjectCode <> 'CASE') then
        begin
          select col_id
            into v_parentFOMPathId
            from tbl_fom_path
           where col_fom_pathfom_relationship =
                 (select col_id
                    from tbl_fom_relationship
                   where col_childfom_relfom_object =
                         (select col_parentfom_relfom_object
                            from tbl_fom_relationship
                           where col_id = v_fomRelationId));
        exception
          when OTHERS then
            v_parentFOMPathId := null;
        end;
      end if;
    
      insert into tbl_fom_path
        (col_code,
         col_name,
         col_fom_pathfom_relationship,
         col_jointype,
         col_fom_pathfom_path)
      values
        (upper(v_code), v_name, v_fomRelationId, 'LEFT', v_parentFOMPathId)
      returning col_id into v_fomPathId;
    
      insert into tbl_dom_relationship
        (col_code,
         col_name,
         col_childdom_reldom_object,
         col_parentdom_reldom_object,
         col_dom_relfom_rel)
      values
        (upper(v_code),
         v_name,
         (select d.col_id
            from tbl_fom_object f
           inner join tbl_dom_object d
              on d.col_dom_objectfom_object = f.col_id
           where upper(f.col_apicode) = upper(v_targetApiCode)
             and upper(d.col_code) = upper(v_targetCode)
             and d.col_dom_objectdom_model = v_domModelID),
         (select d.col_id
            from tbl_fom_object f
           inner join tbl_dom_object d
              on d.col_dom_objectfom_object = f.col_id
           where upper(f.col_apicode) = upper(v_sourceApiCode)
             and upper(d.col_code) = upper(v_sourceCode)
             and d.col_dom_objectdom_model = v_domModelID),
         v_fomRelationId);
    
      insert into tbl_som_relationship
        (col_code,
         col_name,
         col_childsom_relsom_object,
         col_parentsom_relsom_object,
         col_som_relfom_rel)
      values
        (upper(v_code),
         v_name,
         (select s.col_id
            from tbl_fom_object f
           inner join tbl_som_object s
              on s.col_som_objectfom_object = f.col_id
           where upper(f.col_apicode) = upper(v_targetApiCode)
             and upper(s.col_code) = upper(v_targetCode)
             and s.col_som_objectsom_model = v_somModelID),
         (select s.col_id
            from tbl_fom_object f
           inner join tbl_som_object s
              on s.col_som_objectfom_object = f.col_id
           where upper(f.col_apicode) = upper(v_sourceApiCode)
             and upper(s.col_code) = upper(v_sourceCode)
             and s.col_som_objectsom_model = v_somModelID),
         v_fomRelationId);
    
      -- if type is referenceObject update for v_sourceApiCode
      -- if type is not referenceObject update for v_targetApiCode
      begin
          select d.col_type into v_sourceType
          from tbl_fom_object f
          inner join tbl_dom_object d on d.col_dom_objectfom_object = f.col_id
          where upper(f.col_apicode) = upper(v_sourceApiCode)
                and upper(d.col_code) = upper(v_sourceCode)
                and d.col_dom_objectdom_model = v_domModelID;
      exception when no_data_found then
            v_sourceType := NULL;
      end;
    
      if (v_sourceType = 'referenceObject') then
        -- begin
        --   select col_id
        --     into v_childObjectId
        --     from tbl_fom_object
        --    where upper(col_apicode) = upper(v_sourceApiCode);
        -- exception
        --   when no_data_found then
        --     v_parentObjectCode := null;
        --     :ErrorMessage      := 'Parent Object is not found';
        --     :ErrorCode         := 101;
        --     goto exit_;
        -- end;  
      
        -- insert into tbl_fom_attribute
        --   (col_code,
        --    col_name,
        --    col_apicode,
        --    col_columnname,
        --    col_alias,
        --    col_storagetype,
        --    col_fom_attributefom_object,
        --    col_fom_attributedatatype)
        -- values
        --   (upper(v_code),
        --    upper(v_code),
        --    v_apiCode,
        --    v_foreignKey,
        --    upper(v_code),
        --    'SIMPLE',
        --    v_childObjectId,
        --    (select col_id
        --       from tbl_dict_datatype
        --      where lower(col_code) = 'integer'));
      
        update tbl_dom_object
           set col_dom_object_pathtoprntext = v_fomPathId
         where col_id =
               (select d.col_id
                  from tbl_fom_object f
                 inner join tbl_dom_object d
                    on d.col_dom_objectfom_object = f.col_id
                 where upper(f.col_apicode) = upper(v_sourceApiCode)
                   and upper(d.col_code) = upper(v_sourceCode)
                   and d.col_dom_objectdom_model = v_domModelID);
      else
        update tbl_dom_object
           set col_dom_object_pathtoprntext = v_fomPathId
         where col_id =
               (select d.col_id
                  from tbl_fom_object f
                 inner join tbl_dom_object d
                    on d.col_dom_objectfom_object = f.col_id
                 where upper(f.col_apicode) = upper(v_targetApiCode)
                   and upper(d.col_code) = upper(v_targetCode)
                   and d.col_dom_objectdom_model = v_domModelID);
      
      end if;
    
    elsif v_type = 'MODIFY' then
      update tbl_fom_relationship
         set col_name = v_name
       where upper(col_apicode) = upper(v_apiCode);
    
      update tbl_fom_path
         set col_name = v_name
       where col_fom_pathfom_relationship =
             (select col_id
                from tbl_fom_relationship
               where upper(col_apicode) = upper(v_apiCode));
    
      update tbl_dom_relationship
         set col_name = v_name
       where col_dom_relfom_rel =
             (select col_id
                from tbl_fom_relationship
               where upper(col_apicode) = upper(v_apiCode));
    
      update tbl_som_relationship
         set col_name = v_name
       where col_som_relfom_rel =
             (select col_id
                from tbl_fom_relationship
               where upper(col_apicode) = upper(v_apiCode));
    end if;
  
  exception
    when OTHERS then
      :ErrorMessage := 'Error on ' || (case
                         when v_type = 'MODIFY' then
                          'modify'
                         else
                          'create'
                       end) || ' relation with code - ' || v_apiCode || ' ' ||
                       SUBSTR(SQLERRM, 1, 150);
      :ErrorCode    := 101;
  end;

  <<exit_>>
  NULL;
end;
