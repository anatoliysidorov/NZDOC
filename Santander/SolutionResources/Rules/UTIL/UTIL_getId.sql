DECLARE
  v_Id        NVARCHAR2(255);
  v_TableName NVARCHAR2(255);
  v_Count     NUMBER;
  v_Query     VARCHAR2(1000);
  v_Result    NUMBER;
BEGIN
  v_TableName := :TableName;
  v_Id        := :Id;
  v_Count     := 0;

  :errorCode    := 0;
  :errorMessage := '';

  BEGIN
    v_Query := 'begin SELECT count(1) INTO :' || 'v_count FROM ' ||
               v_TableName || ' WHERE col_id = :' || 'Id; end;';
    EXECUTE IMMEDIATE v_Query
      USING OUT v_Count, IN v_Id;
  EXCEPTION
    WHEN OTHERS THEN
      -- Appbase Pages fix
      v_Query := 'begin SELECT count(1) INTO :' || 'v_count FROM ' ||
                 v_TableName || ' WHERE code = :' || 'Id; end;';
      EXECUTE IMMEDIATE v_Query
        USING OUT v_Count, IN v_Id;
  END;

  IF v_Count = 0 THEN
    :errorCode := 100;
    v_Result   := LOC_i18n(MessageText   => 'There is not Id={{MESS_ID}} in the table {{MESS_TABLE_NAME}}',
                           MessageResult => :errorMessage,
                           MessageParams => NES_TABLE(KEY_VALUE('MESS_ID',
                                                                v_Id),
                                                      KEY_VALUE('MESS_TABLE_NAME',
                                                                v_TableName)));
  END IF;
END;