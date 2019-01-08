DECLARE
  --custom
  v_id          NUMBER;
  v_isDeleted   INTEGER;
  v_name        NVARCHAR2(255);
  v_code        NVARCHAR2(255);
  v_description NCLOB;
  v_ModelID     NUMBER;
  v_ObjectId    NUMBER;
  v_FomObjectId number;
  v_FomObjectCode NVARCHAR2(255);
  v_somObjectIsRoot NUMBER;

  --standard 
  v_errorcode     NUMBER;
  v_errormessage  NVARCHAR2(255);
  v_MessageParams NES_TABLE;
  v_result        number;
  v_showInNavMenu number;
BEGIN
  --custom
  v_id          := :ID;
  v_name        := :NAME;
  v_code        := :CODE;
  v_description := :DESCRIPTION;
  v_isDeleted   := :ISDELETED;
  v_ModelID     := :MODELID;
  v_ObjectId    := :OBJECTID;
  v_showInNavMenu := :IsShowInNavMenu;

  --standard 
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  :SuccessResponse := EMPTY_CLOB();

  --set assumed success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Search Updated';
  ELSE
    :SuccessResponse := 'Search Created';
  END IF;

  BEGIN
    --add new record or update existing one 
    IF v_id IS NULL THEN
    
      -- get FomObjectId/Code by SomObjectId
       select 
            s.col_som_objectfom_object, s.col_code, s.col_isroot 
            into v_FomObjectId, v_FomObjectCode, v_somObjectIsRoot
       from tbl_som_object s 
       where s.col_id = v_ObjectId;
    
      INSERT INTO tbl_SOM_Config
        (COL_NAME,
         COL_CODE,
         COL_DESCRIPTION,
         COL_ISDELETED,
         COL_SOM_CONFIGFOM_OBJECT,
         COL_SOM_CONFIGSOM_MODEL)
      VALUES
        (v_name,
         v_code,
         v_description,
         v_isDeleted,
         v_FomObjectId,
         v_ModelID)
      RETURNING col_id INTO v_id;
      
      begin
          -- Add ParentId - tbl_som_resultattr
          insert into tbl_som_resultattr(
            col_code, 
            col_name, 
            col_som_resultattrfom_attr, 
            col_som_resultattrfom_path, 
            col_som_resultattrsom_config, 
            col_sorder
          )
          values(
            v_FomObjectCode || '_PARENTID', 
            v_FomObjectCode || '_PARENTID', 
            (select col_id from tbl_fom_attribute where lower(col_code) = lower(v_FomObjectCode || '_PARENTID')), 
            (
              select d.col_dom_object_pathtoprntext
              from tbl_som_config sc
              inner join tbl_som_model sm
                on sm.col_id = sc.col_som_configsom_model
              inner join tbl_dom_model dm
                on dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
              inner join tbl_dom_object d
                on d.col_dom_objectdom_model = dm.col_id and sc.col_som_configfom_object = d.col_dom_objectfom_object
              where sc.col_id = v_id
            ),
            v_id,
            0
          );        
      exception when OTHERS then
        NULL;
      end;
	  
      begin
        -- Add ParentId - tbl_som_searchattr
        insert into tbl_som_searchattr(
            col_code, 
            col_name, 
            col_som_searchattrfom_attr, 
            col_som_searchattrfom_path, 
            col_som_searchattrsom_config, 
            col_sorder
          ) values (
            v_FomObjectCode || '_PARENTID', 
            v_FomObjectCode || '_PARENTID', 
            (select col_id from tbl_fom_attribute where lower(col_code) = lower(v_FomObjectCode || '_PARENTID')), 
            (
              select d.col_dom_object_pathtoprntext
              from tbl_som_config sc
              inner join tbl_som_model sm
                on sm.col_id = sc.col_som_configsom_model
              inner join tbl_dom_model dm
                on dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
              inner join tbl_dom_object d
                on d.col_dom_objectdom_model = dm.col_id and sc.col_som_configfom_object = d.col_dom_objectfom_object
              where sc.col_id = v_id
            ),
            v_id,
            0
          );
        exception when OTHERS then
          NULL;
        end;

        begin
          -- Add ID - tbl_som_resultattr
          insert into tbl_som_resultattr (
              col_code,
              col_name,
              col_som_resultattrfom_attr,
              col_som_resultattrfom_path,
              col_som_resultattrsom_config,
              col_sorder
          ) values (
              v_FomObjectCode || '_ID', 
              'ID', 
              (select col_id from tbl_fom_attribute where lower(col_code) = lower(v_FomObjectCode || '_ID')), 
              (select d.col_dom_object_pathtoprntext 
              from tbl_som_config sc 
              inner join tbl_som_model sm on sm.col_id = sc.col_som_configsom_model
              inner join tbl_dom_model dm on dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
              inner join tbl_dom_object d on d.col_dom_objectdom_model = dm.col_id
              inner join tbl_dom_attribute da on da.col_dom_attributedom_object = d.col_id
              where sc.col_id = v_id and lower(da.col_code) = lower(v_fomobjectcode || '_ID')),
              v_id,
              0
          );        
        exception when OTHERS then
          NULL;
        end;
        
        begin
          -- Add ID - tbl_som_searchattr
          insert into tbl_som_searchattr (
                col_code,
                col_name,
                col_som_searchattrfom_attr,
                col_som_searchattrfom_path,
                col_som_searchattrsom_config,
                col_sorder
          ) values (
              v_FomObjectCode || '_ID', 
              'ID', 
              (select col_id from tbl_fom_attribute where lower(col_code) = lower(v_FomObjectCode || '_ID')), 
              (select d.col_dom_object_pathtoprntext 
              from tbl_som_config sc 
              inner join tbl_som_model sm on sm.col_id = sc.col_som_configsom_model
              inner join tbl_dom_model dm on dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
              inner join tbl_dom_object d on d.col_dom_objectdom_model = dm.col_id
              inner join tbl_dom_attribute da on da.col_dom_attributedom_object = d.col_id
              where sc.col_id = v_id and lower(da.col_code) = lower(v_fomobjectcode || '_ID')),
              v_id,
              0
          );                
        exception when OTHERS then
          NULL;
        end;

      if(v_somObjectIsRoot = 1) then
        -- Add Case Renderers for root object
        v_result := f_RDR_AddCaseRdrsToSResAttr(RootFomObject => v_FomObjectId, SConfigId => v_id); 
      end if;  

    ELSE
      UPDATE tbl_SOM_Config
         SET COL_NAME                = v_name,
             COL_CODE                = v_code,
             COL_DESCRIPTION         = v_description,
             COL_ISDELETED           = v_isDeleted,
             COL_SOM_CONFIGSOM_MODEL = v_ModelID
       WHERE COL_ID = v_id;
    END IF;
    
    IF(v_showInNavMenu IS NOT NULL) THEN
        IF(NVL(v_showInNavMenu, 0) <> 0) THEN
            UPDATE tbl_SOM_Config SET
                 col_IsShowInNavMenu = 0
            WHERE COL_SOM_CONFIGSOM_MODEL = v_ModelID;
        END IF; 
        
        UPDATE tbl_SOM_Config SET 
            col_IsShowInNavMenu = v_showInNavMenu
        WHERE COL_ID = v_id;
    END IF;
  
    :affectedRows := SQL%ROWCOUNT;
    :recordId     := v_id;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows   := 0;
      v_errorcode     := 101;
      v_errormessage  := 'There already exists a Search with' ||
                         ' the name {{MESS_NAME}}';
      v_MessageParams := NES_TABLE();
      v_MessageParams.EXTEND(1);
      v_MessageParams(1) := Key_Value('MESS_NAME', v_name);
      v_result := LOC_i18n(MessageText    => v_errormessage,
                           MessageResult  => v_errormessage,
                           MessageParams  => v_MessageParams,
                           MessageParams2 => NULL);
      :SuccessResponse := '';
    WHEN OTHERS THEN    
      :affectedRows    := 0;
      v_errorcode      := 102;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
  
END;