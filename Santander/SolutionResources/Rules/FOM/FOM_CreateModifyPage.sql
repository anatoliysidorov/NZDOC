DECLARE
  v_id                NUMBER;
  v_name              NVARCHAR2(255);
  v_code              NVARCHAR2(255);
  v_description       NCLOB;
  v_fieldvalues       NCLOB;
  v_usedfor           NVARCHAR2(255);
  v_btn_routing_id    NUMBER;
  v_config            NCLOB;
  v_usetemplate       NUMBER;
  v_systemdefault     NUMBER;
  v_count             NUMBER;
  v_TemplatePageId    NUMBER;
  v_UIElementId       NUMBER;
  v_AccessObjectId    NUMBER;
  v_CaseTypeId        NUMBER;
  v_isdeleted         NUMBER;
  v_btn_assignment_id NUMBER;
  v_isId              NUMBER;
  v_result            NUMBER;
  v_aotype            INT;

  --standard  
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id             := :ID;
  v_name           := :NAME;
  v_code           := :Code;
  v_description    := :Description;
  v_fieldvalues    := :FieldValues;
  v_usedfor        := UPPER(:UsedFor);
  v_config         := :Config;
  v_usetemplate    := :UseTemplate;
  v_systemdefault  := :SystemDefault;
  v_TemplatePageId := NULL;
  v_CaseTypeId     := :CaseTypeId;
  v_isdeleted      := :IsDeleted;
  :SuccessResponse := EMPTY_CLOB();

  --standard  
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  -- validation on Id is Exist
  IF NVL(v_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, tablename => 'TBL_FOM_PAGE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  -- Get Access Object Type
  v_aotype := f_util_getidbycode(code => 'PAGE_ELEMENT', tablename => 'tbl_ac_accessobjecttype');

  --set assumed success message  
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated {{MESS_NAME}} page';
  ELSE
    :SuccessResponse := 'Created {{MESS_NAME}} page';
  END IF;
  --:SuccessResponse := :SuccessResponse || ' ' || v_name || ' page';
  v_result := LOC_i18n(MessageText => :SuccessResponse, MessageResult => :SuccessResponse, MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_name)));

  BEGIN
    IF (v_id IS NULL) THEN
      SELECT COUNT(col_id)
        INTO v_count
        FROM tbl_fom_page
       WHERE col_systemdefault = 1
         AND col_usedfor = v_usedfor;
    
      IF (NVL(v_usetemplate, 0) = 1 AND v_count > 0) THEN
        -- clone Page record
        FOR rec IN (SELECT col_id,
                           col_description,
                           col_name        AS NAME,
                           col_code,
                           col_fieldvalues AS fieldvalues,
                           col_usedfor,
                           col_config      AS config
                      FROM tbl_fom_page
                     WHERE col_systemdefault = 1
                       AND col_usedfor = v_usedfor) LOOP
          INSERT INTO tbl_fom_page
            (col_description, col_isdeleted, col_name, col_code, col_fieldvalues, col_usedfor, col_config, col_PageCaseSysType)
          VALUES
            (v_description, 0, v_name, v_code, rec.fieldvalues, v_usedfor, rec.config, v_CaseTypeId)
          RETURNING col_id INTO :recordId;
          v_TemplatePageId := rec.col_id;
          :SuccessResponse := 'System Template page {{MESS_PAGEFROM}} was saved to page {{MESS_PAGETO}}';
          v_result         := LOC_i18n(MessageText   => :SuccessResponse,
                                       MessageResult => :SuccessResponse,
                                       MessageParams => NES_TABLE(Key_Value('MESS_PAGEFROM', rec.name), Key_Value('MESS_PAGETO', v_name)));
          :affectedRows    := 1;
        END LOOP;
      
        -- clone PageElement records
        FOR cur1 IN (SELECT ue.col_jsondata        AS jsondata,
                            ue.col_positionindex   AS positionindex,
                            ue.col_regionid        AS regionid,
                            ue.col_description     AS description,
                            ue.col_iseditable      AS iseditable,
                            ao.col_id              AS accessobjectid,
                            ue.col_formidlist      AS formidlist,
                            ue.col_codedpageidlist AS codedpageidlist,
                            ue.col_config          AS config
                       FROM tbl_fom_uielement ue
                       LEFT JOIN tbl_ac_accessobject ao
                         ON ao.col_accessobjectuielement = ue.col_id
                      WHERE ue.col_uielementpage = v_TemplatePageId) LOOP
          -- FOM_UIELEMENT
          INSERT INTO tbl_fom_uielement
            (col_description, col_jsondata, col_positionindex, col_regionid, col_uielementpage, col_iseditable, col_code, col_formidlist, col_codedpageidlist, col_config)
          VALUES
            (cur1.description, cur1.jsondata, cur1.positionindex, cur1.regionid, :recordId, cur1.iseditable, sys_guid(), cur1.formidlist, cur1.codedpageidlist, cur1.config)
          RETURNING col_id INTO v_UIElementId;
        
          -- AC_AccessObject
          INSERT INTO tbl_ac_accessobject
            (col_name, col_code, col_accessobjectuielement, col_accessobjaccessobjtype)
          VALUES
            ('Page element ' || To_char(v_UIElementId), f_UTIL_calcUniqueCode('PAGE_ELEMENT_' || to_char(v_UIElementId), 'tbl_ac_accessobject'), v_UIElementId, v_aotype)
          RETURNING col_id INTO v_AccessObjectId;
        
          -- AC_ACL
          FOR cur2 IN (SELECT col_aclaccesssubject AS aclaccesssubject,
                              col_aclpermission    AS aclpermission,
                              col_type             AS TYPE
                         FROM tbl_ac_acl
                        WHERE col_aclaccessobject = cur1.accessobjectid) LOOP
            INSERT INTO tbl_ac_acl
              (col_aclaccessobject, col_aclaccesssubject, col_aclpermission, col_type, col_code)
            VALUES
              (v_AccessObjectId, cur2.aclaccesssubject, cur2.aclpermission, cur2.type, sys_guid());
          END LOOP;
        END LOOP;
      ELSE
        -- create Page record
        INSERT INTO tbl_fom_page
          (col_name, col_code, col_description, col_isdeleted, col_fieldvalues, col_usedfor, col_config, col_PageCaseSysType)
        VALUES
          (v_name, v_code, v_description, 0, v_fieldvalues, v_usedfor, v_config, v_CaseTypeId)
        RETURNING col_id INTO :recordId;
      
        IF (v_usedfor <> 'EXTPARTY') THEN
          -- create a record Assignment button 
          INSERT INTO tbl_fom_uielement
            (col_description, col_jsondata, col_positionindex, col_regionid, col_uielementpage, col_iseditable, col_config)
          VALUES
            ('Assignment button', '{"type":"assignmentbutton"}', 0, 1, :recordId, 0, '<CustomData><Attributes></Attributes></CustomData>')
          RETURNING col_id INTO v_btn_assignment_id;
        
          --  create a record in the AC_AccessObject table of type AC_AccessObjectType.col_code = "PAGE_ELEMENT"
          INSERT INTO tbl_ac_accessobject
            (col_name, col_code, col_accessobjectuielement, col_accessobjaccessobjtype)
          VALUES
            ('Page element ' || To_char(v_btn_assignment_id), f_UTIL_calcUniqueCode('PAGE_ELEMENT_' || to_char(v_btn_assignment_id), 'tbl_ac_accessobject'), v_btn_assignment_id, v_aotype);
        
          -- create a record Routing button 
          IF ((v_usedfor = 'CASE') OR (v_usedfor = 'PORTALCASE')) THEN
            INSERT INTO tbl_fom_uielement
              (col_description, col_jsondata, col_positionindex, col_regionid, col_uielementpage, col_iseditable, col_config)
            VALUES
              ('Milestone routing buttons', '{"type":"milestoneroutingbuttons"}', 1, 1, :recordId, 0, '<CustomData><Attributes></Attributes></CustomData>')
            RETURNING col_id INTO v_btn_routing_id;
          ELSE
            INSERT INTO tbl_fom_uielement
              (col_description, col_jsondata, col_positionindex, col_regionid, col_uielementpage, col_iseditable, col_config)
            VALUES
              ('Routing button', '{"type":"routingbuttons"}', 1, 1, :recordId, 0, '<CustomData><Attributes></Attributes></CustomData>')
            RETURNING col_id INTO v_btn_routing_id;
          END IF;
        
          --  create a record in the AC_AccessObject table of type AC_AccessObjectType.col_code = "PAGE_ELEMENT"
          INSERT INTO tbl_ac_accessobject
            (col_name, col_code, col_accessobjectuielement, col_accessobjaccessobjtype)
          VALUES
            ('Page element ' || To_char(v_btn_routing_id), f_UTIL_calcUniqueCode('PAGE_ELEMENT_' || to_char(v_btn_routing_id), 'tbl_ac_accessobject'), v_btn_routing_id, v_aotype);
        END IF;
      END IF;
    ELSE
      IF (v_systemdefault = 1) THEN
        -- reset Page.SystemDefault = 1
        UPDATE tbl_fom_page
           SET col_systemdefault = NULL
         WHERE col_systemdefault = 1
           AND col_usedfor = v_usedfor;
      END IF;
    
      UPDATE tbl_fom_page
         SET col_name = v_name, col_description = v_description, col_fieldvalues = v_fieldvalues, col_config = v_config, col_systemdefault = v_systemdefault, col_isdeleted = v_isdeleted
       WHERE col_id = v_id;
    
      :affectedRows := 1;
    
      :recordId := v_id;
    END IF;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      v_errormessage   := 'There already exists a page with the code {{MESS_CODE}}';
      v_result         := LOC_i18n(MessageText => v_errormessage, MessageResult => v_errormessage, MessageParams => NES_TABLE(Key_Value('MESS_CODE', To_char(v_code))));
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 102;
      v_errormessage   := Substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
