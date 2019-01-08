DECLARE
  v_Id                  INTEGER;
  v_Ids                 NVARCHAR2(32767);
  v_listNotAllowDelete  NVARCHAR2(32767);
  v_tempName            NVARCHAR2(255);
  count_                NUMBER;
  v_countDeletedRecords INTEGER;
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
  count_ := 0;
  v_countDeletedRecords := 0;

  IF (v_Id IS NULL AND v_Ids IS NULL)
  THEN
    v_result := LOC_I18N(
      MessageText => 'Id can not be empty',
      MessageResult => :ErrorMessage
    );
    :ErrorCode := 101;
    RETURN;
  END IF;

  IF (v_Id IS NOT NULL)
  THEN
    v_Ids := TO_CHAR(v_Id);
    v_isDetailedInfo := FALSE;
  ELSE
    v_isDetailedInfo := TRUE;
  END IF;

  FOR REC IN (SELECT COLUMN_VALUE AS id
                FROM TABLE (ASF_SPLIT(v_Ids, ',')))
  LOOP
    SELECT SUM(cnt)
      INTO count_
      FROM (SELECT COUNT(*) AS cnt
          FROM TBL_CASE
          WHERE COL_STP_RESOLUTIONCODECASE = REC.ID
          UNION ALL
        SELECT COUNT(*)
          FROM TBL_TASK
          WHERE COL_TASKSTP_RESOLUTIONCODE = REC.ID
          UNION ALL
        SELECT COUNT(*)
          FROM TBL_TASKSYSTYPERESOLUTIONCODE
          WHERE COL_TBL_STP_RESOLUTIONCODE = REC.ID
          UNION ALL
        SELECT COUNT(*)
          FROM TBL_CASESYSTYPERESOLUTIONCODE
          WHERE col_casetyperesolutioncode = REC.ID);

    IF (count_ > 0) THEN
      BEGIN
        SELECT COL_NAME
          INTO v_tempName
          FROM TBL_STP_RESOLUTIONCODE
          WHERE COL_ID = REC.ID;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
      END;

      IF (v_tempName IS NOT NULL) THEN
        v_listNotAllowDelete := v_listNotAllowDelete || ', ' || v_tempName;
      END IF;
      CONTINUE;
    END IF;

    DELETE TBL_STP_RESOLUTIONCODE
     WHERE COL_ID = REC.ID;
    v_countDeletedRecords := v_countDeletedRecords + 1;
  END LOOP;

  --get removed rows
  :affectedRows := SQL % ROWCOUNT;

  IF (v_listNotAllowDelete IS NOT NULL)
  THEN
    v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 2, LENGTH(v_listNotAllowDelete));
    :ErrorCode := 102;
    IF (v_isDetailedInfo) THEN
      v_ErrorMessage := 'Count of deleted Resolution Codes: {{MESS_COUNT}}'
                    || '<br>You can''t delete Resolution Code(s): {{MESS_LIST_NOT_DELETED}}'
                    || '<br>There exists a Case Type or Task Type that uses this Resolution Code'
                    || '<br>Remove the link and try again...';
      v_MessageParams.EXTEND(2);
      v_MessageParams(1) := KEY_VALUE('MESS_COUNT', v_countDeletedRecords);
      v_MessageParams(2) := KEY_VALUE('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
    ELSE
      v_ErrorMessage := 'You can''t delete this Resolution Code.' 
                     || '<br>There exists a Case Type or Task Type that uses this Resolution Code'
                     || '<br>Remove the link and try again...';
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