DECLARE
  --custom 
  v_Id           TBL_INT_INTEGTARGET.COL_ID%TYPE;
  v_Code         TBL_INT_INTEGTARGET.COL_CODE%TYPE;
  v_Name         TBL_INT_INTEGTARGET.COL_NAME%TYPE;
  v_IsDeleted    TBL_INT_INTEGTARGET.COL_ISDELETED%TYPE;
  v_Description  TBL_INT_INTEGTARGET.COL_DESCRIPTION%TYPE;
  v_Config       TBL_INT_INTEGTARGET.COL_CONFIG%TYPE;
  --standard 
  v_Result       NUMBER;
  v_ErrorCode    NUMBER := 0;
  v_ErrorMessage NVARCHAR2(255) := '';
BEGIN
  --custom
  v_Id          := :Id;
  v_Code        := :Code;
  v_Name        := :NAME;
  v_IsDeleted   := NVL(:IsDeleted, 0);
  v_Description := :Description;
  v_Config      := :Config;

  --standard
  :affectedRows  := 0;
  :SuccessResponse := EMPTY_CLOB();
  BEGIN
    --Input params check
    IF v_Code IS NULL
    THEN
      v_ErrorCode := 101;
      v_ErrorMessage := 'CODE can not be empty';
      GOTO cleanup;
    END IF;

    -- validation on Id is Exist
    IF NVL(v_Id, 0) > 0
    THEN
      v_Result := F_UTIL_getId(
        errorCode => v_ErrorCode,
        errorMessage => v_ErrorMessage,
        Id => v_Id,
        TableName => 'TBL_INT_INTEGTARGET'
      );
      IF (v_ErrorCode > 0) THEN
        GOTO cleanup;
      END IF;
    END IF;
    --create new record if needed
    IF v_Id IS NULL
    THEN
      INSERT INTO TBL_INT_INTEGTARGET (
        COL_CODE,
        COL_NAME,
        COL_CONFIG,
        COL_DESCRIPTION,
        COL_ISDELETED
      ) VALUES (
        v_Code,
        v_Name,
        v_Config,
        v_Description,
        v_IsDeleted
      ) RETURNING COL_ID INTO v_Id;
      :affectedRows := SQL%ROWCOUNT;
      :SuccessResponse := 'Created {{MESS_NAME}} Integration Configuration';
    ELSE
      UPDATE TBL_INT_INTEGTARGET SET
        COL_NAME = v_Name,
        COL_ISDELETED = v_IsDeleted,
        COL_DESCRIPTION = v_Description,
        COL_CONFIG = v_Config
       WHERE COL_ID = v_Id;
      :affectedRows := SQL%ROWCOUNT;
      :SuccessResponse := 'Updated {{MESS_NAME}} Integration Configuration';
    END IF;
    v_result := LOC_i18n(
      MessageText => :SuccessResponse,
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name))
    );
    :recordId := v_Id;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      :affectedRows := 0;
      v_ErrorCode := 102;
      v_result := LOC_i18n(
        MessageText => 'This configuration already exists "{{MESS_CODE}}"',
        MessageResult => v_ErrorMessage,
        MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code))
      );
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows := 0;
      v_ErrorCode := 103;
      v_ErrorMessage := SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
<<cleanup>>
  :errorCode := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
END;