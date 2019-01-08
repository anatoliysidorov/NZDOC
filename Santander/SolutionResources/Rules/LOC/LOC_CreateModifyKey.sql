DECLARE
  --custom 
  v_id           NUMBER;
  v_name         NVARCHAR2(255);
  v_context      NVARCHAR2(255);
  v_Description  NCLOB;
  v_IsDeleted    Integer;
  v_IsNew        Integer;
  v_IsPlural     Integer;
  v_NamespaceID  Integer;
  
  --standard 
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
  v_MessageParams NES_TABLE;
  v_result number;
BEGIN
  --custom 
  v_id            := :Id;
  v_name          := trim(:NAME);
  v_context       := trim(:CONTEXT);
  v_Description   := :DESCRIPTION;
  v_IsDeleted     := :ISDELETED;
  v_IsNew         := :ISNEW;
  v_IsPlural      := :ISPLURAL;
  v_NamespaceID   := :NAMESPACEID;
  :SuccessResponse := EMPTY_CLOB();
  --standard 
  :affectedRows   := 0;
  v_errorcode     := 0;
  v_errormessage  := '';
  
  --set assumed success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated key';
  ELSE
    :SuccessResponse := 'Created key';
  END IF;
  
  BEGIN
    --add new record or update existing one 
    IF v_id IS NULL THEN
      INSERT INTO tbl_LOC_Key (
        col_name,
        col_Context,
        col_Description,
        col_IsDeleted,
        col_IsNew,
        col_IsPlural,
        col_NamespaceID,
        COL_UCODE
      ) VALUES (
        v_name,
        v_context,
        v_Description,
        v_IsDeleted,
        v_IsNew,
        v_IsPlural,  
        v_NamespaceID,
        SYS_GUID()
      ) RETURNING col_id INTO v_id;
    ELSE
      IF (v_IsDeleted = 1) THEN
        v_IsNew := 0;
      END IF;
      UPDATE tbl_LOC_Key SET 
        col_name = v_name,
        col_Context = v_context,
        col_Description = v_Description,
        col_IsDeleted = v_IsDeleted,
        col_IsNew = v_IsNew,
        col_IsPlural = v_IsPlural,
        col_NamespaceID = v_NamespaceID
      WHERE col_id = v_id;
    END IF;

    :affectedRows := SQL%ROWCOUNT;
    :recordId := v_id;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      v_errormessage   := 'There already exists a key with' || 
                          ' the name {{MESS_NAME}} and' ||
                          ' context {{MESS_CONTEXT}} and' || 
                          ' namespace ID {{MESS_NAMESPACEID}}';
      v_MessageParams:= NES_TABLE(); 
      v_MessageParams.EXTEND(3);
      v_MessageParams(1) := Key_Value('MESS_NAME', v_name);
      v_MessageParams(2) := Key_Value('MESS_CONTEXT', v_context);
      v_MessageParams(3) := Key_Value('MESS_NAMESPACEID', v_NamespaceID);
      v_result := LOC_i18n(
        MessageText => v_errormessage,
        MessageResult => v_errormessage,
        MessageParams => v_MessageParams,
        MessageParams2 => NULL
      );
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 102;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;