DECLARE
  v_id              NUMBER;
  v_name            NVARCHAR2(255);
  v_code            NVARCHAR2(255);
  v_description     NCLOB;
  v_modelId         NUMBER;
  v_ObjectId        NUMBER;
  v_FomObjectId     number;
  v_FomObjectCode   NVARCHAR2(255);
  v_somObjectIsRoot NUMBER;
  v_sorder          number;
  v_parentFOMPathId number;
  v_parentFOMAttrId number;
  v_result          number;
  v_somObjectType nvarchar2(255);
BEGIN

  v_name        := :Name;
  v_code        := :Code;
  v_description := :Description;
  v_modelId     := :ModelId;
  v_ObjectId    := :SOMObjectId;
  :ErrorMessage := '';
  :ErrorCode    := 0;
  v_sorder      := 0;

  if (v_ObjectId is null or v_modelId is null) then
    :ErrorCode    := 101;
    :ErrorMessage := 'Input parameters can not be null';
    goto exit_;
  end if;

  begin
  
    select 
      s.col_som_objectfom_object, s.col_code, s.col_isroot, s.col_type
      into v_FomObjectId, v_FomObjectCode, v_somObjectIsRoot, v_somObjectType
      from tbl_som_object s
     where s.col_id = v_ObjectId;
  
    insert into tbl_som_config
    (
      col_name,
      col_code,
      col_description,
      col_isdeleted,
      col_som_configfom_object,
      col_som_configsom_model,
      col_isshowinnavmenu
    )
    values
    (
      v_name, 
      v_code, 
      v_description, 
      0, 
      v_FomObjectId, 
      v_modelId,
      (case when v_somObjectType = 'rootBusinessObject' then 1 else 0 end)
    )
    returning col_id into v_id;
  
    select d.col_dom_object_pathtoprntext
      into v_parentFOMPathId
      from tbl_som_config sc
     inner join tbl_som_model sm
        on sm.col_id = sc.col_som_configsom_model
     inner join tbl_dom_model dm
        on dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
     inner join tbl_dom_object d
        on d.col_dom_objectdom_model = dm.col_id
       and sc.col_som_configfom_object = d.col_dom_objectfom_object
     where sc.col_id = v_id;
  
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
      (v_FomObjectCode || '_PARENTID',
       v_FomObjectCode || '_PARENTID',
       (select frc.col_apicode
          from tbl_fom_path fp
         inner join tbl_fom_relationship frc
            on frc.col_id = fp.col_fom_pathfom_relationship
         where fp.col_id = v_parentFOMPathId),
       (select frc.col_foreignkeyname
          from tbl_fom_path fp
         inner join tbl_fom_relationship frc
            on frc.col_id = fp.col_fom_pathfom_relationship
         where fp.col_id = v_parentFOMPathId),
       'PARENTID',
       'SIMPLE',
       (select frc.col_childfom_relfom_object
          from tbl_fom_path fp
         inner join tbl_fom_relationship frc
            on frc.col_id = fp.col_fom_pathfom_relationship
         where fp.col_id = v_parentFOMPathId),
       (select col_id
          from tbl_dict_datatype
         where lower(col_code) = 'integer'))
    returning col_id into v_parentFOMAttrId;
  
    -- Add ParentId - tbl_som_resultattr
    insert into tbl_som_resultattr
      (col_code,
       col_name,
       col_som_resultattrfom_attr,
       col_som_resultattrfom_path,
       col_som_resultattrsom_config,
       col_sorder)
    values
      (v_FomObjectCode || '_PARENTID',
       v_FomObjectCode || '_PARENTID',
       v_parentFOMAttrId,
       v_parentFOMPathId,
       v_id,
       0);
  
    -- Add ParentId - tbl_som_searchattr
    insert into tbl_som_searchattr
      (col_code,
       col_name,
       col_som_searchattrfom_attr,
       col_som_searchattrfom_path,
       col_som_searchattrsom_config,
       col_sorder)
    values
      (v_FomObjectCode || '_PARENTID',
       v_FomObjectCode || '_PARENTID',
       v_parentFOMAttrId,
       v_parentFOMPathId,
       v_id,
       0);

    -- Add Case fields for root object
    if(v_somObjectIsRoot = 1) then
      v_result := f_RDR_AddCaseRdrsToSResAttr(RootFomObject => v_FomObjectId, SConfigId => v_id); 
    end if;   
       
    for rec in (select sa.col_code as code,
                       sa.col_name as name,
                       fa.col_id   as fomAttrId,
                       dt.col_code as typeCode,
                       sa.col_isretrievableinlist as UseOnList,	
	                     sa.col_issearchable AS UseOnSearch
                  from tbl_som_attribute sa
                 inner join tbl_fom_attribute fa
                    on fa.col_id = sa.col_som_attrfom_attr
                 inner join tbl_dict_datatype dt
                    on dt.col_id = fa.col_fom_attributedatatype
                 where sa.col_som_attributesom_object = v_ObjectId) loop
    
      if rec.typeCode in ('CREATEDBY', 'CREATEDDATE', 'MODIFIEDBY', 'MODIFIEDDATE') then

        if(nvl(rec.UseOnList, 0) = 1) then
          v_result := f_RDR_AddBORdrToSResAttr(AttrTypeCode   => rec.typeCode,
                                              FomAttributeId => rec.fomAttrId,
                                              PathId         => v_parentFOMPathId,
                                              SConfigId      => v_id);
        end if;
      
        if(nvl(rec.UseOnSearch, 0) = 1) then
          v_result := f_RDR_AddBORdrToSSrchAttr(AttrTypeCode   => rec.typeCode,
                                                FomAttributeId => rec.fomAttrId,
                                                PathId         => v_parentFOMPathId,
                                                SConfigId      => v_id);
        end if;
      
      else
      
      if(nvl(rec.UseOnList, 0) = 1) then
        -- Add ID - tbl_som_resultattr
        insert into tbl_som_resultattr
          (col_code,
           col_name,
           col_sorder,
           col_som_resultattrfom_attr,
           col_som_resultattrfom_path,
           col_som_resultattrsom_config)
        values
          (rec.code,
           rec.name,
           v_sorder,
           rec.fomAttrId,
           v_parentFOMPathId,
           v_id);
      end if;
      
      if(nvl(rec.UseOnSearch, 0) = 1) then
        -- Add ID - tbl_som_searchattr
        insert into tbl_som_searchattr
          (col_code,
           col_name,
           col_sorder,
           col_som_searchattrfom_attr,
           col_som_searchattrfom_path,
           col_som_searchattrsom_config)
        values
          (rec.code,
           rec.name,
           v_sorder,
           rec.fomAttrId,
           v_parentFOMPathId,
           v_id);
      end if;
      
      end if;
    
      v_sorder := v_sorder + 1;
    end loop;
  
    :New_ID := v_id;
  
  exception
    when OTHERS then
      :ErrorCode    := 101;
      :ErrorMessage := 'Error on create search config with code - ' ||
                       v_code || substr(SQLERRM, 1, 150); 
  end;

  <<exit_>>
  NULL;

end;