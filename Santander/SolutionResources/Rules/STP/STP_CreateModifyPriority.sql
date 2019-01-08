DECLARE
  --custom 
  v_id          NUMBER;
  v_isdefault   NUMBER;
  v_isdeleted   NUMBER;
  v_name        NVARCHAR2(255);
  v_value       NUMBER(10, 2);
  v_description NCLOB;
  v_code        NVARCHAR2(255);
  v_isId        NUMBER;

  --standard 
  v_errorcode     NUMBER;
  v_errormessage  NVARCHAR2(255);
  v_MessageParams NES_TABLE;
  v_result        NUMBER;

BEGIN
  --custom 
  v_id          := :Id;
  v_isdefault   := NVL(:IsDefault, 0);
  v_isdeleted   := NVL(:IsDeleted, 0);
  v_name        := :NAME;
  v_value       := :VALUE;
  v_description := :Description;
  v_code        := :Code;

  --standard 
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  --message params
  :mess_name := :NAME;
  :mess_code := :Code;

  -- validation on Id is Exist
  IF NVL(v_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, tablename => 'TBL_STP_PRIORITY');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  --set assumed success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated {{MESS_NAME}} priority';
  ELSE
    :SuccessResponse := 'Created {{MESS_NAME}} priority';
  END IF;

  BEGIN
    --set isDefault to only 1 item 
    IF v_isdefault = 1 THEN
      UPDATE tbl_stp_priority SET col_isdefault = 0 WHERE col_isdefault = 1;
    END IF;
  
    --add new record or update existing one 
    IF v_id IS NULL THEN
      INSERT INTO tbl_stp_priority
        (col_name, col_code, col_value, col_isdefault, col_description, col_isDeleted)
      VALUES
        (v_name, v_code, v_value, v_isdefault, v_description, v_isdeleted)
      RETURNING col_id INTO v_id;
    ELSE
      UPDATE tbl_stp_priority SET col_isdefault = v_isdefault, col_name = v_name, col_value = v_value, col_description = v_description, col_isDeleted = v_isdeleted WHERE col_id = v_id;
    END IF;
  
    :affectedRows := SQL%ROWCOUNT;
    :recordId     := v_id;
  
    v_MessageParams := NES_TABLE();
    v_MessageParams.extend(1);
    v_MessageParams(1) := Key_Value('MESS_NAME', :NAME);
    v_result := LOC_i18n(MessageText => :SuccessResponse, MessageResult => :SuccessResponse, MessageParams => v_MessageParams, MessageParams2 => NULL);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows   := 0;
      :SuccessResponse := '';
      v_errorcode     := 101;
      v_errormessage  := 'There already exists a priority with the code {{MESS_CODE}}';
      v_MessageParams := NES_TABLE();
      v_MessageParams.extend(1);
      v_MessageParams(1) := Key_Value('MESS_CODE', v_code);
      v_result := LOC_i18n(MessageText => :SuccessResponse, MessageResult => :SuccessResponse, MessageParams => v_MessageParams, MessageParams2 => NULL);
    WHEN OTHERS THEN
      :affectedRows    := 0;
      :SuccessResponse := '';
      v_errorcode      := 102;
      v_errormessage   := substr(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
