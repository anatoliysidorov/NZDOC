DECLARE
  v_errorcode     NUMBER;
  v_MessageParams NES_TABLE := NES_TABLE();
  v_errormessage  NVARCHAR2(255);
  v_affectedrows  NUMBER;
  v_result        NUMBER;
  v_id            NUMBER;
BEGIN
  v_errorcode      := 0;
  v_errormessage   := '';
  v_id             := :Id;
  :SuccessResponse := EMPTY_CLOB();

  BEGIN
    -- delete record  
    DELETE FROM tbl_assocpage WHERE col_id = v_id;
    v_affectedrows := SQL%ROWCOUNT;
    v_MessageParams.EXTEND(1);
    v_MessageParams(1) := Key_Value('MESS_COUNT', v_affectedrows);
    v_result := LOC_I18N(MessageText => 'Deleted {{MESS_COUNT}} items', MessageResult => :SuccessResponse, MessageParams => v_MessageParams);
  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode    := 100;
      v_errormessage := SUBSTR(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :errorMessage := v_errorMessage;
  :errorCode    := v_errorCode;
END;