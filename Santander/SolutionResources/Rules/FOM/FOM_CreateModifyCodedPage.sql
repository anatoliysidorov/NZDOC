DECLARE
  --custom
  v_Id            TBL_FOM_CODEDPAGE.COL_ID%TYPE;
  v_IsDeleted     TBL_FOM_CODEDPAGE.COL_ISDELETED%TYPE;
  v_IsNavMenuItem TBL_FOM_CODEDPAGE.COL_ISNAVMENUITEM%TYPE;
  v_Name          TBL_FOM_CODEDPAGE.COL_NAME%TYPE;
  v_Code          TBL_FOM_CODEDPAGE.COL_NAME%TYPE;
  v_Description   TBL_FOM_CODEDPAGE.COL_DESCRIPTION%TYPE;
  v_PageMarkup    TBL_FOM_CODEDPAGE.COL_PAGEMARKUP%TYPE;
  v_result        NUMBER;
  --standard
  v_ErrorCode     NUMBER := 0;
  v_ErrorMessage  NVARCHAR2(255 CHAR) := '';
BEGIN
  --standard
  :affectedRows := 0;
  --custom
  v_Id            := :Id;
  v_IsDeleted     := NVL(:IsDeleted, 0);
  v_IsNavMenuItem := NVL(:IsNavMenuItem, 0);
  v_Name          := :Name;
  v_Code          := :Code;
  v_Description   := :Description;
  v_PageMarkup    := :PageMarkup;
  :SuccessResponse := EMPTY_CLOB();

  -- validation on Id is Exist
  IF (NVL(v_Id, 0) > 0) THEN
    v_result := f_UTIL_getId(
      errorCode => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id => v_Id,
      TableName => 'TBL_FOM_CODEDPAGE');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;
  BEGIN
    --add new record or update existing one
    IF (v_Id IS NULL) THEN
      INSERT INTO TBL_FOM_CODEDPAGE (
        COL_NAME,
        COL_CODE,
        COL_ISDELETED,
        COL_ISNAVMENUITEM,
        COL_DESCRIPTION,
        COL_PAGEMARKUP
      ) VALUES (
        v_Name,
        v_Code,
        v_IsDeleted,
        v_IsNavMenuItem,
        v_Description,
        v_PageMarkup
      ) RETURNING COL_ID INTO :recordId;
      :affectedRows := SQL%ROWCOUNT;
      :SuccessResponse := 'Created {{MESS_NAME}} coded page';
    ELSE
      UPDATE TBL_FOM_CODEDPAGE SET
        COL_NAME = v_Name,
        COL_ISDELETED = v_IsDeleted,
        COL_ISNAVMENUITEM = v_IsNavMenuItem,
        COL_DESCRIPTION = v_Description,
        COL_PAGEMARKUP = v_PageMarkup
       WHERE COL_ID = v_Id;
      :affectedRows := SQL%ROWCOUNT;
      :recordId := v_Id;
      :SuccessResponse := 'Updated {{MESS_NAME}} coded page';
    END IF;
    v_result := LOC_i18n(
      MessageText => :SuccessResponse,
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name)));
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      :affectedRows := 0;
      v_ErrorCode := 101;
      v_result := LOC_i18n(
        MessageText => 'There already exists a coded page with the code: {{MESS_CODE}}',
        MessageResult => v_ErrorMessage,
        MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code)));
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows := 0;
      v_ErrorCode := 102;
      v_ErrorMessage := '$t(Exception:) ' || SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
<<cleanup>>
  :errorCode := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
END;