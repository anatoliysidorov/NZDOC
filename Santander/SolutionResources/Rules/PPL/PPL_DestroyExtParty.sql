DECLARE
  v_Ids                 NVARCHAR2(32767);
  v_Id                  INTEGER;
  v_listNotAllowDelete  NVARCHAR2(4000);
  v_temp                NVARCHAR2(255);
  v_countDeletedRecords INTEGER;
  v_countCaseParty      INTEGER;
  v_countParticipant    INTEGER;
  v_countCasesWB        INTEGER;
  v_countTasksWB        INTEGER;
  v_res_temp            INTEGER;
  v_isDetailedInfo      BOOLEAN;
  v_customdataprocessor NVARCHAR2(255);

BEGIN

  :SuccessResponse      := '';
  v_Ids                 := :Ids;
  v_Id                  := :Id;
  :affectedRows         := 0;
  :ErrorCode            := 0;
  :ErrorMessage         := '';
  v_countDeletedRecords := 0;
  v_countCaseParty      := 0;
  v_countParticipant    := 0;
  v_countCasesWB        := 0;
  v_countTasksWB        := 0;

  --Input param check
  IF v_Ids IS NULL AND v_Id IS NULL THEN
    :ErrorMessage := 'Id can not be empty';
    :ErrorCode    := 101;
    RETURN;
  END IF;

  IF (v_Id IS NOT NULL) THEN
    v_Ids            := TO_CHAR(v_id);
    v_isDetailedInfo := false;
  ELSE
    v_isDetailedInfo := true;
  END IF;

  FOR mRec IN (SELECT COL_ID AS id, COL_NAME as name, COL_EXTERNALPARTYPARTYTYPE as partyTypeId
                 FROM tbl_externalparty
                WHERE COL_ID IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(v_Ids, ',')))) LOOP
  
    v_customdataprocessor := NULL;
  
    -- validation on delete
    SELECT COUNT(*) INTO v_countCaseParty FROM tbl_caseparty WHERE COL_CASEPARTYEXTERNALPARTY = mRec.id;
  
    SELECT COUNT(*) INTO v_countParticipant FROM TBL_PARTICIPANT WHERE COL_PARTICIPANTEXTERNALPARTY = mRec.id;
  
    SELECT COUNT(*)
      INTO v_countCasesWB
      FROM tbl_ppl_workbasket wb
     INNER JOIN tbl_case c
        on c.COL_CASEPPL_WORKBASKET = wb.col_id
     WHERE wb.col_id = (SELECT col_Id
                          FROM TBL_PPL_WORKBASKET
                         WHERE COL_WORKBASKETEXTERNALPARTY = mRec.id
                           AND ROWNUM = 1);
  
    SELECT COUNT(*)
      INTO v_countTasksWB
      FROM tbl_ppl_workbasket wb
     INNER JOIN tbl_task t
        on t.col_taskppl_workbasket = wb.col_id
     WHERE wb.col_id = (SELECT col_Id
                          FROM TBL_PPL_WORKBASKET
                         WHERE COL_WORKBASKETEXTERNALPARTY = mRec.id
                           AND ROWNUM = 1);
  
    IF (v_countCaseParty > 0 OR v_countParticipant > 0 OR v_countCasesWB > 0 OR v_countTasksWB > 0) THEN
      IF (v_isDetailedInfo = true) THEN
        v_listNotAllowDelete := v_listNotAllowDelete || CHR(13) || CHR(10) || mRec.name || ' - ';
      END IF;
    
      IF (v_countCaseParty > 0) THEN
        v_listNotAllowDelete := v_listNotAllowDelete || ' ' || v_countCaseParty || ' Case Party(ies); ';
      END IF;
    
      IF (v_countParticipant > 0) THEN
        v_listNotAllowDelete := v_listNotAllowDelete || ' ' || v_countParticipant || ' Participant(s); ';
      END IF;
    
      IF (v_countCasesWB > 0) THEN
        v_listNotAllowDelete := v_listNotAllowDelete || ' ' || v_countCasesWB || ' Case(s); ';
      END IF;
    
      IF (v_countTasksWB > 0) THEN
        v_listNotAllowDelete := v_listNotAllowDelete || ' ' || v_countTasksWB || ' Task(s); ';
      END IF;
    
      CONTINUE;
    END IF;
  
    v_res_temp := f_doc_destroydocumentfn(case_id                 => NULL,
                                          casetype_id             => NULL,
                                          caseworker_id           => NULL,
                                          errorcode               => :ErrorCode,
                                          errormessage            => :ErrorMessage,
                                          extparty_id             => mRec.id,
                                          ids                     => NULL,
                                          task_id                 => NULL,
                                          team_id                 => NULL,
                                          token_domain            => f_UTIL_getDomainFn(),
                                          token_useraccesssubject => '@TOKEN_USERACCESSSUBJECT@');
  
    BEGIN
      SELECT col_delcustdataprocessor INTO v_customdataprocessor FROM tbl_dict_partytype WHERE col_id = mRec.partyTypeId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_customdataprocessor := NULL;
    END;
  
    IF (v_customdataprocessor IS NOT NULL) THEN
      v_res_temp := f_DCM_invokeEPCustDataDelPr(ExtPartyId => mRec.id, ProcessorName => v_customdataprocessor);
    END IF;
  
    -- Unlink all related parties
    UPDATE TBL_EXTERNALPARTY SET col_extpartyextparty = NULL WHERE col_extpartyextparty = mRec.id;
  
    DELETE FROM TBL_AC_AccessSubject WHERE col_id = (SELECT col_extpartyaccesssubject FROM tbl_externalparty WHERE col_id = mRec.id);
  
    DELETE FROM TBL_PPL_WORKBASKET WHERE COL_WORKBASKETEXTERNALPARTY = mRec.id;
  
    DELETE FROM TBL_EXTERNALPARTY WHERE col_id = mRec.id;
  
    v_countDeletedRecords := v_countDeletedRecords + 1;
  END LOOP;

  --get affected rows
  :affectedRows := SQL%ROWCOUNT;

  IF (v_listNotAllowDelete IS NOT NULL) THEN
  
    IF (LENGTH(v_listNotAllowDelete) > 255) THEN
      v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 1, 255) || '...';
    END IF;
  
    :ErrorCode := 102;
  
    IF (v_isDetailedInfo = true) THEN
      :ErrorMessage := 'Count of deleted External External Party(ies): ' || v_countDeletedRecords || CHR(13) || CHR(10);
      :ErrorMessage := :ErrorMessage || 'List of not deleted External Party(ies): ' || v_listNotAllowDelete;
    ELSE
      :ErrorMessage := 'You cannot delete this External Party, because it relates with: ' || v_listNotAllowDelete;
    END IF;
  ELSE
    :SuccessResponse := 'Deleted ' || v_countDeletedRecords || ' item(s)';
  END IF;
END;