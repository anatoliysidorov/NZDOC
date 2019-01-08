DECLARE
  v_Id            TBL_SOM_RESULTATTR.COL_ID%TYPE;
  v_Config_Id     TBL_SOM_CONFIG.COL_ID%TYPE;
  v_Code          TBL_SOM_RESULTATTR.COL_CODE%TYPE;
  v_CustomConfig  TBL_SOM_RESULTATTR.COL_CUSTOMCONFIG%TYPE;
  v_Name          TBL_SOM_RESULTATTR.COL_NAME%TYPE;
  v_SOrder        TBL_SOM_RESULTATTR.COL_SORDER%TYPE;
  v_PathLinkId    TBL_SOM_RESULTATTR.COL_SOM_RESULTATTRFOM_PATH%TYPE;
  v_IdPpoperty    TBL_SOM_RESULTATTR.COL_IDPROPERTY%TYPE;
  v_IsHidden      TBL_SOM_RESULTATTR.COL_ISHIDDEN%TYPE;
  v_LinkType_Code NVARCHAR2(255 CHAR);
  v_LinkId        NUMBER;
  v_ErrorCode     NUMBER := 0;
  v_ErrorMessage  NVARCHAR2(255 CHAR) := '';
  v_Count         NUMBER;
  v_result        NUMBER;
