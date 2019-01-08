DECLARE
  v_Msg_Code        NVARCHAR2(255);
  v_Code            NVARCHAR2(255);
  v_Msg_Id          NUMBER;
  v_Msg_Type        NUMBER;
  v_Message         NCLOB;
  v_Description     NCLOB;
  v_SuccessResponse NCLOB;
  v_Result          NUMBER;
  v_Count           PLS_INTEGER;
  v_ErrorCode       NUMBER := 0;
  v_ErrorMessage    NVARCHAR2(255 CHAR) := '';
BEGIN
  v_Msg_Id := :Message_Id;
  v_Message := :MessageTemplate;
  v_Code := :Code;
  v_Msg_Type := :MessageType;
  v_Description := :Description;
  :recordId := 0;
  :errorCode := 0;
  :errorMessage := '';
  :affectedRows := 0;
  :SuccessResponse := EMPTY_CLOB();
  v_Result := 0;
  -- validation on Id is Exist
  IF NVL(v_Msg_Id, 0) > 0 THEN
    v_Result := f_UTIL_getId(
      errorCode => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id => v_Msg_Id,
      TableName => 'TBL_MESSAGE'
    );
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF (v_Code IS NULL OR v_Message IS NULL)
  THEN
    v_ErrorCode := 122;
    v_result := LOC_i18n(
      MessageText => 'Code or MessageTemplate must no be empty',
      MessageResult => v_ErrorMessage);
    v_SuccessResponse := '';
  END IF;
  --set assumed success message
  IF v_Msg_Id IS NOT NULL
  THEN
    v_SuccessResponse := 'Updated {{MESS_CODE}} message template';
  ELSE
    v_SuccessResponse := 'Created {{MESS_CODE}} message template';
  END IF;
  v_result := LOC_i18n(
    MessageText => v_SuccessResponse,
    MessageResult => v_SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code))
  );
 

  IF (v_Msg_Id IS NOT NULL)
  THEN
    BEGIN
      SELECT COL_CODE
        INTO v_Msg_Code
        FROM TBL_MESSAGE
        WHERE COL_CODE = v_Code
          AND COL_ID <> v_Msg_Id;
      v_ErrorCode := 101;
      v_result := LOC_i18n(
        MessageText => 'Message template with this code already exists!',
        MessageResult => v_ErrorMessage);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN 
        UPDATE TBL_MESSAGE SET 
          COL_CODE = v_Code,
          COL_MESSAGETYPEMESSAGE = v_Msg_Type,
          COL_TEMPLATE = v_Message,
          COL_DESCRIPTION = v_Description
         WHERE COL_ID = v_Msg_Id;
    END;
  ELSE
    SELECT COUNT(COL_CODE)
      INTO v_Count
      FROM TBL_MESSAGE
      WHERE COL_CODE = v_Code;
    IF (v_Count >= 1)
    THEN
      v_SuccessResponse := '';
      v_ErrorCode := 101;
      v_result := LOC_i18n(
        MessageText => 'Message template with this code already exists!',
        MessageResult => v_ErrorMessage);
    ELSE
      INSERT INTO TBL_MESSAGE (
        COL_CODE,
        COL_MESSAGETYPEMESSAGE,
        COL_TEMPLATE,
        COL_DESCRIPTION
      ) VALUES (
        v_Code,
        v_Msg_Type,
        v_Message,
        v_Description
      ) RETURNING COL_ID INTO v_Msg_Id;
    END IF;
  END IF;
<<cleanup>>
  :errorCode := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
  :SuccessResponse := v_SuccessResponse;
  :recordId := v_Msg_Id;
END;