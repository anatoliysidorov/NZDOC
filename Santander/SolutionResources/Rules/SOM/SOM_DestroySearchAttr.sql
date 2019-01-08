DECLARE
  v_Id            TBL_SOM_SEARCHATTR.COL_ID%TYPE;
  v_ConfigID      TBL_SOM_SEARCHATTR.COL_SOM_SEARCHATTRSOM_CONFIG%TYPE;
  v_SOrder        TBL_SOM_SEARCHATTR.COL_SORDER%TYPE;
  v_affectedRows  NUMBER;
  v_result        NUMBER;
BEGIN
  v_Id := :Id;
  :SuccessResponse := EMPTY_CLOB();

  SELECT COL_SOM_SEARCHATTRSOM_CONFIG, 
         COL_SORDER  
    INTO v_ConfigID, 
         v_SOrder
    FROM TBL_SOM_SEARCHATTR
   WHERE COL_ID = v_Id;
  
  DELETE FROM TBL_SOM_SEARCHATTR
   WHERE COL_ID = v_Id;
  v_affectedRows := SQL%ROWCOUNT;

  UPDATE TBL_SOM_SEARCHATTR
     SET COL_SORDER = COL_SORDER - 1
   WHERE COL_SOM_SEARCHATTRSOM_CONFIG = v_ConfigID
     AND COL_SORDER > v_SOrder;
  
  v_result := LOC_I18N(
    MessageText => 'Deleted {{MESS_COUNT}} items',
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_COUNT', v_affectedRows))
  );
  EXCEPTION
    WHEN OTHERS THEN
      :ErrorCode    := SQLCODE;
      :ErrorMessage := '$t(Exception:) ' || SUBSTR(SQLERRM, 1, 200);
END;