DECLARE
  v_Id            NUMBER;
  v_ErrorCode     NUMBER := 0;
  v_ErrorMessage  NVARCHAR2(255 CHAR) := '';
  v_result        NUMBER;
BEGIN
  :affectedRows := 0;
  v_Id := :Id;
   
  IF (v_Id IS NULL) THEN
    v_ErrorMessage := 'Id can not be empty';
    v_ErrorCode := 101;
    GOTO cleanup;
  END IF;

  DELETE TBL_FOM_Attribute
   WHERE COL_FOM_ATTRIBUTEFOM_OBJECT = v_Id;
   
  DELETE TBL_FOM_Relationship
  WHERE COL_PARENTFOM_RELFOM_OBJECT = v_Id;
    
  DELETE TBL_FOM_Object
   WHERE COL_ID = v_Id;
 
  --get affected rows
  :affectedRows := SQL%ROWCOUNT; 
  v_result := LOC_I18N(
    MessageText => 'Deleted {{MESS_COUNT}} items',
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_COUNT', :affectedRows)));
  <<cleanup>>
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode := v_ErrorCode;
END;