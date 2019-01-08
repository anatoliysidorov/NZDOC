DECLARE
  v_Id              TBL_FOM_WIDGET.COL_ID%TYPE;
  v_col_Type        TBL_FOM_WIDGET.COL_TYPE%TYPE;
  v_col_Name        TBL_FOM_WIDGET.COL_NAME%TYPE;
  v_col_Code        TBL_FOM_WIDGET.COL_CODE%TYPE;
  v_col_Category    TBL_FOM_WIDGET.COL_CATEGORY%TYPE;
  v_col_Image       TBL_FOM_WIDGET.COL_IMAGE%TYPE;
  v_col_isDeleted   TBL_FOM_WIDGET.COL_ISDELETED%TYPE;
  v_col_Description TBL_FOM_WIDGET.COL_DESCRIPTION%TYPE;
  v_col_Config      TBL_FOM_WIDGET.COL_CONFIG%TYPE;
  v_Result          NUMBER;
  v_ErrorCode       NUMBER := 0;
  v_ErrorMessage    NVARCHAR2(255 CHAR) := '';
BEGIN
  v_Id := :p_Id;
  v_col_Type := :p_Type;
  v_col_Name := :p_Name;
  v_col_Code := :p_Code;
  v_col_Category := :p_Category;
  v_col_Image := :p_Image;
  v_col_isDeleted := :p_isDeleted;
  v_col_Description := :p_Description;
  v_col_Config := :p_Config;
  :affectedRows := 0;
  -- validation on Id is Exist
  IF (NVL(v_Id, 0) > 0) THEN
    v_Result := f_UTIL_getId(
      errorCode => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id => v_Id,
      TableName => 'TBL_FOM_WIDGET');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;
  BEGIN
    IF (v_Id IS NULL)
    THEN
      INSERT INTO TBL_FOM_WIDGET (
        COL_CODE,
        COL_TYPE,
        COL_NAME,
        COL_CATEGORY,
        COL_IMAGE,
        COL_ISDELETED,
        COL_DESCRIPTION,
        COL_CONFIG
      ) VALUES (
        v_col_Code,
        v_col_Type,
        v_col_Name,
        v_col_Category,
        v_col_Image,
        v_col_isDeleted,
        v_col_Description,
        v_col_Config
      ) RETURNING COL_ID INTO v_Id;
      :SuccessResponse := 'Created {{MESS_NAME}} widget';
    ELSE
      UPDATE TBL_FOM_WIDGET SET
        COL_TYPE = v_col_Type,
        COL_NAME = v_col_Name,
        COL_CATEGORY = v_col_Category,
        COL_IMAGE = v_col_Image,
        COL_ISDELETED = v_col_isDeleted,
        COL_DESCRIPTION = v_col_Description,
        COL_CONFIG = v_col_Config
       WHERE COL_ID = v_Id;
      :SuccessResponse := 'Updated {{MESS_NAME}} widget';
    END IF;
    :affectedRows := SQL%ROWCOUNT;
    :recordId := v_Id;
    v_Result := LOC_i18n(
      MessageText => :SuccessResponse,
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_col_Name))
    );
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      :affectedRows := 0;
      v_ErrorCode := 101;
      v_Result := LOC_i18n(
        MessageText => 'There already exists a widget with the code {{MESS_CODE}}',
        MessageResult => v_ErrorMessage,
        MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_col_Code))
      );
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows := 0;
      v_ErrorCode := 102;
      v_ErrorMessage := SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
<<cleanup>>
  :errorCode := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
END;