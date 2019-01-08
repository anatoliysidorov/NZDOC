DECLARE
  v_Ids                 NVARCHAR2(32767);
  v_Id                  INTEGER;
  v_countCases          PLS_INTEGER := 0;
  v_countAdHoc          PLS_INTEGER := 0;
  v_countCaseType1      PLS_INTEGER := 0;
  v_countCaseType2      PLS_INTEGER := 0;
  v_countCaseState      PLS_INTEGER := 0;
  v_countDeletedRecords PLS_INTEGER := 0;
  v_temp                TBL_PROCEDURE.COL_NAME%TYPE;
  v_listNotAllowDelete  NVARCHAR2(32767);
  v_isDetailedInfo      BOOLEAN;
  v_ErrorMessage        NCLOB;
  v_MessageParams       NES_TABLE := NES_TABLE();
  v_result              NUMBER;
BEGIN
  :ErrorCode := 0;
  :ErrorMessage := '';
  v_Ids := :Ids;
  v_Id := :Id;
  :SuccessResponse := '';

  IF (v_Ids IS NULL AND v_Id IS NULL)
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

  FOR mRec IN (SELECT COLUMN_VALUE AS id
                 FROM TABLE (ASF_SPLIT(v_Ids, ',')))
  LOOP

    -- Validation
    -- If there is a Case linked to the Procedure
    SELECT COUNT(COL_ID)
      INTO v_countCases
      FROM TBL_CASE
     WHERE COL_PROCEDURECASE = mRec.ID;

    -- If there is a STP_AvailableAdHoc linked to the Procedure
    SELECT COUNT(COL_ID)
      INTO v_countAdHoc
      FROM TBL_STP_AVAILABLEADHOC
     WHERE COL_PROCEDURE = mRec.ID;

    -- If there is a DICT_CaseSysType record linked to the Procedure (either way)
    SELECT COUNT(COL_ID)
      INTO v_countCaseType1
      FROM TBL_DICT_CASESYSTYPE
     WHERE COL_CASESYSTYPEPROCEDURE = mRec.ID;

    SELECT COUNT(p.COL_ID)
      INTO v_countCaseType2
      FROM TBL_PROCEDURE p
      LEFT JOIN TBL_DICT_CASESYSTYPE ct on p.COL_PROCEDUREDICT_CASESYSTYPE = ct.COL_ID
     WHERE p.COL_ID = mRec.ID
       AND ct.COL_ID IS NOT NULL;

    -- If there is a DICT_CaseState record linked to the Procedure
    SELECT COUNT(COL_ID)
      INTO v_countCaseState
      FROM TBL_PROCEDURE
     WHERE COL_ID = mRec.ID
       AND NVL(COL_PROCEDURECASESTATE, 0) > 0;

    IF (v_countCases > 0
        OR v_countAdHoc > 0
        OR v_countCaseType1 > 0
        OR v_countCaseType2 > 0
        OR v_countCaseState > 0)
    THEN
      BEGIN
        SELECT COL_NAME
          INTO v_temp
          FROM TBL_PROCEDURE
         WHERE COL_ID = mRec.ID;

        IF (v_isDetailedInfo) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || '<br>' || v_temp || ' $t(related with:)';
        END IF;

        IF (v_countCases > 0) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || ' $t(MESS_CASES, {"count":' || v_countCases || ', "ns":"Rule" })';
        END IF;

        IF (v_countAdHoc > 0) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || ' $t(MESS_ADHOC, {"count":' || v_countAdHoc || ', "ns":"Rule" })';
        END IF;

        IF (v_countCaseType1 > 0 OR v_countCaseType2 > 0) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || ' $t(MESS_CASE_TYPE, {"count":' || (v_countCaseType1 + v_countCaseType2) || ', "ns":"Rule" })';
        END IF;

        IF (v_countCaseState > 0) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || ' $t(MESS_CASE_STATE, {"count":' || v_countCaseState || ', "ns":"Rule" })';
        END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
      END;
      CONTINUE;
    END IF;

    DELETE FROM TBL_TASKTEMPLATE
          WHERE COL_PROCEDURETASKTEMPLATE = mRec.ID;

    DELETE FROM TBL_PROCEDURE
          WHERE COL_ID = mRec.ID;

    v_countDeletedRecords := v_countDeletedRecords + 1;
  END LOOP;

  --get affected rows
  :affectedRows := v_countDeletedRecords;

  IF (v_listNotAllowDelete IS NOT NULL) THEN
    /*IF (LENGTH(v_listNotAllowDelete) > 255) THEN
      v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 1, 252) || '...';
    END IF;*/
    :ErrorCode := 102;
    IF (v_isDetailedInfo) THEN
      :ErrorMessage := 'Count of deleted Procedurs: {{MESS_COUNT}}'
                    || '<br>List of not deleted Procedure(s): {{MESS_LIST_NOT_DELETED}}';
      v_MessageParams.EXTEND(2);
      v_MessageParams(v_MessageParams.LAST - 1) := Key_Value('MESS_COUNT', v_countDeletedRecords);
      v_MessageParams(v_MessageParams.LAST) := Key_Value('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
    ELSE
      :ErrorMessage := 'You cannot delete this Procedure, because it relates with:{{MESS_LIST_NOT_DELETED}}';
      v_MessageParams.EXTEND(1);
      v_MessageParams(v_MessageParams.LAST) := Key_Value('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
    END IF;
    v_result := LOC_I18N(
      MessageText => :ErrorMessage,
      MessageParams => v_MessageParams,
      DisableEscapeValue => TRUE,
      MessageResult => :ErrorMessage
    );
  ELSE
    v_result := LOC_I18N(
      MessageText => 'Deleted {{MESS_COUNT}} items',
      MessageParams => NES_TABLE(Key_Value('MESS_COUNT', v_countDeletedRecords)),
      MessageResult => :SuccessResponse
    );
  END IF;
END;