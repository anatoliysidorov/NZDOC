DECLARE
  v_id             NUMBER;
  v_name           NVARCHAR2(255);
  v_code           NVARCHAR2(255);
  v_isdeleted      NUMBER;
  v_description    NCLOB;
  v_stateconfig_id NUMBER;
  v_result         NUMBER;
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id             := :Id;
  v_name           := :NAME;
  v_code           := :Code;
  v_isdeleted      := :IsDeleted;
  v_description    := :Description;
  v_stateconfig_id := :StateConfig_Id;
  :SuccessResponse := EMPTY_CLOB();

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  BEGIN
    --add new record or update existing one 
    IF v_id IS NULL THEN
    
      INSERT INTO TBL_DICT_CASESTATE
        (col_code,
         col_name,
         col_isdeleted,
         col_description,
         col_stateconfigcasestate)
      VALUES
        (v_code, v_name, 0, v_description, v_stateconfig_id)
      RETURNING col_id INTO :recordId;
    
      :affectedRows := SQL%ROWCOUNT;
      :SuccessResponse := 'Created {{MESS_NAME}} case state';
    ELSE
      UPDATE TBL_DICT_CASESTATE
         SET col_code                 = v_code,
             col_name                 = v_name,
             col_description          = v_description,
             col_isdeleted            = v_isdeleted,
             col_stateconfigcasestate = v_stateconfig_id
       WHERE col_id = v_id;
       :affectedRows := SQL%ROWCOUNT;
       :recordId     := v_id;
       :SuccessResponse := 'Updated {{MESS_NAME}} case state';
    END IF;
    v_result := LOC_i18n(
        MessageText => :SuccessResponse,
        MessageResult => :SuccessResponse,
        MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_name)));
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      v_result := LOC_i18n(
        MessageText => 'There already exists a case state with the code {{MESS_CODE}}',
        MessageResult => v_errormessage,
        MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_code)));
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