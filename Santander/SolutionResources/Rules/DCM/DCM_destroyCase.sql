DECLARE
  v_AccessObjectId NUMBER;
  v_CaseTypeId     NUMBER;
  v_res            NUMBER;
  v_Ids            NVARCHAR2(32767);
  v_Id             NUMBER;
  v_errorCode      NUMBER;
  v_errorMessage   NVARCHAR2(255);
  v_executionLog   NCLOB;
  v_message        NCLOB;
  v_isErorrFound   NUMBER;
  v_countOfRemoved NUMBER;

BEGIN
  v_errorCode      := 0;
  v_errorMessage   := '';
  v_AccessObjectId := NULL;
  v_CaseTypeId     := NULL;
  v_Id             := :Id;
  v_Ids            := :Ids;
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

  FOR rec IN (SELECT column_value AS id FROM TABLE(asf_split(v_Ids, ','))) LOOP

    -- get CaseTypeId
    BEGIN
      SELECT col_casedict_casesystype INTO v_CaseTypeId FROM tbl_case WHERE col_id = rec.id;
    EXCEPTION
      WHEN no_data_found THEN
        v_isErorrFound := 1;
        v_message      := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'Case is not found. (CaseId: ' || to_char(rec.id) || ')');
        CONTINUE;
    END;

    IF (v_CaseTypeId IS NULL) THEN
      v_isErorrFound := 1;
      v_message      := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'CaseType is not found. (CaseId: ' || to_char(rec.id) || ')');
      CONTINUE;
    END IF;

    -- get AccessObjectId
    BEGIN
      SELECT Id INTO v_AccessObjectId FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = v_CaseTypeId;
    EXCEPTION
      WHEN no_data_found THEN
        v_isErorrFound := 1;
        v_message      := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'CaseType is not found. (CaseId: ' || to_char(rec.id) || ')');
        CONTINUE;
    END;

    IF (v_AccessObjectId IS NULL) THEN
      v_isErorrFound := 1;
      v_message      := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'AccessObjectId is not found. (CaseId: ' || to_char(rec.id) || ')');
      CONTINUE;
    END IF;

    IF f_dcm_iscasetypedeletealwms(AccessObjectId => v_AccessObjectId) = 1 THEN
      v_res := f_dcm_destroycasefn(errorcode               => v_errorCode,
                                   errormessage            => v_errorMessage,
                                   id                      => rec.id,
                                   token_domain            => f_UTIL_getDomainFn(),
                                   token_useraccesssubject => '@TOKEN_USERACCESSSUBJECT@');

      IF v_errorMessage IS NOT NULL THEN
        v_isErorrFound := 1;
        v_message      := f_UTIL_addToMessage(originalMsg => v_message, newMsg => v_errorMessage || ' (CaseId: ' || to_char(rec.id) || ')');
      ELSE
        v_countOfRemoved := v_countOfRemoved + 1;
        v_message        := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'Case was deleted. (CaseId: ' || to_char(rec.id) || ')');
      END IF;

    ELSE
      v_isErorrFound := 1;
      v_message      := f_UTIL_addToMessage(originalMsg => v_message,
                                            newMsg      => 'You are not have enough rights to delete a Case of this type. (CaseId: ' || to_char(rec.id) || ')');
    END IF;
  END LOOP;

  IF v_isErorrFound <> 0 THEN
    :ErrorCode    := 101;
    :ErrorMessage := 'There are errors in delete case(s). See execution log.';
    :ExecutionLog := v_message;
  ELSE
    v_res := LOC_i18n(MessageText   => 'Deleted {{MESS_COUNT}} items',
                      MessageResult => :SuccessResponse,
                      MessageParams => NES_TABLE(Key_Value('MESS_COUNT', TO_CHAR(v_countOfRemoved))));
  END IF;

END;