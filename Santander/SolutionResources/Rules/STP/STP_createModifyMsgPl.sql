DECLARE
  v_Placeholder_Id  TBL_MESSAGEPLACEHOLDER.COL_ID%TYPE;
  v_Placeholder     TBL_MESSAGEPLACEHOLDER.COL_PLACEHOLDER%TYPE;
  v_Plhldr_Id       TBL_MESSAGEPLACEHOLDER.COL_ID%TYPE;
  v_Value           TBL_MESSAGEPLACEHOLDER.COL_VALUE%TYPE;
  v_Description     TBL_MESSAGEPLACEHOLDER.COL_DESCRIPTION%TYPE;
  v_ProcessorCode   TBL_MESSAGEPLACEHOLDER.COL_PROCESSORCODE%TYPE;
  v_SuccessResponse NVARCHAR2(255 CHAR);
  v_Result          NUMBER;
  v_Count           NUMBER;
  v_ErrorCode       NUMBER              := 0;
  v_ErrorMessage    NVARCHAR2(255 CHAR) := '';
BEGIN
  v_Plhldr_Id := :Placeholder_Id;
  v_Value := :p_value;
  :recordId := 0;
  :errorCode := 0;
  v_Placeholder := :p_placeholder;
  v_Description := :p_Description;
  v_ProcessorCode := :p_processorcode;
  :errorMessage := '';
  :affectedRows := 0;
  :SuccessResponse := EMPTY_CLOB();
  -- validation on Id is Exist
  IF NVL(v_Plhldr_Id, 0) > 0 THEN
    v_Result := f_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_Plhldr_Id,
      TableName    => 'TBL_MESSAGEPLACEHOLDER');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF (v_Placeholder IS NULL) THEN
    v_ErrorCode := 122;
    v_ErrorMessage := 'Placeholder name must no be empty';
    v_SuccessResponse := '';
  END IF;
  
  IF (v_Plhldr_Id IS NOT NULL)
  THEN
    BEGIN
      SELECT COL_ID
        INTO v_Placeholder_Id
        FROM TBL_MESSAGEPLACEHOLDER
       WHERE COL_PLACEHOLDER = v_Placeholder
         AND COL_ID <> v_Plhldr_Id;
      v_ErrorCode := 101;
      v_ErrorMessage := 'Message template with this code already exists!';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN 
        UPDATE TBL_MESSAGEPLACEHOLDER SET
          COL_PLACEHOLDER = v_Placeholder,
          COL_PROCESSORCODE = v_ProcessorCode,
          COL_VALUE = v_Value,
          COL_DESCRIPTION = v_Description
         WHERE COL_ID = v_Plhldr_Id;
       :affectedRows := 1;
       v_SuccessResponse := 'Updated {{MESS_NAME}} message placeholder';
    END;
  ELSE
    SELECT COUNT(COL_ID)
      INTO v_Count
      FROM TBL_MESSAGEPLACEHOLDER
      WHERE COL_PLACEHOLDER = v_Placeholder;
    IF (v_Count >= 1) THEN
      v_SuccessResponse := '';
      v_ErrorCode := 101;
      v_ErrorMessage := 'Message placeholder with this code already exists!';
    ELSE
      BEGIN
        INSERT INTO TBL_MESSAGEPLACEHOLDER (
          COL_PLACEHOLDER,
          COL_PROCESSORCODE,
          COL_DESCRIPTION,
          COL_VALUE
        ) VALUES (
          v_Placeholder,
          v_ProcessorCode,
          v_Description,
          v_Value
        ) RETURNING COL_ID INTO v_Plhldr_Id;
        :affectedRows := 1;
        v_SuccessResponse := 'Created {{MESS_NAME}} message placeholder';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN :affectedRows := 0;
        WHEN DUP_VAL_ON_INDEX THEN :affectedRows := 0;
      END;
      :recordId := v_Plhldr_Id;
    END IF;
  END IF;
  v_Result := LOC_i18n(
      MessageText => v_SuccessResponse,
      MessageResult => v_SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Placeholder))
  );
<<cleanup>>
  :errorCode := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
  :SuccessResponse := v_SuccessResponse;
END;