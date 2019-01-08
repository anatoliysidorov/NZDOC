DECLARE
  v_Id           TBL_LTR_LETTERTEMPLATE.COL_ID%TYPE;
  v_Name         TBL_LTR_LETTERTEMPLATE.COL_NAME%TYPE;
  v_Code         TBL_LTR_LETTERTEMPLATE.COL_CODE%TYPE;
  v_Description  TBL_LTR_LETTERTEMPLATE.COL_DESCRIPTION%TYPE;
  v_Markup       TBL_LTR_LETTERTEMPLATE.COL_MARKUP%TYPE;
  v_ErrorCode    NUMBER := 0;
  v_ErrorMessage NCLOB;
  v_Result       NUMBER;
BEGIN
  v_Id := :Id;
  v_Name := :NAME;
  v_Code := :Code;
  v_Description := :Description;
  v_Markup := :Markup;
  :affectedRows := 0;
  :SuccessResponse := EMPTY_CLOB();
  -- validation on Id is Exist
  IF NVL(v_Id, 0) > 0 THEN
    v_Result := f_UTIL_getId(
      errorCode => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id => v_Id,
      TableName => 'TBL_LTR_LETTERTEMPLATE'
    );
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;

  BEGIN
    --add new record or update existing one 
    IF (v_Id IS NULL) THEN
      INSERT INTO TBL_LTR_LETTERTEMPLATE (
        COL_NAME,
        COL_CODE,
        COL_MARKUP,
        COL_DESCRIPTION
      ) VALUES (
        v_Name,
        v_Code,
        v_Markup,
        v_Description
      ) RETURNING COL_ID INTO v_Id;
      :SuccessResponse := 'Created {{MESS_NAME}} Letter Template';
    ELSE
      UPDATE TBL_LTR_LETTERTEMPLATE SET 
        COL_NAME = v_Name,
        COL_DESCRIPTION = v_Description,
        COL_MARKUP = v_Markup
       WHERE COL_ID = v_Id;
      :SuccessResponse := 'Updated {{MESS_NAME}} Letter Template';
    END IF;
    :affectedRows := SQL%ROWCOUNT;
    :recordId := v_Id;
    v_Result := LOC_I18N(
      MessageText => :SuccessResponse,
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name))
    );
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      :affectedRows := 0;
      v_ErrorCode := 101;
      v_Result := LOC_I18N(
        MessageText => 'There already exists a letter template with the code {{MESS_CODE}}',
        MessageResult => v_ErrorMessage,
        MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code))
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