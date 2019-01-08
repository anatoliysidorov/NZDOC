DECLARE
  v_QueueId         QUEUE_EVENT.QUEUEID%TYPE;
  v_Ids             NVARCHAR2(32767);
  v_NotDeletedIds   NVARCHAR2(32767);
  v_ProcessedStatus QUEUE_EVENT.PROCESSEDSTATUS%TYPE;
  v_ErrorCode       NUMBER := 0;
  v_ErrorMessage    NVARCHAR2(255) := 0;
  v_result          NUMBER;
BEGIN
  :affectedRows := 0;
  v_QueueId := :QueueId;
  v_Ids := :IDS;
  v_NotDeletedIds := '';

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

  DELETE FROM QUEUE_EVENT
    WHERE processedstatus = 8
      AND queueid IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE (ASF_SPLIT(v_Ids, ',')));
  :affectedRows := SQL%ROWCOUNT;

  SELECT LISTAGG(TO_CHAR(queueid),', ') WITHIN GROUP(ORDER BY queueid)
  INTO v_NotDeletedIds
  FROM QUEUE_EVENT
  WHERE processedstatus <> 8
    AND queueid IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE (ASF_SPLIT(v_Ids, ',')));

  IF (v_NotDeletedIds IS NULL) THEN
    v_result := LOC_i18n(
      MessageText => 'Deleted {{MESS_COUNT}} Queue Event',
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_COUNT', :affectedRows))
    );
  ELSE
    v_result := LOC_i18n(
      MessageText => 'Deleted {{MESS_COUNT}} Queue Event.<br>You can not delete Queue Event(s) {{MESS_NOTDELETED}}<br>because it''s not done processing yet',
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_COUNT', :affectedRows), Key_Value('MESS_NOTDELETED', v_NotDeletedIds))
    );
  END IF;

<<cleanup>>
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode := v_ErrorCode;
END;