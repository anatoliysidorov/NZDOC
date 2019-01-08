declare
  v_config       nclob;
  v_errorXMLData nclob;
  v_id           number;
  v_result       NUMBER;
  v_idMaxVersion number;
  v_isModelValid number;

begin

  v_id           := :ID;
  v_config       := :CONFIG;
  v_errorXMLData := :ErrorXMLData;
  v_isModelValid := :IsModelValid; 

  update tbl_mdm_model 
  set col_config = v_config
  where COL_ID = v_id;

  if (v_isModelValid = 1) then
    insert into tbl_mdm_modelversion
    (
      col_code, 
      col_config, 
      col_description, 
      col_isdeleted, 
      col_name, 
      col_usedfor, 
      col_mdm_modelversionmdm_model
    )
    select 
      col_code, 
      col_config, 
      col_description, 
      col_isdeleted, 
      col_name, 
      col_usedfor, 
      col_id
    from tbl_mdm_model
    where col_id = v_id;  
  else
    select max(col_id) into v_idMaxVersion 
    from tbl_mdm_modelversion 
    where col_mdm_modelversionmdm_model = v_id;

    if (v_idMaxVersion is null) then
      -- Create first model version with CONFIG is NULL
      insert into tbl_mdm_modelversion
        (
          col_code, 
          col_config, 
          col_description, 
          col_isdeleted, 
          col_name, 
          col_usedfor,
          col_mdm_modelversionmdm_model
        )
        select 
          col_code, 
          null, 
          col_description, 
          col_isdeleted, 
          col_name, 
          col_usedfor, 
          col_id 
        from tbl_mdm_model 
        where col_id = v_id;
    else
        delete from tbl_dom_modeljournal
       where col_mdm_modverdom_modjrnl = v_idMaxVersion;
    end if;
  end if;

  select max(col_id) into v_idMaxVersion 
  from tbl_mdm_modelversion 
  where col_mdm_modelversionmdm_model = v_id;

  if(v_errorXMLData is not null) then
    insert into tbl_dom_modeljournal
    (
      col_type,
      col_appbasecode,
      col_errorcode,
      col_errormessage,
      col_mdm_modverdom_modjrnl
    )
    select 
      s.Type,
      s.AppbaseCode,
      s.ErrorCode,
      s.ErrorMessage,
      v_idMaxVersion
    from (select d.extract('Parameter/ErrorMessage/text()').getStringVal() AS ErrorMessage,
                d.extract('Parameter/ErrorCode/text()').getStringVal() AS ErrorCode,
                d.extract('Parameter/Type/text()').getStringVal() AS Type,
                d.extract('Parameter/AppbaseCode/text()').getStringVal() AS AppbaseCode
            from table(XMLSequence(extract(XMLType(v_errorXMLData),'/Parameters/Parameter'))) d) s
    where s.ErrorCode is not null 
          and s.ErrorMessage is not null;
  end if;

  
   -- delete OLD records in DOM_ModelJournal and MDM_ModelVersion
   delete from tbl_dom_modeljournal
   where col_mdm_modverdom_modjrnl in (select col_id
                                         from tbl_mdm_modelversion
                                        where col_id != v_idMaxVersion
                                          and col_mdm_modelversionmdm_model = v_id);

  
  --  delete from tbl_mdm_modelversion
  --  where col_id in (select col_id 
  --                   from tbl_mdm_modelversion 
  --                   where col_id != v_idMaxVersion
  --                         and col_mdm_modelversionmdm_model = v_id);

end;