DECLARE
  v_AccessObjectId NUMBER;
  v_res            NUMBER;
  v_Ids            NVARCHAR2(32767);
  v_Id             NUMBER;
  v_CaseId         NUMBER;
  v_errorCode      NUMBER;
  v_errorMessage   NVARCHAR2(255);
  v_executionLog   NCLOB;
  v_message        NCLOB;
  v_additionalInfo NCLOB;
  v_isErorrFound   NUMBER;
  v_countOfRemoved NUMBER;

BEGIN
  v_Id             := :Id;
  v_Ids            := :Ids;
  v_AccessObjectId := NULL;
  v_errorCode      := 0;
  v_errorMessage   := '';
  v_message        := '';
  v_isErorrFound   := 0;
  v_countOfRemoved := 0;
  :ErrorCode       := 0;
  :ErrorMessage    := '';
  :ExecutionLog    := '';
  :SuccessResponse := '';

  --Input params check
  IF v_Id IS NULL AND v_Ids IS NULL THEN
    :ErrorMessage := 'Id can not be empty';
    :ErrorCode    := 101;
    RETURN;
  END IF;

  IF (v_Id IS NOT NULL) THEN
    v_Ids := TO_CHAR(v_id);
  END IF;

  FOR recIds IN (SELECT TO_NUMBER(column_value) AS id FROM TABLE(asf_split(v_Ids, ','))) LOOP
    FOR rec IN (SELECT col_Id AS id, col_Name AS Name
                FROM tbl_task
                start with col_Id = recIds.id
                connect by prior col_ID = col_ParentId
                ORDER BY 1 DESC) LOOP

      --Find Case Id for Case History
      BEGIN
        SELECT col_casetask
        INTO v_CaseId
        FROM tbl_task
        WHERE col_id = rec.id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_CaseId := NULL;
      END;

      --Destroy Task
      v_res := f_DCM_destroyTaskFn(errorcode               => v_errorCode,
                                   errormessage            => v_errorMessage,
                                   id                      => rec.id,
                                   token_domain            => f_UTIL_getDomainFn(),
                                   token_useraccesssubject => '@TOKEN_USERACCESSSUBJECT@');

      IF v_errorMessage IS NOT NULL THEN
        v_isErorrFound := 1;
        v_message      := f_UTIL_addToMessage(originalMsg => v_message, newMsg => v_errorMessage || ' (TaskId: ' || to_char(rec.id) || ')');
      ELSE
        v_countOfRemoved := v_countOfRemoved + 1;
        v_message        := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'Task ' || rec.Name || ' was deleted. (TaskId: ' || to_char(rec.id) || ')');

      END IF;
    END LOOP;
  END LOOP;

  IF v_isErorrFound <> 0 THEN
    :ErrorCode    := 101;
    :ErrorMessage := 'There are errors in delete task(s). See execution log.';
    :ExecutionLog := v_message;
  ELSE
    v_res := LOC_i18n(MessageText   => 'Deleted {{MESS_COUNT}} items',
                      MessageResult => :SuccessResponse,
                      MessageParams => NES_TABLE(Key_Value('MESS_COUNT', TO_CHAR(v_countOfRemoved))));
  END IF;

END;