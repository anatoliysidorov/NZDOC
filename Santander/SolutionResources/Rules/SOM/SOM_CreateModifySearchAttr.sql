DECLARE
  v_Id                TBL_SOM_SEARCHATTR.COL_ID%TYPE;
  v_Config_Id         TBL_SOM_CONFIG.COL_ID%TYPE;
  v_UIElementType_Id  TBL_SOM_SEARCHATTR.COL_SEARCHATTR_UIELEMENTTYPE%TYPE;
  v_Code              TBL_SOM_SEARCHATTR.COL_CODE%TYPE;
  v_CustomConfig      TBL_SOM_SEARCHATTR.COL_CUSTOMCONFIG%TYPE;
  v_DisplayField      TBL_SOM_SEARCHATTR.COL_DISPLAYFIELD%TYPE;
  v_IsCaseIncensitive TBL_SOM_SEARCHATTR.COL_ISCASEINCENSITIVE%TYPE;
  v_IsLike            TBL_SOM_SEARCHATTR.COL_ISLIKE%TYPE;
  v_IsPredefined      TBL_SOM_SEARCHATTR.COL_ISPREDEFINED%TYPE;
  v_Name              TBL_SOM_SEARCHATTR.COL_NAME%TYPE;
  v_ProcessorCode     TBL_SOM_SEARCHATTR.COL_PROCESSORCODE%TYPE;
  v_SOrder            TBL_SOM_SEARCHATTR.COL_SORDER%TYPE;
  v_ValueField        TBL_SOM_SEARCHATTR.COL_VALUEFIELD%TYPE;
  v_Constant          TBL_SOM_SEARCHATTR.COL_CONSTANT%TYPE;
  v_DefaultValue      TBL_SOM_SEARCHATTR.COL_DEFAULTVALUE%TYPE;
  v_PathLinkId        TBL_SOM_SEARCHATTR.COL_SOM_SEARCHATTRFOM_PATH%TYPE;
  v_LinkType_Code     NVARCHAR2(255 CHAR);
  v_LinkId            NUMBER;
  v_Count             NUMBER;
  v_result            NUMBER;
  v_ErrorCode         NUMBER := 0;
  v_ErrorMessage      NVARCHAR2(255 CHAR) := '';
