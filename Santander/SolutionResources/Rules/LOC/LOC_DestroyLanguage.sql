DECLARE
  v_Id     INTEGER;
  v_Ids    NVARCHAR2(32767);
  v_result NUMBER;
  v_Count NUMBER;
BEGIN
  :ErrorCode := 0; 
  :ErrorMessage := '';
  :affectedRows := 0; 
  :SuccessResponse := EMPTY_CLOB();
  v_Ids := :Ids;
  v_Id := :Id;

  --Input params check 
  IF v_Id IS NULL AND v_Ids IS NULL THEN
    :ErrorCode := 101;
    v_result := LOC_i18n(
        MessageText => 'Id can not be empty!',
        MessageResult => :ErrorMessage);
    RETURN;
  END IF;
  
  IF(v_Id IS NOT NULL) THEN
    v_Ids := TO_CHAR(v_id);
  END IF;
DBMS_OUTPUT.PUT_LINE(v_Ids);
  --check for default 
  SELECT COUNT(COL_ID)
    INTO v_Count
    FROM TBL_LOC_LANGUAGES
  WHERE NVL(COL_ISDEFAULT, 0) = 1
    AND COL_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  IF (v_Count >= 1)
    THEN
      :ErrorCode := 102;
      v_result := LOC_i18n(
        MessageText => 'You can not delete the default language!',
        MessageResult => :ErrorMessage);
  END IF;
  
  DELETE FROM TBL_LOC_LANGUAGES
  WHERE NVL(COL_ISDEFAULT, 0) <> 1
    AND COL_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  :affectedRows := SQL%ROWCOUNT; --Get data from last implicit cursor
  
  DELETE FROM TBL_LOC_TRANSLATION 
  WHERE col_LangID IN (
    SELECT COL_ID FROM TBL_LOC_LANGUAGES
    WHERE NVL(COL_ISDEFAULT, 0) <> 1
      AND COL_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE(ASF_SPLIT(v_Ids, ','))));
  
  v_result := LOC_I18N(
    MessageText => 'Deleted {{MESS_COUNT}} items',
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_COUNT', :affectedRows)));
END;