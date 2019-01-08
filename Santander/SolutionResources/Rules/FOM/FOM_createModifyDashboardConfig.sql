DECLARE
  v_Id             TBL_FOM_UIELEMENT.COL_ID%TYPE;
  v_DashboardId    TBL_FOM_DASHBOARD.COL_ID%TYPE;
  v_WidgetId       TBL_FOM_WIDGET.COL_ID%TYPE;
  v_JsonData       TBL_FOM_UIELEMENT.COL_JSONDATA%TYPE;
  v_Description    TBL_FOM_UIELEMENT.COL_DESCRIPTION%TYPE;
  v_AoType         TBL_AC_ACCESSOBJECT.COL_ACCESSOBJACCESSOBJTYPE%TYPE;
  v_RuleVisibility TBL_FOM_UIELEMENT.COL_RULEVISIBILITY%TYPE;

  v_CodedPageID  TBL_FOM_CODEDPAGE.COL_ID%TYPE;
  v_ElementType  NVARCHAR2(255);
  v_ElementValue TBL_FOM_CODEDPAGE.COL_CODE%TYPE;

  v_isId         NUMBER;
  v_ErrorCode    NUMBER;
  v_ErrorMessage NVARCHAR2(255);
BEGIN
  v_Id             := :Id;
  v_DashboardId    := :DashboardId;
  v_WidgetId       := :WidgetId;
  v_JsonData       := :JsonData;
  v_Description    := :Description;
  v_RuleVisibility := :RuleVisibility;
  v_CodedPageID    := NULL;

  :affectedRows  := 0;
  v_ErrorCode    := 0;
  v_ErrorMessage := '';

  -- check on require parameters
  IF (v_DashboardId IS NULL) THEN
    v_ErrorMessage := 'Dashboard_Id can not be empty';
    v_ErrorCode    := 101;
    GOTO cleanup;
  END IF;

  -- validation on Id is Exist
  IF (NVL(v_Id, 0) > 0) THEN
    v_isId := f_UTIL_getId(errorCode    => v_ErrorCode,
                           errorMessage => v_ErrorMessage,
                           Id           => v_Id,
                           TableName    => 'TBL_FOM_UIELEMENT');
    IF v_ErrorCode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF NVL(v_DashboardId, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorCode    => v_ErrorCode,
                           errorMessage => v_ErrorMessage,
                           Id           => v_DashboardId,
                           TableName    => 'TBL_FOM_DASHBOARD');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF (NVL(v_WidgetId, 0) > 0) THEN
    v_isId := f_UTIL_getId(errorCode    => v_ErrorCode,
                           errorMessage => v_ErrorMessage,
                           Id           => v_WidgetId,
                           TableName    => 'TBL_FOM_WIDGET');
    IF v_ErrorCode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  --set success message
  IF v_Id IS NOT NULL THEN
    :SuccessResponse := 'Updated widget';
  ELSE
    :SuccessResponse := 'Created widget';
  END IF;

  BEGIN
    --custom decode a JSON data
    IF (v_JsonData IS NOT NULL) AND (v_JsonData <> '{}') THEN
    
      --define a type of element
      v_ElementType := REGEXP_SUBSTR(v_JsonData, '\"CODEDPAGE_CODE\"', 1, 1);
    
      --type is coded page   
      IF (UPPER(v_ElementType) = '"CODEDPAGE_CODE"') THEN
        v_ElementValue := REGEXP_SUBSTR(v_JsonData,
                                        '"CODEDPAGE_CODE\":\"[^\"]+\"',
                                        1,
                                        1);
        v_ElementValue := REGEXP_SUBSTR(v_ElementValue,
                                        '\":\"[^\"]+\"',
                                        1,
                                        1);
        v_ElementValue := REPLACE(REPLACE(v_ElementValue, '"', ''), ':', '');
        v_ElementValue := NVL(v_ElementValue, '');
      
        BEGIN
          SELECT COL_ID
            INTO v_CodedPageID
            FROM TBL_FOM_CODEDPAGE
           WHERE COL_CODE = v_ElementValue;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_CodedPageID := NULL;
        END;
      END IF; --eof UPPER(v_ElementType) ='"CODEDPAGE_CODE"'
    
    END IF; --v_JsonData IS NOT NULL    
  
    --add new record or update existing one
    IF (v_Id IS NULL) THEN
      INSERT INTO TBL_FOM_UIELEMENT
        (COL_DESCRIPTION,
         COL_JSONDATA,
         COL_UIELEMENTDASHBOARD,
         COL_UIELEMENTWIDGET,
         COL_ISEDITABLE,
         COL_RULEVISIBILITY,
         COL_CODE,
         COL_CODEDPAGEIDLIST)
      VALUES
        (v_Description,
         v_JsonData,
         v_DashboardId,
         v_WidgetId,
         1,
         v_RuleVisibility,
         sys_guid(),
         TO_CHAR(v_CodedPageID))
      RETURNING COL_ID INTO :recordId;
    
      --  create a record in the AC_AccessObject table of type AC_AccessObjectType.col_code = "PAGE_ELEMENT"
      v_AoType := f_util_getidbycode(code      => 'DASHBOARD_ELEMENT',
                                     tablename => 'tbl_ac_accessobjecttype');
    
      INSERT INTO TBL_AC_ACCESSOBJECT
        (COL_NAME,
         COL_CODE,
         COL_ACCESSOBJACCESSOBJTYPE,
         COL_ACCESSOBJECTUIELEMENT)
      VALUES
        ('Dashboard element ' || to_char(:recordId),
         f_UTIL_calcUniqueCode('DASHBOARD_ELEMENT_' || to_char(:recordId), 'tbl_ac_accessobject'),
         v_AoType,
         :recordId)
      RETURNING COL_ID INTO :accessobjectId;
      :affectedRows := 1;
    ELSE
      UPDATE TBL_FOM_UIELEMENT
         SET COL_DESCRIPTION        = v_Description,
             COL_JSONDATA           = v_JsonData,
             COL_UIELEMENTDASHBOARD = v_DashboardId,
             COL_UIELEMENTWIDGET    = v_WidgetId,
             COL_RULEVISIBILITY     = v_RuleVisibility,
             COL_CODEDPAGEIDLIST    = TO_CHAR(v_CodedPageID)
       WHERE col_id = v_Id;
    
      :affectedRows := 1;
      :recordId     := v_Id;
    END IF;
  
    -- get UIElement Code
    select col_code
      into :uielementCode
      from tbl_fom_uielement
     where col_id = :recordId;

    -- get permissions
    :isViewable := f_fom_isuielementallowed(accessobjectid => :accessobjectId, accesstype => 'VIEW', accessobjecttype => 'DASHBOARD_ELEMENT');
    :isEnable := f_fom_isuielementallowed(accessobjectid => :accessobjectId, accesstype => 'ENABLE', accessobjecttype => 'DASHBOARD_ELEMENT');

  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_ErrorCode      := 102;
      v_ErrorMessage   := '$t(Exception:) ' || SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
  <<cleanup>>
  :errorCode    := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
END;