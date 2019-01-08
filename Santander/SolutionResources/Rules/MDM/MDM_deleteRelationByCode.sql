declare
  v_apiCode nvarchar2(255);
  v_modelId number;
  v_errorCode number;
  v_errorMessage nvarchar2(255);
  v_tmp_attrCode nvarchar2(255);
  v_tmp_boCode nvarchar2(255);
  v_tmp_boApiCode nvarchar2(255);
  v_res number;
  v_count number;
begin

  -- Init
  v_modelId     := :ModelId;
  v_apiCode     := :ApiCode;
  :ErrorMessage := '';
  :ErrorCode    := 0;
  
  if(v_modelId is null or v_apiCode is null) then
  	:ErrorCode    := 101;
    :ErrorMessage := 'Input parameters can not be null';
    goto exit_;
  end if;
  
  begin
    
    select count(*) into v_count
    from tbl_fom_attribute
    where upper(col_apicode) = upper(v_apiCode);
    
    -- Clean fom_attribute
    if(v_count > 0) then
      begin
        select 
          fa.col_code,
          fo.col_code,
          fo.col_apicode into v_tmp_attrCode, v_tmp_boCode, v_tmp_boApiCode
        from tbl_fom_attribute fa
        inner join tbl_fom_object fo on fo.col_id = fa.col_fom_attributefom_object
        where upper(fa.col_apicode) = upper(v_apiCode);
      exception
        when no_data_found then
           v_tmp_attrCode := null;
           v_tmp_boCode := null;
           v_tmp_boApiCode := null;
      end;         
      
      if(v_tmp_attrCode is not null 
        and v_tmp_boApiCode is not null 
        and v_tmp_boCode is not null)
      then
        v_res := f_mdm_deleteattrbycode(apicode        => v_apiCode,
                                        errorcode      => v_errorCode,
                                        errormessage   => v_errorMessage,
                                        modelid        => v_modelId,
                                        code           => v_tmp_attrCode,
                                        objectcode     => v_tmp_boCode,
                                        objectapicode  => v_tmp_boApiCode,
                                        objecttypecode => 'businessObject',
                                        calccode       => 0);
       end if;               
    end if;
    
    delete from tbl_fom_path
     where col_fom_pathfom_relationship =
           (select col_id
              from tbl_fom_relationship
             where upper(col_apicode) = upper(v_apiCode));     
  
    delete from tbl_dom_relationship
     where col_dom_relfom_rel =
           (select col_id
              from tbl_fom_relationship
             where upper(col_apicode) = upper(v_apiCode));
  
    delete from tbl_som_relationship
     where col_som_relfom_rel =
           (select col_id
              from tbl_fom_relationship
             where upper(col_apicode) = upper(v_apiCode)); 
  
    delete from tbl_fom_relationship
     where upper(col_apicode) = upper(v_apiCode);
  
  exception
    when OTHERS then
      :ErrorMessage := 'Error on delete relation with code - ' || v_apiCode || ' ' ||
                       SUBSTR(SQLERRM, 1, 150);
      :ErrorCode    := 101;
    
  end;
  
  <<exit_>>
  NULL;
end;