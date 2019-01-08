DECLARE
  --INPUT
  v_workitemId   NUMBER;
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
BEGIN
  v_workitemId := :WorkItemId;
  v_errorCode    := 0;
  v_errorMessage := '';
  :SuccessResponse := '';

  BEGIN
    IF v_workitemId IS NULL THEN
      v_errorCode    := 100;
      v_errorMessage := 'WorkItemId can not be NULL';
      GOTO cleanup;
    END IF;

    DELETE FROM TBL_EMAIL_WORKITEM_EXT WHERE COL_EMAIL_WI_PI_WORKITEM = v_workitemId;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      v_errorCode    := 103;
      v_errorMessage := substr(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;

END;
