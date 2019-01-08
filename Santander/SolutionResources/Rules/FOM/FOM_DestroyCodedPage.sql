DECLARE
  v_Id                  INTEGER;
  v_Ids                 NVARCHAR2(32767);
  v_listNotAllowDelete  NVARCHAR2(32767);
  v_tempName            TBL_FOM_CODEDPAGE.COL_NAME%TYPE;
  count_                INTEGER;
  v_countDeletedRecords INTEGER;
  v_isDetailedInfo      BOOLEAN;
  v_result              NUMBER;
BEGIN
  :SuccessResponse := EMPTY_CLOB();
  :ErrorCode := 0;
  :ErrorMessage := '';
  :affectedRows := 0;
  v_Id := :Id;
  v_Ids := :Ids;
  count_ := 0;
  v_countDeletedRecords := 0;

  ---Input params check 
  IF (v_Id IS NULL AND v_Ids IS NULL)
  THEN
    :ErrorMessage := 'Id can not be empty';
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

  FOR mRec IN (SELECT COLUMN_VALUE AS id
      FROM TABLE (ASF_SPLIT(v_Ids, ',')))
  LOOP

    SELECT COUNT(*)
      INTO count_
      FROM TBL_ASSOCPAGE
      WHERE COL_ASSOCPAGECODEDPAGE = mRec.ID
        AND ROWNUM = 1;

    IF (count_ > 0)
    THEN
      BEGIN
        SELECT COL_NAME
          INTO v_tempName
          FROM TBL_FOM_CODEDPAGE
         WHERE COL_ID = mRec.ID;
        v_listNotAllowDelete := v_listNotAllowDelete || ', ' || v_tempName;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
      END;
      CONTINUE;
    END IF;

    DELETE TBL_FOM_CODEDPAGE
      WHERE COL_ID = mRec.ID;

    v_countDeletedRecords := v_countDeletedRecords + 1;

  END LOOP;

  --get affected rows
  :affectedRows := v_countDeletedRecords;

  IF (v_listNotAllowDelete IS NOT NULL)
  THEN
    v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 2, LENGTH(v_listNotAllowDelete));
    :ErrorCode := 102;
    IF (v_isDetailedInfo) THEN
      :ErrorMessage := 'Count of deleted Coded Pages: {{MESS_COUNT}}<br>'
                    || 'You can''t delete Coded Page(s): {{MESS_LIST_NOT_DELETED}}'
                    || '<br>It''s linked to either Task Type or a Case Type'
                    || '<br>Remove the link and try again...';
      v_result := LOC_i18n(
        MessageText => :ErrorMessage,
        MessageResult => :ErrorMessage,
        MessageParams => NES_TABLE(
          Key_Value('MESS_COUNT', v_countDeletedRecords),
          Key_Value('MESS_LIST_NOT_DELETED', v_listNotAllowDelete))
      );
    ELSE
      :ErrorMessage := 'You can''t delete this Coded Page.'
                    || '<br>It''s linked to either Task Type or a Case Type'
                    || '<br>Remove the link and try again...';
    END IF;
  ELSE
    v_result := LOC_i18n(
      MessageText => 'Deleted {{MESS_COUNT}} items',
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_COUNT', v_countDeletedRecords)));
  END IF;
END;