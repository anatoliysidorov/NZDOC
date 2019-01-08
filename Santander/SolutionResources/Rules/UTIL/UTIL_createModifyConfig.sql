DECLARE 
  v_Id             TBL_CONFIG.COL_ID%TYPE;
  v_IsDeletable    TBL_CONFIG.COL_ISDELETABLE%TYPE; 
  v_IsDeleted      TBL_CONFIG.COL_ISDELETED%TYPE; 
  v_Name           TBL_CONFIG.COL_NAME%TYPE;
  v_Value          TBL_CONFIG.COL_VALUE%TYPE;
  v_BigValue       TBL_CONFIG.COL_BIGVALUE%TYPE; 
  v_IsModifiable   TBL_CONFIG.COL_ISMODIFIABLE%TYPE; 
  --standard 
  v_OrigName       TBL_CONFIG.COL_NAME%TYPE;
  v_OrigDeletable  TBL_CONFIG.COL_ISDELETABLE%TYPE;
  v_OrigModifiable TBL_CONFIG.COL_ISMODIFIABLE%TYPE;
  v_Result         NUMBER;
  v_ErrorCode      NUMBER;
  v_ErrorMessage   NCLOB;
BEGIN 
  --custom 
  :affectedRows := 0; 
  v_errorcode := 0; 
  v_errormessage := ''; 
  --standard 
  v_Id := :Id; 
  v_IsDeletable := :IsDeletable; 
  v_IsDeleted := :IsDeleted; 
  v_Name := :Name; 
  v_Value := :Value; 
  v_BigValue := :BigValue;
  v_IsModifiable := :IsModifiable; 

  BEGIN 
    IF(v_IsDeletable IS NULL) THEN v_IsDeletable := 1; END IF;
    IF(v_IsDeleted IS NULL) THEN v_IsDeleted := 0; END IF;
    IF(v_IsModifiable IS NULL) THEN v_IsModifiable := 1; END IF;
       
    -- validation on Id is Exist
    IF NVL(v_id, 0) > 0 THEN
      v_Result := f_UTIL_getId(
        ErrorCode    => v_ErrorCode,
        ErrorMessage => v_ErrorMessage,
        Id           => v_Id,
        TableName    => 'TBL_CONFIG');
      IF (v_ErrorCode > 0) THEN
        GOTO cleanup;
      END IF;
      :SuccessResponse := 'Updated {{MESS_NAME}} config';
    ELSE
      :SuccessResponse := 'Created {{MESS_NAME}} config';
    END IF;
     
    --add new record or update existing one 
    IF (v_Id IS NULL)
    THEN 
      INSERT INTO TBL_CONFIG (
        COL_VALUE,
        COL_NAME,
        COL_ISDELETED,
        COL_ISDELETABLE,
        COL_ISMODIFIABLE,
        COL_BIGVALUE
      ) VALUES (
        v_Value,
        v_Name,
        0,
        1,
        1,
        v_BigValue
      );

      /*SELECT gen_tbl_config.CURRVAL
        INTO :recordId
        FROM dual;*/
      :recordId := gen_tbl_config.CURRVAL;
      UPDATE TBL_CONFIG SET 
        COL_CONFIGID = :recordid
      WHERE COL_ID = :recordid;
      :affectedRows := 1;
    ELSE
      SELECT COL_ISMODIFIABLE, COL_ISDELETABLE, COL_NAME
        INTO v_origmodifiable, v_origdeletable, v_origname
        FROM TBL_CONFIG
       WHERE COL_ID = v_id;
      
      IF (v_origdeletable = 0 AND v_IsDeleted = 1)
      THEN
        v_errorcode := 10;
        v_Result := LOC_i18n(
          MessageText => 'Item {{MESS_NAME}} is system and can not be deleted!',
          MessageResult => v_errormessage,
          MessageParams => NES_TABLE(KEY_VALUE('MESS_NAME', v_origname))
        );
        GOTO cleanup;
      END IF;
      IF (v_origmodifiable = 0)
      THEN
        v_errorcode := 9;
        v_Result := LOC_i18n(
          MessageText => 'Item {{MESS_NAME}} is system and can not be edited!',
          MessageResult => v_errormessage,
          MessageParams => NES_TABLE(KEY_VALUE('MESS_NAME', v_origname))
        );
        GOTO cleanup;
      END IF;
      
      UPDATE TBL_CONFIG SET
        COL_NAME = v_Name,
        COL_VALUE = v_Value,
        COL_ISDELETED = v_IsDeleted,
        COL_ISDELETABLE = v_IsDeletable,
        COL_ISMODIFIABLE = v_IsModifiable,
        COL_BIGVALUE = v_BigValue
       WHERE COL_ID = v_Id;
      :affectedRows := 1;
      :recordId := v_id;
    END IF;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows := 0; 
      v_errorcode := 101; 
      v_Result := LOC_i18n(
        MessageText => 'There already exists a config item with the value {{MESS_VALUE}}',
        MessageResult => v_errormessage,
        MessageParams => NES_TABLE(KEY_VALUE('MESS_VALUE', TO_CHAR(v_value)))
      );
    WHEN OTHERS THEN 
      :affectedRows := 0; 
      v_errorcode := 102; 
      v_errormessage := substr(SQLERRM, 1, 200);
  END;
  v_Result := LOC_i18n(
    MessageText => :SuccessResponse,
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(KEY_VALUE('MESS_NAME', v_Name))
  );
  <<cleanup>>
  :errorCode := v_errorcode;
  :errorMessage := v_errormessage;  
END; 