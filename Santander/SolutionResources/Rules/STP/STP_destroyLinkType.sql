DECLARE
  v_id           TBL_DICT_LINKTYPE.COL_ID%TYPE;
  v_errorcode    PLS_INTEGER := 0;
  v_errormessage NVARCHAR2(255) := '';
  v_affectedRows PLS_INTEGER := 0;
  v_result       NUMBER;
BEGIN
  v_id := :Id;
  
  IF (v_id IS NULL) THEN
    v_result := LOC_I18N(
      MessageText => 'Id can not be empty',
      MessageResult => v_errormessage
    );
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;
 
  DELETE tbl_dict_linktype WHERE col_id = v_id;
  v_affectedRows := SQL%ROWCOUNT;
  v_result := LOC_I18N(
    MessageText => 'Deleted {{MESS_COUNT}} items',
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(KEY_VALUE('MESS_COUNT', v_affectedRows))
  );
  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;