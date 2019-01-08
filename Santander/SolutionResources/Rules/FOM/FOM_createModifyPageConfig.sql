DECLARE
  v_id             NUMBER;
  v_pageid         NUMBER;
  v_jsondata       NCLOB;
  v_config         NCLOB;
  v_positionindex  INT;
  v_regionid       INT;
  v_description    NCLOB;
  v_parentid       NUMBER;
  v_isdeletechild  INT;
  v_aotype         INT;
  v_iseditable     INT;
  v_DomAttributeID INT;

  v_formID       NUMBER;
  v_codedPageID  NUMBER;
  v_elementType  NVARCHAR2(255);
  v_elementValue NVARCHAR2(255);
  v_isId         NUMBER;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id             := :Id;
  v_pageid         := :PageId;
  v_jsondata       := :JsonData;
  v_config         := nvl(:Config, '<CustomData><Attributes></Attributes></CustomData>');
  v_positionindex  := :PositionIndex;
  v_regionid       := :RegionId;
  v_description    := :Description;
  v_parentid       := :ParentId;
  v_isdeletechild  := :IsDeleteChild;
  v_iseditable     := :IsEditable;
  v_DomAttributeID := :DOMATTRIBUTEID;

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  v_formID      := NULL;
  v_codedPageID := NULL;

  -- check on require parameters
  IF v_pageid IS NULL THEN
    v_errormessage := 'Page_Id can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  -- validation on Id is Exist
  IF NVL(v_pageid, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_pageid, tablename => 'TBL_FOM_PAGE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;
  IF NVL(v_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, tablename => 'TBL_FOM_UIELEMENT');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  --set success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated element';
  ELSE
    :SuccessResponse := 'Created element';
  END IF;

  --:SuccessResponse := :SuccessResponse || ' element';

  BEGIN
    --custom decode a JSON data
    IF (v_jsondata IS NOT NULL) AND (v_jsondata <> '{}') THEN
    
      --define a type of element
      SELECT REGEXP_SUBSTR(v_jsondata, '\"type\":\"[^\"]+\"', 1, 1) INTO v_elementType FROM dual;
    
      --type is form   
      IF UPPER(v_elementType) = '"TYPE":"FORM"' THEN
        SELECT REGEXP_SUBSTR(v_jsondata, '\"value\":\"[^\"]+\"', 1, 1) INTO v_elementValue FROM dual;
      
        SELECT REGEXP_SUBSTR(v_elementValue, '\":\"[^\"]+\"', 1, 1) INTO v_elementValue FROM dual;
        SELECT REPLACE(REPLACE(v_elementValue, '"', ''), ':', '') INTO v_elementValue FROM dual;
        SELECT NVL(v_elementValue, '') INTO v_elementValue FROM dual;
      
        BEGIN
          SELECT col_id INTO v_formID FROM TBL_FOM_FORM WHERE col_code = v_elementValue;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_formID := NULL;
        END;
      END IF; --eof v_elementType ='"type":"form"'
    
      --type is form and contains a custom code
      IF UPPER(v_elementType) = '"TYPE":"TAB"' THEN
        SELECT REGEXP_SUBSTR(v_jsondata, '\"contentType\":\"[^\"]+\"', 1, 1) INTO v_elementType FROM dual;
        IF UPPER(v_elementType) = '"CONTENTTYPE":"CODEDPAGE"' THEN
          SELECT REGEXP_SUBSTR(v_jsondata, '\"pageCode\":\"[^\"]+\"', 1, 1) INTO v_elementValue FROM dual;
          SELECT REGEXP_SUBSTR(v_elementValue, '\":\"[^\"]+\"', 1, 1) INTO v_elementValue FROM dual;
          SELECT REPLACE(REPLACE(v_elementValue, '"', ''), ':', '') INTO v_elementValue FROM dual;
        
          SELECT NVL(v_elementValue, '') INTO v_elementValue FROM dual;
          BEGIN
            SELECT col_id INTO v_codedPageID FROM TBL_FOM_CODEDPAGE WHERE col_code = v_elementValue;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_codedPageID := NULL;
          END;
        END IF; --'"contentType":"codedpage"'
      END IF; --v_elementType ='"type":"tab"'
    
    END IF; --v_jsondata IS NOT NULL
  
    --add new record or update existing one
    IF v_id IS NULL THEN
    
      INSERT INTO tbl_fom_uielement
        (col_description,
         col_jsondata,
         col_positionindex,
         col_regionid,
         col_uielementpage,
         col_iseditable,
         col_parentid,
         col_code,
         col_formidlist,
         col_codedpageidlist,
         col_config)
      VALUES
        (v_description, v_jsondata, v_positionindex, v_regionid, v_pageid, v_iseditable, v_parentid, sys_guid(), TO_CHAR(v_formID), TO_CHAR(v_codedPageID), v_config)
      RETURNING col_id INTO :recordId;
    
      IF v_DomAttributeID IS NOT NULL THEN
        -- add a relationship between the UI element and the DOM Attribute
        INSERT INTO TBL_UIELEMENT_DOM_ATTRIBUTE (COL_FOM_UIELEMENT_ID, COL_DOM_ATTRIBUTE_ID) VALUES (:recordId, v_DomAttributeID);
      END IF;
    
      --  create a record in the AC_AccessObject table of type AC_AccessObjectType.col_code = "PAGE_ELEMENT"
      v_aotype := f_util_getidbycode(code => 'PAGE_ELEMENT', tablename => 'tbl_ac_accessobjecttype');
    
      INSERT INTO tbl_ac_accessobject
        (col_name, col_code, col_accessobjaccessobjtype, col_accessobjectuielement)
      VALUES
        ('Page element ' || to_char(:recordId), f_UTIL_calcUniqueCode('PAGE_ELEMENT_' || to_char(:recordId), 'tbl_ac_accessobject'), v_aotype, :recordId)
      RETURNING col_id INTO :accessobjectId;
    
      :affectedRows := 1;
    ELSE
      -- delete Child Forms
      IF v_isdeletechild = 1 THEN
        DELETE FROM tbl_ac_acl
         WHERE col_aclaccessobject IN (SELECT col_id FROM tbl_ac_accessobject WHERE col_accessobjectuielement IN (SELECT col_id FROM tbl_fom_uielement WHERE col_parentid = v_id));
        DELETE FROM tbl_ac_accessobject WHERE col_accessobjectuielement IN (SELECT col_id FROM tbl_fom_uielement WHERE col_parentid = v_id);
        DELETE FROM tbl_uielement_dom_attribute WHERE col_fom_uielement_id IN (SELECT uie.COL_ID FROM tbl_fom_uielement uie WHERE uie.col_parentid = v_id);
        DELETE FROM tbl_fom_uielement WHERE col_parentid = v_id;
      END IF;
    
      UPDATE tbl_fom_uielement
         SET col_description     = v_description,
             col_jsondata        = v_jsondata,
             col_positionindex   = v_positionindex,
             col_regionid        = v_regionid,
             col_uielementpage   = v_pageid,
             col_parentid        = v_parentid,
             col_formidlist      = TO_CHAR(v_formID),
             col_codedpageidlist = TO_CHAR(v_codedPageID),
             col_config          = v_config
       WHERE col_id = v_id;
    
      :affectedRows := 1;
      :recordId     := v_id;
    END IF;
  
    -- update Modified data for tbl_FOM_Page
    SELECT col_description INTO v_description FROM tbl_fom_page WHERE col_id = v_pageid;
    UPDATE tbl_fom_page SET col_description = v_description WHERE col_id = v_pageid;
  
  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 102;
      v_errormessage   := SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
