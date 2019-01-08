DECLARE
  v_Id            NUMBER;
  v_ErrorCode     NUMBER;
  v_ErrorMessage  NVARCHAR2(255); 
  v_result        NUMBER;
BEGIN
  v_ErrorCode := 0; 
  v_ErrorMessage := '';
  :affectedRows := 0; 
  v_Id := :Id;
  
  ---Input params check 
  IF v_Id IS NULL THEN
    v_ErrorMessage := 'Id can not be empty';
    v_ErrorCode := 101;
    GOTO cleanup;
  END IF;

  --Check if there are Cases with this priority
  DELETE tbl_INT_IntegTarget
   WHERE col_id = v_Id;

  --get affected rows
  :affectedRows := SQL%ROWCOUNT;
  v_result := LOC_I18N(
    MessageText => 'Deleted {{MESS_COUNT}} items',
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_COUNT', :affectedRows))
  );
  <<cleanup>> 
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode := v_ErrorCode; 
END;