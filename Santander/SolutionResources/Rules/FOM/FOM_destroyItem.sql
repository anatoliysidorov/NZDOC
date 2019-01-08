DECLARE
  v_Id            NUMBER;
  v_Type          NVARCHAR2(255 CHAR);
  v_ErrorCode     NUMBER := 0;
  v_ErrorMessage  NVARCHAR2(255 CHAR) := '';
  v_MessageText   NCLOB := 'Deleted {{MESS_COUNT}} items';
  v_MessageParams NES_TABLE := NES_TABLE();
  v_Result        NUMBER;
BEGIN
  :affectedRows  := 0;
  v_Id   := :Id;
  v_Type := lower(:TYPE);

  IF (v_Id IS NULL) THEN
    v_ErrorMessage := 'Id can not be empty';
    v_ErrorCode    := 101;
    GOTO cleanup;
  END IF;

  IF v_Type IS NULL THEN
    v_ErrorMessage := 'Type can not be empty';
    v_ErrorCode    := 102;
    GOTO cleanup;
  END IF;

  IF (v_Type = 'attribute') THEN
    DELETE TBL_FOM_Attribute WHERE COL_ID = v_Id;
    :affectedRows := SQL%ROWCOUNT;
    v_MessageText := 'Deleted {{MESS_COUNT}} attributes';
  END IF;
  IF (v_Type = 'relationship') THEN
    DELETE TBL_FOM_Relationship WHERE COL_ID = v_Id;
    :affectedRows := SQL%ROWCOUNT;
    v_MessageText := 'Deleted {{MESS_COUNT}} relationships';
  END IF;
  v_Result := LOC_I18N(
    MessageText => v_MessageText,
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_COUNT', :affectedRows)));
<<cleanup>>
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode    := v_ErrorCode;
END;  