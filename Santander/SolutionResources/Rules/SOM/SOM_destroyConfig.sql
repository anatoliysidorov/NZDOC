DECLARE
  v_Id            TBL_SOM_CONFIG.COL_ID%TYPE;
  v_affectedRows  NUMBER;
  v_result        NUMBER;
BEGIN
  v_Id := :Id;
  :SuccessResponse := EMPTY_CLOB();

  IF (v_Id IS NULL) THEN
    :ErrorCode    := 101;
    :ErrorMessage := 'Id can not be empty';
  ELSE
    DELETE FROM TBL_SOM_SEARCHATTR
     WHERE COL_SOM_SEARCHATTRSOM_CONFIG = v_Id;
  
    DELETE FROM TBL_SOM_RESULTATTR
     WHERE COL_SOM_RESULTATTRSOM_CONFIG = v_Id;
  
    DELETE FROM TBL_SOM_CONFIG
     WHERE COL_ID = v_Id;
    v_affectedRows := SQL%ROWCOUNT;

    v_result := LOC_I18N(
      MessageText => 'Deleted {{MESS_COUNT}} items',
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_COUNT', v_affectedRows))
    );
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      :ErrorCode    := SQLCODE();
      :ErrorMessage := '$t(Exception:) ' || SUBSTR(SQLERRM(), 1, 200);
END;