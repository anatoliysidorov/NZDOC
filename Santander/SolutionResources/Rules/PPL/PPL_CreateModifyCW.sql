DECLARE
  v_caseworker_id NUMBER;
  v_user_id       NUMBER;
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
BEGIN
  :ErrorCode    := 0;
  :ErrorMessage := '';
  :RECORDID     := 0;
  v_user_id     := :UserId;

  -- get UserId by NFS_CODE from Business Event Notification_UpdateUser
  IF (:NFS_CODE IS NOT NULL) THEN
    BEGIN
      SELECT userid INTO v_user_id FROM VW_USERS WHERE CODE = :NFS_CODE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;

  v_caseworker_id := f_ppl_createmodifycwfn(UserId => v_user_id, ExternalId => :ExternalId, ErrorCode => v_errorCode, ErrorMessage => v_errorMessage);

  IF v_errorCode <> 0 THEN
    :ErrorCode    := v_errorCode;
    :ErrorMessage := v_errorMessage;
    ROLLBACK;
  ELSE
    :RECORDID := v_caseworker_id;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    :RECORDID     := NULL;
    :ErrorCode    := 101;
    :ErrorMessage := SQLERRM;
    ROLLBACK;
END;