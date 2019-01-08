DECLARE
  --custom  
  v_id            NUMBER;
  v_isdeleted     NUMBER;
  v_title         NVARCHAR2(255);
  v_pagecode      NVARCHAR2(255);
  v_description   NCLOB;
  v_pagetype      NUMBER;
  v_pagetype_code NVARCHAR2(255);
  v_form          NUMBER; --form builder
  v_codedpage     NUMBER; --custom js page
  v_page          NUMBER; --designer page
  v_rawtype       NVARCHAR2(255);
  v_elementid     NVARCHAR2(255);
  v_isId          NUMBER;
  v_result        NUMBER;
  v_Text          NVARCHAR2(255);
  v_Count         NUMBER;
  v_Query         VARCHAR2(1000);
  v_mdm_form      NUMBER;

  --for calculated order 
  v_max              NUMBER;
  v_calculated_order NUMBER;
  v_casesystype      NUMBER;
  v_workactivitytype NUMBER;
  v_tasksystype      NUMBER;
  v_tasktemplate     NUMBER;
  v_partytype        NUMBER;
  v_documenttype     NUMBER;
  v_pageparams       NCLOB;

  --standard  
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  --custom  
  v_id               := :Id;
  v_isdeleted        := :IsDeleted;
  v_title            := :Title;
  v_description      := :Description;
  v_pagetype         := :PAGETYPE;
  v_pagetype_code    := :PAGETYPE_CODE;
  v_casesystype      := :CASESYSTYPE;
  v_workactivitytype := :WorkActivityType;
  v_tasksystype      := :TASKSYSTYPE;
  v_tasktemplate     := :TASKTEMPLATE;
  v_partytype        := :PARTYTYPE;
  v_documenttype     := :DOCTYPE;
  v_rawtype          := :TARGET_RAWTYPE;
  v_elementid        := :TARGET_ELEMENTID;
  v_pageparams       := :PageParams;
  v_mdm_form         := :MDM_FORM;

  --calcuated later 
  v_pagecode  := NULL;
  v_form      := NULL;
  v_codedpage := NULL;
  v_page      := NULL;

  --standard 
  :affectedRows    := 0;
  v_errorcode      := 0;
  v_errormessage   := '';
  :SuccessResponse := EMPTY_CLOB();

  BEGIN
    -- validation on Id is Exist 
    -- TaskSysTypeId
    IF NVL(v_tasksystype, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_tasksystype, tablename => 'TBL_DICT_TASKSYSTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    -- CaseSysTypeId
    IF NVL(v_casesystype, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_casesystype, tablename => 'TBL_DICT_CASESYSTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    -- PartyTypeId
    IF NVL(v_partytype, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_partytype, tablename => 'TBL_DICT_PARTYTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    -- DocumentTypeId
    IF NVL(v_documenttype, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_documenttype, tablename => 'TBL_DICT_DOCUMENTTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    -- WorkActivityTypeId
    IF NVL(v_workactivitytype, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_workactivitytype,
                             tablename    => 'TBL_DICT_WORKACTIVITYTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    -- TaskTemplateId
    IF NVL(v_tasktemplate, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_tasktemplate, tablename => 'TBL_TASKTEMPLATE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    --set assumed success message  
    IF v_id IS NOT NULL THEN
      v_Text := 'Updated {{MESS_TITLE}} of custom page';
    ELSE
      v_Text := 'Created {{MESS_TITLE}} of custom page';
    END IF;
    --:SuccessResponse := :SuccessResponse || ' ' || v_title || ' of custom page';
    v_result := LOC_i18n(MessageText => v_Text, MessageResult => :SuccessResponse, MessageParams => NES_TABLE(Key_Value('MESS_TITLE', v_title)));
  
    --determine correct properties for page type 
    IF (v_elementid IS NOT NULL AND v_rawtype IS NOT NULL) THEN
      IF v_rawtype = 'FORM' THEN
        v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_elementid, tablename => 'TBL_FOM_FORM');
        IF v_errorcode > 0 THEN
          GOTO cleanup;
        END IF;
        v_form := v_elementid;
      ELSIF v_rawtype = 'MDM_FORM' THEN
        v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_elementid, tablename => 'TBL_MDM_FORM');
        IF v_errorcode > 0 THEN
          GOTO cleanup;
        END IF;
        v_mdm_form := v_elementid;
      ELSIF v_rawtype = 'APPBASE_PAGE' THEN
        v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_elementid, tablename => 'VW_UTIL_DEPLOYEDPAGE');
        IF v_errorcode > 0 THEN
          GOTO cleanup;
        END IF;
        v_pagecode := v_elementid;
        /*        ELSIF v_rawtype = 'CODED_PAGE' THEN
        v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                               errormessage => v_errormessage,
                               id           => v_elementid,
                               tablename    => 'TBL_FOM_CODEDPAGE');
        IF v_errorcode > 0 THEN
          GOTO cleanup;
        END IF;
        v_codedpage := v_elementid;*/
      
      ELSIF (v_rawtype = 'PAGE') THEN
        v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_elementid, tablename => 'TBL_FOM_PAGE');
        IF v_errorcode > 0 THEN
          GOTO cleanup;
        END IF;
        v_page := v_elementid;
      END IF;
    ELSE
      v_errorCode    := 122;
      v_errorMessage := 'TARGET_ELEMENTID or TARGET_RAWTYPE can not be empty';
      GOTO cleanup;
    END IF;
  
    -- get PageTypeId
    IF NVL(v_pagetype, 0) = 0 THEN
      v_pagetype := f_util_getidbycode(code => v_pagetype_code, tablename => 'tbl_dict_assocpagetype');
    END IF;
  
    --add new record if one does not exist yet 
    IF v_id IS NULL THEN
    
      --calculate order 
      IF (UPPER(v_pagetype_code) IN ('NEW', 'PORTAL_NEW')) THEN
        BEGIN
          IF NVL(v_partytype, 0) > 0 THEN
            SELECT MAX(ta.col_order)
              INTO v_max
              FROM tbl_assocpage ta
             WHERE ta.col_partytypeassocpage = v_partytype
               AND ta.col_assocpageassocpagetype = v_pagetype;
          ELSIF NVL(v_documenttype, 0) > 0 THEN
            SELECT MAX(ta.col_order)
              INTO v_max
              FROM tbl_assocpage ta
             WHERE ta.col_assocpagedict_doctype = v_documenttype
               AND ta.col_assocpageassocpagetype = v_pagetype;
          ELSIF NVL(v_casesystype, 0) > 0 THEN
            SELECT MAX(ta.col_order)
              INTO v_max
              FROM tbl_assocpage ta
             WHERE ta.col_assocpagedict_casesystype = v_casesystype
               AND ta.col_assocpageassocpagetype = v_pagetype;
          ELSIF NVL(v_workactivitytype, 0) > 0 THEN
            SELECT MAX(ta.col_order)
              INTO v_max
              FROM tbl_assocpage ta
             WHERE ta.COL_DICT_WATYPEASSOCPAGE = v_workactivitytype
               AND ta.col_assocpageassocpagetype = v_pagetype;
          ELSIF NVL(v_tasksystype, 0) > 0 THEN
            SELECT MAX(ta.col_order)
              INTO v_max
              FROM tbl_assocpage ta
             WHERE ta.col_assocpagedict_tasksystype = v_tasksystype
               AND ta.col_assocpageassocpagetype = v_pagetype;
          ELSIF NVL(v_tasktemplate, 0) > 0 THEN
            SELECT MAX(ta.col_order)
              INTO v_max
              FROM tbl_assocpage ta
             WHERE ta.col_assocpagetasktemplate = v_tasktemplate
               AND ta.col_assocpageassocpagetype = v_pagetype;
          END IF;
        
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_pagetype := NULL;
            v_max      := 0;
          WHEN TOO_MANY_ROWS THEN
            v_pagetype := NULL;
            v_max      := 0;
        END;
      
        v_calculated_order := v_max + 1;
      ELSE
        v_calculated_order := NULL;
      END IF;
    
      INSERT INTO tbl_assocpage
        (col_code,
         col_order,
         col_title,
         col_description,
         col_pagecode,
         col_assocpageform,
         col_assocpagecodedpage,
         col_assocpagepage,
         col_assocpageassocpagetype,
         col_assocpagedict_casesystype,
         col_dict_watypeassocpage,
         col_assocpagedict_tasksystype,
         col_assocpagetasktemplate,
         col_partytypeassocpage,
         col_pageparams,
         col_assocpagedict_doctype,
         col_assocpagemdm_form)
      VALUES
        (sys_guid(),
         v_calculated_order,
         v_title,
         v_rawtype,
         v_pagecode,
         v_form,
         v_codedpage,
         v_page,
         v_pagetype,
         v_casesystype,
         v_workactivitytype,
         v_tasksystype,
         v_tasktemplate,
         v_partytype,
         v_pageparams,
         v_documenttype,
         v_mdm_form)
      RETURNING col_id INTO v_id;
    
    ELSE
      --set the values in the record 
      UPDATE tbl_assocpage
         SET col_isdeleted              = NVL(v_isdeleted, 0),
             col_title                  = v_title,
             col_description            = v_rawtype,
             col_pagecode               = v_pagecode,
             col_assocpageform          = v_form,
             col_assocpagecodedpage     = v_codedpage,
             col_assocpagepage          = v_page,
             col_assocpageassocpagetype = v_pagetype,
             col_pageparams             = v_pageparams,
             col_assocpagemdm_form      = v_mdm_form
       WHERE col_id = v_id;
    END IF;
  
    :affectedRows := 1;
    :recordId     := v_id;
  EXCEPTION
    WHEN OTHERS THEN
      :SuccessResponse := '';
      :affectedRows    := 0;
      v_errorcode      := 102;
      v_errormessage   := substr(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
