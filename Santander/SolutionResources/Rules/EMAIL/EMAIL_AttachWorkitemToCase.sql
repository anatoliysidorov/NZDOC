DECLARE
  --INPUT
  v_workitemId NUMBER;
  v_caseId     NUMBER;
  v_result     NUMBER;
  v_WI_Parent  NUMBER;

  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
BEGIN

  -- Input
  v_caseId     := :CaseId;
  v_workitemId := :WorkitemId;

  v_errorCode      := 0;
  v_errorMessage   := '';
  :SuccessResponse := '';

  v_result := f_pi_attachworkitemtocasefn(caseid => v_caseId, errorcode => v_errorCode, errormessage => v_errorMessage, workitemid => v_workitemId);

  IF NVL(v_errorCode, 0) > 0 THEN
    :SuccessResponse := '';
    GOTO cleanup;
  END IF;

  :SuccessResponse := 'Document Workitem was successfully attached to Case';

  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
END;