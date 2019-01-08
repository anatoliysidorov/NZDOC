DECLARE
  v_workitemId   NUMBER;
  v_actionCode   NVARCHAR2(255);
  v_actionName   NVARCHAR2(255);
  v_target       NVARCHAR2(255);
  v_result       NUMBER;
  v_isDeleted    NUMBER;
  v_workbasketId NUMBER;

  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
BEGIN

  -- Input
  v_workitemId := :WorkitemId;
  v_actionCode := UPPER(:ActionCode);

  v_result       := 0;
  v_errorCode    := 0;
  v_errorMessage := '';

  -- get data
  SELECT col_isdeleted, col_pi_workitemppl_workbasket INTO v_isDeleted, v_workbasketId FROM tbl_pi_workitem WHERE col_id = v_workitemId;

  SELECT CASE
           WHEN v_actionCode = 'ATTACH_TO_CASE' THEN
            'root_CS_STATUS_DOCINDEXINGSTATES_REVIEWED'
           WHEN v_actionCode = 'UNATTACH_FROM_CASE' THEN
            'root_CS_STATUS_DOCINDEXINGSTATES_WAITING_FOR_REVIEW'
           ELSE
            ''
         END
    INTO v_target
    FROM dual;

  SELECT CASE
           WHEN v_actionCode = 'ATTACH_TO_CASE' THEN
            'Attach to Case'
           WHEN v_actionCode = 'UNATTACH_FROM_CASE' THEN
            'Unattach from Case'
           ELSE
            ''
         END
    INTO v_actionName
    FROM dual;

  -- validate Attach/Unattach action by security matrix
  v_result := f_DCM_getPIWorkitemAccessFn(IsDeleted => v_isDeleted, PermissionCode => v_actionCode, WorkbasketId => v_workbasketId);
  IF (v_result = 0) THEN
    v_errorCode    := 101;
    v_errorMessage := 'You do not have permission for Document Workitem to ''' || v_actionName || '''.';
    GOTO cleanup;
  END IF;

  -- validate Workitem on State
  v_result := f_pi_workitemroutemanualfn(errorcode => v_errorCode, errormessage => v_errorMessage, target => v_target, workitemid => v_workitemId);
  IF (v_result = 0) THEN
    GOTO cleanup;
  END IF;

  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;

END;