DECLARE
  v_id             NUMBER;
  v_name           NVARCHAR2(255);
  v_code           NVARCHAR2(255);
  v_isdeleted      NUMBER;
  v_description    NCLOB;
  v_stateconfig_id NUMBER;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id             := :Id;
  v_name           := :NAME;
  v_code           := :Code;
  v_isdeleted      := :IsDeleted;
  v_description    := :Description;
  v_stateconfig_id := :StateConfig_Id;

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  --set success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated';
  ELSE
    :SuccessResponse := 'Created';
  END IF;
  :SuccessResponse := :SuccessResponse || ' ' || v_name || ' task state';

  BEGIN
    --add new record or update existing one 
    IF v_id IS NULL THEN
    
      INSERT INTO TBL_DICT_TASKSTATE
        (col_code,
         col_name,
         col_isdeleted,
         col_description,
         col_stateconfigtaskstate)
      VALUES
        (v_code, v_name, 0, v_description, v_stateconfig_id)
      RETURNING col_id INTO :recordId;
    
      :affectedRows := 1;
    ELSE
      UPDATE TBL_DICT_TASKSTATE
         SET col_code                 = v_code,
             col_name                 = v_name,
             col_description          = v_description,
             col_isdeleted            = v_isdeleted,
             col_stateconfigtaskstate = v_stateconfig_id
       WHERE col_id = v_id;
    
      :affectedRows := 1;
      :recordId     := v_id;
    END IF;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      v_errormessage   := 'There already exists a task state with the code ' ||
                          to_char(v_code);
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