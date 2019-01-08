DECLARE
  v_taskId       NUMBER;
  v_ErrorCode    NUMBER;
  v_ErrorMessage NCLOB;
  v_input        CLOB;
  v_InData       CLOB;
  v_outData      CLOB;

BEGIN
  --INPUT
  v_taskId := :TaskId;
  v_input  := :Input;
  v_InData := :InData;

  --INIT
  v_outData      := NULL;
  v_ErrorCode    := 0;
  v_ErrorMessage := NULL;

  UPDATE tbl_task SET COL_TASKPPL_WORKBASKET = f_DCM_getMyPersonalWorkbasket() WHERE col_id = v_taskId;

  <<cleanup>>
  :ErrorCode    := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;

END;