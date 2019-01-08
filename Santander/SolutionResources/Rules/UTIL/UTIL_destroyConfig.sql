DECLARE
  v_Id           TBL_CONFIG.COL_ID%TYPE;
  v_isDeletable  TBL_CONFIG.COL_ISDELETABLE%TYPE;
  v_ErrorCode    NUMBER         := 0;
  v_ErrorMessage NVARCHAR2(255) := ''; 
  v_Result       NUMBER;
BEGIN
  :affectedRows := 0; 
  :SuccessResponse := EMPTY_CLOB();
  v_Id := :Id;
  
  ---Input params check 
  IF (v_Id IS NULL) THEN
    v_Result := LOC_i18n(
      MessageText => 'Id can not be empty',
      MessageResult => v_ErrorMessage
    );
    v_ErrorCode := 101;
  GOTO cleanup;
  END IF;

  ---Check if there are Cases with this priority
  SELECT COL_ISDELETABLE into v_isDeletable
    FROM tbl_config
   WHERE COL_ID = v_Id;

  IF v_IsDeletable = 0 THEN
    v_Result := LOC_i18n(
      MessageText => 'You can not delete this Config Item',
      MessageResult => v_ErrorMessage
    );
    v_ErrorCode := 102;
    GOTO cleanup;
  ELSE
    DELETE FROM tbl_Config
     WHERE col_id = v_Id;
    --get affected rows
    :affectedRows := SQL%ROWCOUNT;
    v_Result := LOC_i18n(
      MessageText => 'Deleted {{MESS_COUNT}} items',
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(KEY_VALUE('MESS_COUNT', :affectedRows))
    );  
  END IF;
  <<cleanup>> 
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode := v_ErrorCode; 
  --DBMS_output.put_line(v_ErrorMessage);
END;