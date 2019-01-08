DECLARE 
  v_QueueId         NUMBER;
  v_Ids             NVARCHAR2(32767);
  v_ErrorCode       NUMBER := 0;
  v_ErrorMessage    NVARCHAR2(255) := 0;
  v_result          NUMBER;
BEGIN
  :affectedRows := 0;
  v_QueueId := :QueueId;
  v_Ids := :Ids;

  ---Input params check
  IF (v_QueueId IS NULL AND v_Ids IS NULL) THEN
    v_result := LOC_I18N(
      MessageText => 'Id can not be empty',
      MessageResult => v_ErrorMessage
    );
    v_ErrorCode := 101;
    GOTO cleanup;
  END IF;

  IF (v_QueueId IS NOT NULL) THEN
    v_Ids := TO_CHAR(v_QueueId);
  END IF;

  BEGIN
    UPDATE QUEUE_EVENT
      SET
	    PROCESSEDSTATUS = 1,
	    PROCESSEDDATE = NULL,
	    ErrorStatus = NULL,
	    Error = NULL,
	    CREATEDDATE = SYSDATE,
	    CREATEDBY = sys_context('CLIENTCONTEXT', 'AccessSubject')
	WHERE QUEUEID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE (ASF_SPLIT(v_Ids, ',')));

        :affectedRows := SQL%ROWCOUNT;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows := -1;
  END;

<<cleanup>>
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode := v_ErrorCode;
END;