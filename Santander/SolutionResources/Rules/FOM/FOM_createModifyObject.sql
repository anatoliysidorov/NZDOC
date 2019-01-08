DECLARE
  --custom 
  v_Id           TBL_FOM_OBJECT.COL_ID%TYPE;
  v_IsDeleted    TBL_FOM_OBJECT.COL_ISDELETED%TYPE;
  v_Name         TBL_FOM_OBJECT.COL_NAME%TYPE;
  v_Code         TBL_FOM_OBJECT.COL_CODE%TYPE;
  v_TableName    TBL_FOM_OBJECT.COL_TABLENAME%TYPE;
  v_Result       NUMBER;
  --standard 
  v_ErrorCode    NUMBER := 0;
  v_ErrorMessage NVARCHAR2(255 CHAR) := '';
BEGIN
  :affectedRows := 0;
  --standard 
  v_Id := :Id;
  v_IsDeleted := :IsDeleted;
  v_Name := :Name;
  v_Code := :Code;
  v_TableName := :TableName;
  :SuccessResponse := EMPTY_CLOB();

  -- validation on Id is Exist
  IF (NVL(v_Id, 0) > 0) THEN
    v_Result := f_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_Id,
      TableName    => 'TBL_FOM_OBJECT');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;
  BEGIN
    IF (v_Id IS NULL) THEN
      v_IsDeleted := 0;
      INSERT INTO TBL_FOM_OBJECT (
        COL_CODE,
        COL_NAME,
        COL_TABLENAME,
        COL_ISDELETED
      ) VALUES (
        v_Code,
        v_Name,
        v_TableName,
        v_IsDeleted
      ) RETURNING COL_ID INTO :recordId;
      :affectedRows := SQL%ROWCOUNT;
      :SuccessResponse := 'Created {{MESS_NAME}} object';
    ELSE
      UPDATE TBL_FOM_OBJECT SET
        COL_NAME = v_Name,
        COL_CODE = v_Code,
        COL_TABLENAME = v_TableName,
        COL_ISDELETED = v_IsDeleted
       WHERE COL_ID = v_Id;
      :affectedRows := SQL%ROWCOUNT;
      :recordId := v_Id;
      :SuccessResponse := 'Updated {{MESS_NAME}} object';
    END IF;
    v_result := LOC_i18n(
      MessageText => :SuccessResponse,
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name))
    );
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      :affectedRows := 0;
      v_ErrorCode := 101;
      v_result := LOC_i18n(
        MessageText => 'There already exists a FOM Object with the name {{MESS_NAME}}',
        MessageResult => v_ErrorMessage,
        MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name))
      );
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows := 0;
      v_ErrorCode := 102;
      v_ErrorMessage := SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

<< cleanup >>
  :errorCode := v_ErrorCode;

  :errorMessage := v_ErrorMessage;
END;