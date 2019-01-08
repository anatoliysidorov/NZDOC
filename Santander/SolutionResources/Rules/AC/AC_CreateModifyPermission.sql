DECLARE
  --custom 
  v_Id          TBL_AC_PERMISSION.COL_ID%TYPE;
  v_TypeId      TBL_AC_ACCESSOBJECTTYPE.COL_ID%TYPE;
  v_Name        TBL_AC_PERMISSION.COL_NAME%TYPE;
  v_Code        TBL_AC_PERMISSION.COL_CODE%TYPE;
  v_Description TBL_AC_PERMISSION.COL_DESCRIPTION%TYPE;
  v_OrderACL    TBL_AC_PERMISSION.COL_ORDERACL%TYPE;
  v_DefaultACL  TBL_AC_PERMISSION.COL_DEFAULTACL%TYPE;
  v_res      NUMBER;
  --standard 
  v_ErrorCode    NUMBER := 0;
  v_ErrorMessage NVARCHAR2(255 CHAR) := '';
BEGIN
  v_Id             := :Id;
  v_TypeId         := :TypeId;
  v_Name           := :NAME;
  v_Code           := :Code;
  v_Description    := :Description;
  v_OrderACL       := :OrderACL;
  v_DefaultACL     := :DefaultACL;
  :affectedRows    := 0;
  :SuccessResponse := EMPTY_CLOB();

  -- validation on Id is Exist
  IF NVL(v_Id, 0) > 0 THEN
    v_res := F_UTIL_getId(errorCode => v_ErrorCode, errorMessage => v_ErrorMessage, Id => v_Id, TableName => 'TBL_AC_PERMISSION');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;
  -- validation on Id is Exist
  IF NVL(v_TypeId, 0) > 0 THEN
    v_res := F_UTIL_getId(errorCode => v_ErrorCode, errorMessage => v_ErrorMessage, Id => v_TypeId, TableName => 'TBL_AC_ACCESSOBJECTTYPE');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;
  BEGIN
    IF (v_Id IS NULL) THEN
      -- validation on same Code
      IF nvl(v_TypeId, 0) > 0 THEN
        v_res := 0;
        SELECT COUNT(col_id)
          INTO v_res
          FROM TBL_AC_PERMISSION
         WHERE col_permissionaccessobjtype = v_TypeId
           AND col_code = v_Code;
        IF (v_res > 0) THEN
          v_ErrorCode := 103;
          v_res    := LOC_i18n(MessageText   => 'There already exists a permission with the code {{MESS_CODE}}',
                                  MessageResult => v_ErrorMessage,
                                  MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code)));
          GOTO cleanup;
        END IF;
      END IF;
    
      INSERT INTO TBL_AC_PERMISSION
        (COL_NAME, COL_CODE, COL_DESCRIPTION, COL_ORDERACL, COL_DEFAULTACL, COL_UCODE, COL_PERMISSIONACCESSOBJTYPE)
      VALUES
        (v_Name, v_Code, v_Description, v_OrderACL, v_DefaultACL, SYS_GUID(), v_TypeId)
      RETURNING COL_ID INTO v_Id;
      :SuccessResponse := 'Created {{MESS_NAME}} permission';
    
    ELSE
      UPDATE TBL_AC_PERMISSION
         SET COL_NAME = v_Name,
             --        COL_CODE = v_Code,
             COL_DESCRIPTION = v_Description,
             COL_ORDERACL    = v_OrderACL,
             COL_DEFAULTACL  = v_DefaultACL
       WHERE COL_ID = v_Id;
      :SuccessResponse := 'Updated {{MESS_NAME}} permission';
    END IF;
    v_res  := LOC_i18n(MessageText   => :SuccessResponse,
                              MessageResult => :SuccessResponse,
                              MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name)));
    :affectedRows := 1;
    :recordId     := v_Id;

    --GENERATE SECURITY CACHE FOR ALL CASE TYPES
    v_res := f_DCM_createCTAccessCache();

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      :affectedRows    := 0;
      v_ErrorCode      := 101;
      v_res         := LOC_i18n(MessageText   => 'There already exists a permission with the value {{MESS_CODE}}',
                                   MessageResult => v_ErrorMessage,
                                   MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_Code)));
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_ErrorCode      := 102;
      v_ErrorMessage   := SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
  <<cleanup>>
  :errorCode    := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
END;
