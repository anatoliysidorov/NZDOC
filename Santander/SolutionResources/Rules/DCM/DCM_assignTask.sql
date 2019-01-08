DECLARE
  v_action       NVARCHAR2(255);
  v_taskid       NUMBER;
  v_workbasketid NUMBER;
  v_casepartyid  NUMBER;
  v_note         NVARCHAR2(2000);
  v_result       NUMBER;
  --standard
  v_errorcode       NUMBER;
  v_errormessage    NCLOB;
  v_SuccessResponse NCLOB;
BEGIN
  v_action       := :Action;
  v_taskid       := :Task_Id;
  v_workbasketid := :WorkBasket_Id;
  v_casepartyid  := :CaseParty_Id;
  v_note         := :Note;
  --standard
  v_errorcode    := 0;
  v_errormessage := '';
  v_result       := F_DCM_assignTaskFn(Action          => v_action,
                                       CaseParty_Id    => v_casepartyid,
                                       errorCode       => v_errorCode,
                                       errorMessage    => v_errorMessage,
                                       Note            => v_note,
                                       SuccessResponse => v_SuccessResponse,
                                       Task_Id         => v_taskid,
                                       WorkBasket_Id   => v_workbasketid);
  IF v_errorCode > 0 THEN
    :errorCode       := v_errorCode;
    :errorMessage    := v_errorMessage;
  END IF;
  
  :SuccessResponse := v_SuccessResponse;
EXCEPTION
  WHEN OTHERS THEN
    :errorCode       := 101;
    :errorMessage    := SQLERRM;
    :SuccessResponse := '';
END;