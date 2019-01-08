DECLARE
  v_Id     INTEGER;
  v_Ids    NVARCHAR2(32767);
  v_result NUMBER;
BEGIN
  :ErrorCode := 0; 
  :ErrorMessage := '';
  :affectedRows := 0; 
  v_Ids := :Ids;
  v_Id := :Id;
  :SuccessResponse := EMPTY_CLOB();
  
  --Input params check 
  IF v_Id IS NULL AND v_Ids IS NULL THEN
    :ErrorMessage := 'Id can not be empty';
    :ErrorCode := 101;
    RETURN;
  END IF;

  IF(v_Id IS NOT NULL) THEN
    v_Ids := TO_CHAR(v_id);
  END IF;
   
  DELETE FROM TBL_MESSAGE
  WHERE COL_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  :affectedRows := SQL%ROWCOUNT; --Get data from last implicit cursor
  v_result := LOC_I18N(
    MessageText => 'Deleted {{MESS_COUNT}} items',
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_COUNT', :affectedRows)));
END;