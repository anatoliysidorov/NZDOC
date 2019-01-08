DECLARE
  v_Id               TBL_SOM_CONFIG.COL_ID%TYPE;
  v_IsDeleted        TBL_SOM_CONFIG.COL_ISDELETED%TYPE;
  v_Description      TBL_SOM_CONFIG.COL_DESCRIPTION%TYPE;
  v_Name             TBL_SOM_CONFIG.COL_NAME%TYPE;
  v_Code             TBL_SOM_CONFIG.COL_CODE%TYPE;
  v_PrimaryObject_Id TBL_SOM_CONFIG.COL_SOM_CONFIGFOM_OBJECT%TYPE;
  v_DefSort          TBL_SOM_CONFIG.COL_DEFSORTFIELD%TYPE;
  v_DefDirection     TBL_SOM_CONFIG.COL_SORTDIRECTION%TYPE;
  --
  v_result           NUMBER;
  v_count            NUMBER;
  v_ErrorMessage     NVARCHAR2(255 CHAR) := '';
  v_ErrorCode        NUMBER;
  v_successResponse  NVARCHAR2(255 CHAR) := '';
BEGIN
<<MainBlock>>
  BEGIN
    v_Id := NVL(:Id, 0);
    v_IsDeleted := NVL(:IsDeleted, 0);
    v_Description := :Description;
    v_Name := :Name;
    v_Code := :Code;
    v_PrimaryObject_Id := NVL(:PrimaryObject_Id, 0);
    v_DefSort := :DefSort;
    v_DefDirection := NVL(:DefDirection, 'ASC');
    :SuccessResponse := EMPTY_CLOB();

    -- validation on Id is Exist
    IF (v_Id > 0) THEN
      v_result := f_UTIL_getId(
        errorCode    => v_ErrorCode,
        errorMessage => v_ErrorMessage,
        Id           => v_Id,
        TableName    => 'TBL_SOM_CONFIG');
      IF (v_ErrorCode > 0) THEN
        GOTO ErrorBlock;
      END IF;
    END IF;
    --Check for the existence of the object
    IF (v_PrimaryObject_Id = 0) THEN
      v_ErrorCode := 101;
      v_ErrorMessage := 'Primary Object, cannot be empty';
      v_successResponse := '';
      GOTO ErrorBlock;
    ELSE
      SELECT COUNT(*)
        INTO v_count
        FROM TBL_FOM_OBJECT obj
       WHERE obj.COL_ID = v_PrimaryObject_Id;

      IF (v_count = 0)
      THEN
        v_ErrorCode := 102;
        v_result := LOC_I18N(
          MessageText => 'Object with Id {{MESS_OBJID}}, does not found',
          MessageResult => v_ErrorMessage,
          MessageParams => NES_TABLE(Key_Value('MESS_OBJID', v_PrimaryObject_Id)));
        v_successResponse := '';
        GOTO ErrorBlock;
      END IF; -- v_count = 0

      IF (v_Code IS NULL OR LENGTH(v_Code) = 0)
      THEN
        v_ErrorCode := 103;
        v_ErrorMessage := 'Configuration code, cannot be empty';
        v_successResponse := '';
        GOTO ErrorBlock;
      ELSE
        SELECT COUNT(*)
          INTO v_count
          FROM TBL_SOM_CONFIG sConf
         WHERE sConf.COL_CODE = v_Code
           AND sConf.COL_ID <> v_Id;

        IF (v_count <> 0)
        THEN
          v_ErrorCode := 104;
          v_result := LOC_I18N(
            MessageText => 'Configuration with code {{MESS_CODE}} already exists',
            MessageResult => v_ErrorMessage,
            MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code)));
          v_successResponse := '';
          GOTO ErrorBlock;
        END IF; -- v_count = 0

      END IF; -- v_Code IS NULL OR LENGTH(v_Code) == 0

      IF (v_DefSort IS NULL OR LENGTH(v_DefSort) = 0)
      THEN
        v_DefDirection := NULL;
      ELSE
        SELECT COUNT(*)
          INTO v_count
          FROM TBL_FOM_ATTRIBUTE tfa
         WHERE tfa.COL_FOM_ATTRIBUTEFOM_OBJECT = v_PrimaryObject_Id
           AND tfa.COL_CODE = v_DefSort;

        IF (v_count = 0)
        THEN
          v_ErrorCode := 105;
          v_ErrorMessage := 'Attribute for sorting is not found';
          v_successResponse := '';
          GOTO ErrorBlock;
        END IF;
      END IF;

      IF (v_Id = 0)
      THEN
        INSERT INTO TBL_SOM_CONFIG (
          COL_SOM_CONFIGFOM_OBJECT,
          COL_CODE,
          COL_NAME,
          COL_DESCRIPTION,
          COL_ISDELETED,
          COL_DEFSORTFIELD,
          COL_SORTDIRECTION
        ) VALUES (
          v_PrimaryObject_Id,
          v_Code,
          v_Name,
          v_Description,
          v_IsDeleted,
          v_DefSort,
          v_DefDirection
        ) RETURNING COL_ID INTO :recordId;
        v_successResponse := 'Created {{MESS_NAME}} Configuration';
      ELSE
        UPDATE TBL_SOM_CONFIG SET
          COL_SOM_CONFIGFOM_OBJECT = v_PrimaryObject_Id,
          COL_CODE = v_Code,
          COL_NAME = v_Name,
          COL_DESCRIPTION = v_Description,
          COL_ISDELETED = v_IsDeleted,
          COL_DEFSORTFIELD = v_DefSort,
          COL_SORTDIRECTION = v_DefDirection
         WHERE COL_ID = v_Id;
        :recordId := v_Id;
        v_successResponse := 'Updated {{MESS_NAME}} Configuration';
      END IF;
    END IF; -- v_PrimaryObject_Id = 0
  EXCEPTION
    WHEN OTHERS THEN
      v_ErrorCode := SQLCODE();
      v_ErrorMessage := '$(Exception:) ' || SUBSTR(SQLERRM(), 1, 200);
      v_successResponse := '';
      GOTO ErrorBlock;
  END MainBlock;
<<ErrorBlock>>
  BEGIN
    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
    v_result := LOC_i18n(
      MessageText => v_successResponse,
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name)));
  END ErrorBlock;
END;