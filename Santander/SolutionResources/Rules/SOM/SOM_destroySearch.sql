DECLARE
  v_Id           INTEGER;
  v_affectedRows NUMBER;
  v_result       NUMBER;
  v_Ids          VARCHAR2(32767);
BEGIN
  v_Id             := :Id;
  v_Ids            := :Ids;
  :SuccessResponse := '';
  :ErrorMessage := '';
  :ErrorCode := 0;
  
  IF (v_Id IS NULL AND v_Ids IS NULL) THEN
    :ErrorCode    := 101;
    :ErrorMessage := 'Id can not be empty';
  ELSE
  
    IF (v_Id IS NOT NULL) THEN
      v_Ids := TO_CHAR(v_Id);
    END IF;
  
    DELETE FROM TBL_MDM_SEARCHPAGE WHERE COL_SEARCHPAGESOM_CONFIG IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  
    DELETE FROM TBL_SOM_SEARCHATTR WHERE COL_SOM_SEARCHATTRSOM_CONFIG IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  
	DELETE FROM TBL_SOM_RESULTATTR WHERE COL_SOM_RESULTATTRSOM_CONFIG IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  
    DELETE FROM TBL_SOM_CONFIG WHERE COL_ID IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  
    v_affectedRows := SQL%ROWCOUNT;
  
	v_result := LOC_I18N(MessageText   => 'Deleted {{MESS_COUNT}} items',
                         MessageResult => :SuccessResponse,
                         MessageParams => NES_TABLE(Key_Value('MESS_COUNT', v_affectedRows)));
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    :ErrorCode    := SQLCODE();
    :ErrorMessage := '$t(Exception) ' || SUBSTR(SQLERRM(), 1, 200);  
END;  