BEGIN
  v_Id := NVL(:Id, 0);
  v_Config_Id := NVL(:Config_Id, 0);
  v_UIElementType_Id := :UIElementType_Id;
  v_CustomConfig := :CustomConfig;
  v_ProcessorCode := :ProcessorCode;
  v_DisplayField :=  :DisplayField;
  v_ValueField   := :ValueField;
  v_Name := :Name;
  v_Code := :Code;
  v_SOrder := NVL(:SOrder, 0);
  v_IsCaseIncensitive := :IsCaseIncensitive;
  v_IsLike := :IsLike;
  v_LinkType_Code := UPPER(:LinkType_Code);
  v_LinkId := NVL(:LinkId, 0);
  v_PathLinkId := NVL(:PathLinkId, 0);
  v_Constant := NVL(:Constant, 0);
  v_DefaultValue := :DefaultValue;
  v_IsPredefined := NVL(:IsPredefined, 0);
  :SuccessResponse := EMPTY_CLOB();

  -- validation on Id is Exist
  IF (v_id > 0) THEN
    v_result := f_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_Id,
      TableName    => 'TBL_SOM_SEARCHATTR');
    IF (v_errorcode > 0) THEN
      GOTO ErrorException;
    END IF;
  END IF;
  
  IF (v_Config_Id > 0) THEN
    v_result := f_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_Config_Id,
      TableName    => 'TBL_SOM_CONFIG');
    IF (v_errorcode > 0) THEN
      GOTO ErrorException;
    END IF;
  END IF;
  
  IF(v_LinkId = 0) THEN
    v_ErrorCode    := 101;
    v_ErrorMessage := 'LinkId cannot be empty or 0.';
    :SuccessResponse := '';
    GOTO ErrorException;
  END IF;

  IF(v_Id = 0 AND v_Config_Id = 0) THEN
    v_ErrorCode    := 102;
    v_ErrorMessage := 'ConfigId cannot be empty at creation.';
    :SuccessResponse := '';
    GOTO ErrorException;
  END IF;

  IF(v_LinkType_Code IS NULL) THEN
    v_ErrorCode    := 103;
    v_ErrorMessage := 'LinkType_Code cannot be empty';
    :SuccessResponse := '';
    GOTO ErrorException;
  END IF;

  IF (v_Constant <> 0 AND v_DefaultValue IS NULL) 
  THEN
    v_ErrorCode    := 104;
    v_ErrorMessage := 'Default Value cannot be empty when attribute is constant';
    :SuccessResponse := '';
    GOTO ErrorException;
  END IF;
  
  BEGIN
    IF (v_LinkType_Code = 'ATTRIBUTE') 
    THEN
      SELECT COL_CODE
        INTO v_Code
        FROM TBL_FOM_ATTRIBUTE 
       WHERE COL_ID = v_LinkId;
    ELSE
      SELECT COL_CODE 
        INTO v_Code
        FROM TBL_FOM_PATH 
       WHERE COL_ID = v_LinkId;
    END IF;

    SELECT COUNT(*) 
      INTO v_Count
      FROM TBL_SOM_SEARCHATTR
     WHERE COL_CODE = v_Code
       AND COL_SOM_SEARCHATTRSOM_CONFIG = v_Config_Id
       AND NVL(COL_CONSTANT, 0) = v_Constant
       AND COL_ID <> v_Id;

    IF (v_Count <> 0) THEN
      v_ErrorCode := 105;
      IF (v_Constant = 0)  THEN
        v_ErrorMessage  := 'Attribute with code {{MESS_CODE}} already exist.';
      ELSE
        v_ErrorMessage  := 'Constant attribute with code {{MESS_CODE}} already exist.';
      END IF;
      v_result := LOC_I18N(
        MessageText => v_ErrorMessage,
        MessageResult => v_ErrorMessage,
        MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code)));
      :SuccessResponse := '';
      GOTO ErrorException;
    END IF;

    IF (v_Id = 0) THEN --Insert new record
      IF(v_SOrder = 0)
      THEN
        SELECT MAX(COL_SORDER) 
          INTO v_SOrder 
          FROM TBL_SOM_SEARCHATTR
         WHERE COL_SOM_SEARCHATTRSOM_CONFIG = v_Config_Id;
         v_SOrder := NVL(v_SOrder, 0) + 1;
      END IF;
            
      IF(v_LinkType_Code = 'PATH')
      THEN --Link for Path
        INSERT INTO TBL_SOM_SEARCHATTR (
          COL_SOM_SEARCHATTRFOM_PATH,
          COL_SOM_SEARCHATTRSOM_CONFIG,
          COL_SOM_SEARCHATTRFOM_ATTR,
          COL_CODE,
          COL_NAME,
          COL_ISCASEINCENSITIVE,
          COL_SORDER,
          COL_ISLIKE,
          COL_CUSTOMCONFIG,
          COL_VALUEFIELD,
          COL_DISPLAYFIELD,
          COL_PROCESSORCODE,
          COL_SEARCHATTR_UIELEMENTTYPE,
          COL_CONSTANT,
          COL_DEFAULTVALUE,
          COL_ISPREDEFINED
        ) VALUES (
          v_LinkId,
          v_Config_Id,
          NULL,
          v_Code,
          v_Name,
          v_IsCaseIncensitive,
          v_SOrder,
          v_IsLike,
          v_CustomConfig,
          v_ValueField,
          v_DisplayField,
          v_ProcessorCode,
          v_UIElementType_Id,
          v_Constant,
          v_DefaultValue,
          v_IsPredefined
        ) RETURNING COL_ID INTO :recordId;
        :SuccessResponse := 'Created {{MESS_NAME}} Path';
        ELSIF (v_LinkType_Code = 'ATTRIBUTE')
        THEN --Link for attribute
          INSERT INTO TBL_SOM_SEARCHATTR(
            COL_SOM_SEARCHATTRFOM_PATH,
            COL_SOM_SEARCHATTRSOM_CONFIG,
            COL_SOM_SEARCHATTRFOM_ATTR,
            COL_CODE,
            COL_NAME,
            COL_ISCASEINCENSITIVE,
            COL_SORDER,
            COL_ISLIKE,
            COL_CUSTOMCONFIG,
            COL_VALUEFIELD,
            COL_DISPLAYFIELD,
            COL_PROCESSORCODE,
            COL_SEARCHATTR_UIELEMENTTYPE,
            COL_CONSTANT,
            COL_DEFAULTVALUE,
            COL_ISPREDEFINED
          ) VALUES (
            v_PathLinkId,
            v_Config_Id,
            v_LinkId,
            v_Code,
            v_Name,
            v_IsCaseIncensitive,
            v_SOrder,
            v_IsLike,
            v_CustomConfig,
            v_ValueField,
            v_DisplayField,
            v_ProcessorCode,
            v_UIElementType_Id,
            v_Constant,
            v_DefaultValue,
            v_IsPredefined
          ) RETURNING COL_ID INTO :recordId;
          :SuccessResponse := 'Created {{MESS_NAME}} Attribute';
        END IF;
    ELSE --v_Id IS NOT NULL. Update recod
      IF(v_LinkType_Code = 'PATH')
      THEN 
        UPDATE TBL_SOM_SEARCHATTR SET
          COL_SOM_SEARCHATTRFOM_PATH = v_LinkId,
          COL_SOM_SEARCHATTRFOM_ATTR = NULL,
          COL_CODE = v_Code,
          COL_NAME = v_Name,
          COL_ISCASEINCENSITIVE = v_IsCaseIncensitive,
          COL_ISLIKE = v_IsLike,
          COL_CUSTOMCONFIG = v_CustomConfig,
          COL_VALUEFIELD = v_ValueField,
          COL_DISPLAYFIELD = v_DisplayField,
          COL_PROCESSORCODE = v_ProcessorCode,
          COL_SEARCHATTR_UIELEMENTTYPE = v_UIElementType_Id,
          COL_CONSTANT = v_Constant,
          COL_DEFAULTVALUE = v_DefaultValue,
          COL_ISPREDEFINED = v_IsPredefined
        WHERE COL_ID = v_Id;
        :recordId := v_Id;
        :SuccessResponse := 'Updated {{MESS_NAME}} Path';
      ELSIF(v_LinkType_Code = 'ATTRIBUTE')
      THEN
        UPDATE TBL_SOM_SEARCHATTR SET
          COL_SOM_SEARCHATTRFOM_PATH = v_PathLinkId,
          COL_SOM_SEARCHATTRFOM_ATTR = v_LinkId,
          COL_CODE = v_Code,
          COL_NAME = v_Name,
          COL_ISCASEINCENSITIVE = v_IsCaseIncensitive,
          COL_ISLIKE = v_IsLike,
          COL_CUSTOMCONFIG = v_CustomConfig,
          COL_VALUEFIELD = v_ValueField,
          COL_DISPLAYFIELD = v_DisplayField,
          COL_PROCESSORCODE = v_ProcessorCode,
          COL_SEARCHATTR_UIELEMENTTYPE = v_UIElementType_Id,
          COL_CONSTANT = v_Constant,
          COL_DEFAULTVALUE = v_DefaultValue,
          COL_ISPREDEFINED = v_IsPredefined
        WHERE COL_ID = v_Id;
        :recordId := v_Id;
        :SuccessResponse := 'Updated {{MESS_NAME}} Attribute';
      END IF;  
    END IF;
    EXCEPTION
      WHEN OTHERS THEN
        v_ErrorCode    := SQLCODE;
        v_ErrorMessage := '$t(Exception:) ' || SUBSTR(SQLERRM, 1, 200);
        :SuccessResponse := '';
  END;
  v_result := LOC_i18n(
    MessageText => :SuccessResponse,
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name)));
  <<ErrorException>>
  BEGIN 
    :ErrorCode    := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
  END ErrorException;
END;