DECLARE
  v_Id                  INTEGER;
  v_Ids                 NVARCHAR2(32767);
  v_listNotAllowDelete  NVARCHAR2(32767);
  v_tempName            TBL_STP_PRIORITY.COL_NAME%TYPE;
  count_                INTEGER := 0;
  v_countDeletedRecords INTEGER := 0;
  v_isDetailedInfo      BOOLEAN;
  v_ErrorMessage        NCLOB;
  v_MessageParams       NES_TABLE := NES_TABLE();
  v_result              NUMBER;
BEGIN
  :SuccessResponse := '';
  :ErrorCode := 0;
  :ErrorMessage := '';
  :affectedRows := 0;
  v_Id := :Id;
  v_Ids := :Ids;
  ---Input params check 
  IF (v_Id IS NULL AND v_Ids IS NULL) THEN
    v_result := LOC_I18N(
      MessageText => 'Id can not be empty',
      MessageResult => :ErrorMessage
    );
    :ErrorCode := 101;
    RETURN;
  END IF;

  IF (v_Id IS NOT NULL) THEN
    v_Ids := TO_CHAR(v_Id);
    v_isDetailedInfo := FALSE;
  ELSE
    v_isDetailedInfo := TRUE;
  END IF;

  FOR mRec IN (SELECT COLUMN_VALUE AS id
                 FROM TABLE (ASF_SPLIT(v_Ids, ',')))
  LOOP
    SELECT COUNT(*)
      INTO count_
      FROM TBL_CASE
     WHERE COL_STP_PRIORITYCASE = mRec.ID;

    IF (count_ > 0) THEN
      BEGIN
        SELECT COL_NAME
          INTO v_tempName
          FROM TBL_STP_PRIORITY
         WHERE COL_ID = mRec.ID;
        v_listNotAllowDelete := v_listNotAllowDelete || ', ' || v_tempName;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
      END;
      CONTINUE;
    END IF;

    DELETE TBL_STP_PRIORITY
     WHERE COL_ID = mRec.ID;
    v_countDeletedRecords := v_countDeletedRecords + 1;
  END LOOP;

  --get affected rows
  :affectedRows := v_countDeletedRecords;

  IF (v_listNotAllowDelete IS NOT NULL)
  THEN
    v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 2, LENGTH(v_listNotAllowDelete));

    IF (LENGTH(v_listNotAllowDelete) > 255)
    THEN
      v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 1, 255) || '...';
    END IF;
    :ErrorCode := 102;
    IF (v_isDetailedInfo) THEN
      v_ErrorMessage := 'Count of deleted  Priorities: {{MESS_COUNT}}'
                     || '<br>You can''t delete Priority(ies): {{MESS_LIST_NOT_DELETED}}'
                     || '<br>There are one or more Cases referencing Priority.'
                     || '<br>Change the Priority value of those Cases and try again.';
      v_MessageParams.EXTEND(2);
      v_MessageParams(1) := KEY_VALUE('MESS_COUNT', v_countDeletedRecords);
      v_MessageParams(2) := KEY_VALUE('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
    ELSE
      v_ErrorMessage := 'You can''t delete this Priority.'
                     || '<br>There are one or more Cases referencing Priority.'
                     || '<br>Change the Priority value of those Cases and try again.';
    END IF;
    v_result := LOC_I18N(
      MessageText => v_ErrorMessage,
      MessageResult => :ErrorMessage,
      MessageParams => v_MessageParams
    );
  ELSE
    v_result := LOC_I18N(
      MessageText => 'Deleted {{MESS_COUNT}} items',
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(KEY_VALUE('MESS_COUNT', v_countDeletedRecords))
    );
  END IF;
END;