BEGIN
  v_Id := NVL(:Id, 0);
  v_Config_Id := NVL(:Config_Id, 0);
  v_CustomConfig := :CustomConfig;
  v_Name := :Name;
  :SuccessResponse := EMPTY_CLOB();

  v_SOrder := NVL(:SOrder, 0);
  v_LinkType_Code := UPPER(:LinkType_Code);
  v_LinkId := NVL(:LinkId, 0);
  v_IdPpoperty := NVL(:IdProperty, 0);
  v_IsHidden := NVL(:IsHidden, 0);
  v_PathLinkId := NVL(:PathLinkId, 0);

  -- validation on Id is Exist
  IF (v_Id > 0) THEN
    v_result := f_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_Id,
      TableName    => 'TBL_SOM_RESULTATTR');
    IF (v_ErrorCode > 0) THEN
      GOTO ErrorException;
    END IF;
  END IF;

  IF (v_Config_Id > 0) THEN
    v_result := f_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_Config_Id,
      TableName    => 'TBL_SOM_CONFIG');
    IF (v_ErrorCode > 0) THEN
      GOTO ErrorException;
    END IF;
  END IF;

  IF (v_LinkId = 0) THEN
    v_ErrorCode := 101;
    v_ErrorMessage := 'LinkId cannot be empty.';
    :SuccessResponse := '';
    GOTO ErrorException;
  END IF;

  IF (v_Id = 0 AND v_Config_Id = 0) THEN
    v_ErrorCode := 102;
    v_ErrorMessage := 'ConfigId cannot be empty at creation.';
    :SuccessResponse := '';
    GOTO ErrorException;
  END IF;

  IF (v_LinkType_Code IS NULL) THEN
    v_ErrorCode := 103;
    v_ErrorMessage := 'LinkType_Code cannot be empty';
    :SuccessResponse := '';
    GOTO ErrorException;
  END IF;

  BEGIN
    IF (v_LinkType_Code = 'ATTRIBUTE') THEN
      SELECT UPPER(COL_ALIAS)
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
      FROM TBL_SOM_RESULTATTR
     WHERE COL_CODE = v_Code
       AND COL_SOM_RESULTATTRSOM_CONFIG = v_Config_Id
       AND COL_ID <> v_Id;

    IF (v_Count <> 0) THEN
      v_ErrorCode := 104;
      v_result := LOC_I18N(
        MessageText => 'Attribute with code {{MESS_CODE}} already exist.',
        MessageResult => v_ErrorMessage,
        MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code)));
      :SuccessResponse := '';
      GOTO ErrorException;
    END IF;

    IF (v_Id = 0) THEN
      IF (v_SOrder = 0) THEN
        SELECT MAX(COL_SORDER)
          INTO v_SOrder
          FROM TBL_SOM_RESULTATTR
         WHERE COL_SOM_RESULTATTRSOM_CONFIG = v_Config_Id;
        v_SOrder := NVL(v_SOrder, 0) + 1;
      END IF;

      IF (v_LinkType_Code = 'PATH') THEN
        INSERT INTO TBL_SOM_RESULTATTR (
          COL_SOM_RESULTATTRFOM_PATH,
          COL_SOM_RESULTATTRSOM_CONFIG,
          COL_SOM_RESULTATTRFOM_ATTR,
          COL_CODE,
          COL_NAME,
          COL_SORDER,
          COL_IDPROPERTY,
          COL_ISHIDDEN,
          COL_CUSTOMCONFIG
        ) VALUES (
          v_LinkId,
          v_Config_Id,
          NULL,
          v_Code,
          v_Name,
          v_SOrder,
          v_IdPpoperty,
          v_IsHidden,
          v_CustomConfig
        ) RETURNING COL_ID INTO v_Id;
        :recordId := v_Id;
        :SuccessResponse := 'Created {{MESS_NAME}} Path';
      ELSIF (v_LinkType_Code = 'ATTRIBUTE') THEN
        INSERT INTO TBL_SOM_RESULTATTR (
          COL_SOM_RESULTATTRFOM_PATH,
          COL_SOM_RESULTATTRSOM_CONFIG,
          COL_SOM_RESULTATTRFOM_ATTR,
          COL_CODE,
          COL_NAME,
          COL_SORDER,
          COL_IDPROPERTY,
          COL_ISHIDDEN,
          COL_CUSTOMCONFIG
        ) VALUES (
          v_PathLinkId,
          v_Config_Id,
          v_LinkId,
          v_Code,
          v_Name,
          v_SOrder,
          v_IdPpoperty,
          v_IsHidden,
          v_CustomConfig
        ) RETURNING COL_ID INTO v_Id;
        :recordId := v_Id;
        :SuccessResponse := 'Created {{MESS_NAME}} Attribute';
      END IF;
    ELSE --v_Id IS NOT NULL. Update recod
      IF (v_LinkType_Code = 'PATH') THEN
        UPDATE TBL_SOM_RESULTATTR SET
          COL_SOM_RESULTATTRFOM_PATH = v_LinkId,
          COL_SOM_RESULTATTRFOM_ATTR = NULL,
          COL_CODE = v_Code,
          COL_NAME = v_Name,
          COL_IDPROPERTY = v_IdPpoperty,
          COL_ISHIDDEN = v_IsHidden,
          COL_CUSTOMCONFIG = v_CustomConfig
         WHERE COL_ID = v_Id 
     RETURNING COL_SOM_RESULTATTRSOM_CONFIG 
          INTO v_Config_Id;
        :recordId := v_Id;
        :SuccessResponse := 'Updated {{MESS_NAME}} Path';
      ELSIF (v_LinkType_Code = 'ATTRIBUTE') THEN
        UPDATE TBL_SOM_RESULTATTR SET
          COL_SOM_RESULTATTRFOM_PATH = v_PathLinkId,
          COL_SOM_RESULTATTRFOM_ATTR = v_LinkId,
          COL_CODE = v_Code, COL_NAME = v_Name,
          COL_IDPROPERTY = v_IdPpoperty,
          COL_ISHIDDEN = v_IsHidden,
          COL_CUSTOMCONFIG = v_CustomConfig
         WHERE COL_ID = v_Id 
     RETURNING COL_SOM_RESULTATTRSOM_CONFIG 
          INTO v_Config_Id;
        :recordId := v_Id;
        :SuccessResponse := 'Updated {{MESS_NAME}} Attribute';
      END IF;
    END IF;

    IF (v_IdPpoperty <> 0 AND NVL(v_Config_Id, 0) <> 0 AND NVL(v_Id, 0) <> 0)
    THEN
      UPDATE TBL_SOM_RESULTATTR
         SET COL_IDPROPERTY = 0
       WHERE COL_SOM_RESULTATTRSOM_CONFIG = v_Config_Id
         AND COL_ID <> v_Id;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      v_ErrorCode := SQLCODE;
      v_ErrorMessage := '$t(Exception:) ' || SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
  v_result := LOC_i18n(
    MessageText => :SuccessResponse,
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name)));  
<<ErrorException>>
  BEGIN
    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
  END ErrorException;
END;