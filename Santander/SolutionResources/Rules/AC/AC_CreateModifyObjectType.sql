DECLARE
  --custom
  v_Id           TBL_AC_ACCESSOBJECTTYPE.COL_ID%TYPE;
  v_IsDeleted    TBL_AC_ACCESSOBJECTTYPE.COL_ISDELETED%TYPE;
  v_Name         TBL_AC_ACCESSOBJECTTYPE.COL_NAME%TYPE;
  v_Code         TBL_AC_ACCESSOBJECTTYPE.COL_CODE%TYPE;
  v_Description  TBL_AC_ACCESSOBJECTTYPE.COL_DESCRIPTION%TYPE;
  v_Result       NUMBER;
  --standard
  v_errorcode    NUMBER := 0;
  v_errormessage NVARCHAR2(255 CHAR) := '';
BEGIN
  --custom
  v_Id := :Id;
  v_IsDeleted := :IsDeleted;
  v_Name := :Name;
  v_Code := :Code;
  v_Description := :Description;
  :SuccessResponse := EMPTY_CLOB();

  --standard
  :affectedRows := 0;

  -- validation on Id is Exist
  IF NVL(v_Id, 0) > 0
  THEN
    v_Result := F_UTIL_getId(
      errorCode => v_errorcode,
      errorMessage => v_errormessage,
      Id => v_Id,
      TableName => 'TBL_AC_ACCESSOBJECTTYPE');
    IF (v_errorcode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;
  BEGIN
    --add new record or update existing one
    IF (v_Id IS NULL)
    THEN
      v_IsDeleted := 0;
      INSERT INTO TBL_AC_ACCESSOBJECTTYPE (
        COL_NAME,
        COL_CODE,
        COL_DESCRIPTION,
        COL_ISDELETED
      ) VALUES (
        v_Name,
        v_Code,
        v_Description,
        v_IsDeleted
      ) RETURNING COL_ID INTO :recordId;
      :affectedRows := SQL%ROWCOUNT;
      :SuccessResponse := 'Created {{MESS_NAME}} Access Object Type';
    ELSE
      UPDATE TBL_AC_ACCESSOBJECTTYPE SET
        COL_NAME = v_Name,
        COL_CODE = v_Code,
        COL_DESCRIPTION = v_Description,
        COL_ISDELETED = v_IsDeleted
       WHERE COL_ID = v_Id;
      :affectedRows := SQL%ROWCOUNT;
      :SuccessResponse := 'Updated {{MESS_NAME}} Access Object Type';
      :recordId := v_Id;
    END IF;
    v_result := LOC_i18n(
      MessageText => :SuccessResponse,
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name))
    );
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      :affectedRows := 0;
      v_errorcode := 101;
      v_result := LOC_i18n(
        MessageText => 'There already exists a Access Object Type with the value {{MESS_CODE}}',
        MessageResult => v_errormessage,
        MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code))
      );
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows := 0;
      v_errorcode := 102;
      v_errormessage := SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
<< cleanup >>
  :errorCode := v_errorcode;
  :errorMessage := v_errormessage;
END;