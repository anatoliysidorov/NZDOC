DECLARE
  v_CompletedStatus CONSTANT PLS_INTEGER := 8;
  v_ErrorStatus PLS_INTEGER := 2;
  v_DeleteParam    NVARCHAR2(255);
  v_exec NUMBER;
BEGIN
  :affectedRows := 0;
  :SuccessResponse := EMPTY_CLOB();
  v_DeleteParam := :DELETEPARAM;

  IF (v_DeleteParam <> 'COMPLETED_NOERROR') THEN
    v_ErrorStatus := null;
  END IF;

  DELETE QUEUE_EVENT
   WHERE PROCESSEDSTATUS = v_CompletedStatus
     AND (v_ErrorStatus IS NULL OR (v_ErrorStatus IS NOT NULL AND ERRORSTATUS <> v_ErrorStatus));
  :affectedRows := SQL%ROWCOUNT;
  v_exec := LOC_i18n(
    MessageText => 'Deleted {{MESS_COUNT}} Queue Event',
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(KEY_VALUE('MESS_COUNT', :affectedRows))
  );
END;