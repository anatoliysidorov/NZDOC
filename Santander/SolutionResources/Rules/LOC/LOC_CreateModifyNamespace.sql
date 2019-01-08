DECLARE
  --custom 
  v_id           NUMBER;
  v_name         NVARCHAR2(255);
  v_description  NCLOB;
  --standard 
  v_errorcode    NUMBER;
  v_errormessage NCLOB;
  v_MessageParams NES_TABLE;
  v_result number;
BEGIN
  --custom 
  v_id          := :Id;
  v_name        := :NAME;
  v_description := :DESCRIPTION;
  --standard 
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  :SuccessResponse := EMPTY_CLOB();

  --set assumed success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated {{MESS_NAME}} namespace';
  ELSE
    :SuccessResponse := 'Created {{MESS_NAME}} namespace';
  END IF;
  
  BEGIN
    --add new record or update existing one 
    IF v_id IS NULL THEN
      INSERT INTO tbl_LOC_Namespace (col_name, col_description, COL_UCODE) VALUES (v_name, v_description, SYS_GUID()) RETURNING col_id INTO v_id;
    ELSE
      UPDATE tbl_LOC_Namespace
      SET col_name = v_name,
          col_description = v_description
      WHERE col_id = v_id;
    END IF;

    :affectedRows := SQL%ROWCOUNT;
    :recordId := v_id;

    v_MessageParams:= NES_TABLE(); 
    v_MessageParams.EXTEND(1);
    v_MessageParams(1) := Key_Value('MESS_NAME', v_name);
    
    v_result := LOC_i18n(
      MessageText => :SuccessResponse,
      MessageResult => :SuccessResponse,
      MessageParams => v_MessageParams,
      MessageParams2 => NULL
    );

  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      v_errormessage   := 'There already exists a namespace with the name {{MESS_NAME}}';
      
      v_MessageParams:= NES_TABLE(); 
      v_MessageParams.EXTEND(1);
      v_MessageParams(1) := Key_Value('MESS_NAME', v_name);
      
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