DECLARE
  --INPUT
  v_CaseId          INT;
  v_TaskId          INT;
  v_ExternalPartyId INT;

  --COUNTS
  v_countTasks            INT;
  v_countCaseDocuments    INT;
  v_countTaskDocuments    INT;
  v_countEPDocuments      INT;
  v_countThreads          INT;
  v_countNotes            INT;
  v_countCaseParties      INT;
  v_countActivities       FLOAT;
  v_countCaseLinks        INT;
  v_countEPCases          INT;
  v_countRelatedEPParties INT;

  --INTERNAL
  v_parentTask  INT;
  v_casetypeid  INT;
  v_tasktypeid  INT;
  v_partytypeid INT;

BEGIN
  --INPUT
  v_CaseId          := NVL(:CaseId, 0);
  v_TaskId          := NVL(:TaskId, 0);
  v_ExternalPartyId := NVL(:ExternalPartyId, 0);

  --SET MISSING INFO
  IF v_TaskId > 0 AND v_CaseId = 0 THEN
    v_CaseId := NVL(f_DCM_getCaseIdByTaskId(v_TaskId), 0);
  END IF;

  --COUNT TASKS AND SUB-TASKS
  IF v_TaskId > 0 THEN
    v_parentTask := v_TaskId;
    v_countTasks := -1; --too compensate for the parent not counting
  ELSIF v_CaseId > 0 THEN
    v_parentTask := NVL(f_DCM_getCaseRootFn(v_CaseId), 0);
    v_countTasks := -1; --too compensate for the root not counting
  ELSE
    v_parentTask := 0;
  END IF;

  IF v_parentTask > 0 THEN
    SELECT v_countTasks + COUNT(col_id) INTO v_countTasks FROM tbl_Task START WITH col_id = v_parentTask CONNECT BY PRIOR col_id = COL_PARENTID;
  ELSE
    v_countTasks := 0;
  END IF;

  --COUNT CASE DOCUMENTS
  v_countCaseDocuments := 0;
  IF v_CaseId > 0 THEN
    v_casetypeid := f_DCM_getCaseTypeForCase(v_CaseId);

    SELECT COUNT(dMap.col_id)
      INTO v_countCaseDocuments
      FROM TBL_DOC_DOCCASE dMap
     INNER JOIN TBL_DOC_DOCUMENT doc
        ON doc.col_id = dMap.COL_DOCCASEDOCUMENT
     WHERE dMap.COL_DOCCASECASE = v_CaseId
       AND NVL(doc.col_isfolder, 0) = 0;

    SELECT COUNT(dMap.col_id) + v_countCaseDocuments
      INTO v_countCaseDocuments
      FROM TBL_DOC_DOCCASETYPE dMap
     INNER JOIN TBL_DOC_DOCUMENT doc
        ON doc.col_id = dMap.COL_DOCCSETYPEDOC
     WHERE dMap.COL_DOCCSETYPETYPE = v_casetypeid
       AND NVL(doc.col_isfolder, 0) = 0;

  END IF;

  --COUNT TASK DOCUMENTS
  v_countTaskDocuments := 0;
  IF v_TaskId > 0 THEN
    SELECT COUNT(dMap.col_id)
      INTO v_countTaskDocuments
      FROM TBL_DOC_DOCTASK dMap
     INNER JOIN TBL_DOC_DOCUMENT doc
        ON doc.col_id = dMap.COL_DOCTASKDOCUMENT
     WHERE dMap.COL_DOCTASKTASK = v_TaskId
       AND NVL(doc.col_isfolder, 0) = 0;
  END IF;

  --COUNT EXTERNAL PARTY DOCUMENTS
  v_countEPDocuments := 0;
  IF v_ExternalPartyId > 0 THEN
    SELECT COUNT(dMap.col_id)
      INTO v_countEPDocuments
      FROM TBL_DOC_DOCEXTPRT dMap
     INNER JOIN TBL_DOC_DOCUMENT doc
        ON doc.col_id = dMap.COL_DOCEXTPRTDOC
     WHERE dMap.COL_DOCEXTPRTEXTPRT = v_ExternalPartyId
       AND NVL(doc.col_isfolder, 0) = 0;
  END IF;

  --COUNT DISCUSSION THREADS (ONLY FOR CASES)
  v_countThreads := 0;
  IF v_CaseId > 0 THEN
    SELECT COUNT(col_id) INTO v_countThreads FROM tbl_THREAD WHERE COL_THREADCASE = v_CaseId;
  END IF;

  --COUNT NOTES
  v_countNotes := 0;
  IF v_TaskId > 0 THEN
    SELECT COUNT(COL_ID) INTO v_countNotes FROM TBL_NOTE WHERE COL_TASKNOTE = v_TaskId;
  ELSIF v_CaseId > 0 THEN
    SELECT COUNT(COL_ID) INTO v_countNotes FROM TBL_NOTE WHERE COL_CASENOTE = v_CaseId;
  ELSIF v_ExternalPartyId > 0 THEN
    SELECT COUNT(COL_ID) INTO v_countNotes FROM TBL_NOTE WHERE COL_EXTERNALPARTYNOTE = v_ExternalPartyId;
  END IF;

  --COUNT PEOPLE IN CASE
  v_countCaseParties := 0;
  IF v_CaseId > 0 THEN
    SELECT COUNT(COL_ID) INTO v_countCaseParties FROM TBL_CASEPARTY WHERE COL_CASEPARTYCASE = v_CaseId;
  END IF;

  --COUNT WORK ACTIVITIES
  v_countActivities := 0;
  IF v_TaskId > 0 THEN
    SELECT SUM(col_hoursspent) INTO v_countActivities FROM TBL_DCM_WORKACTIVITY WHERE COL_WORKACTIVITYTASK = v_TaskId;
  ELSIF v_CaseId > 0 THEN
    SELECT SUM(col_hoursspent) INTO v_countActivities FROM TBL_DCM_WORKACTIVITY WHERE COL_WORKACTIVITYCASE = v_CaseId;
  END IF;

  --COUNT CASES LINKED TOGETHER (CASES ONLY)
  v_countCaseLinks := 0;
  IF v_CaseId > 0 AND v_TaskId = 0 THEN
    SELECT COUNT(COL_ID)
      INTO v_countCaseLinks
      FROM TBL_CASELINK
     WHERE COL_CASELINKPARENTCASE = v_CaseId
        OR COL_CASELINKCHILDCASE = v_CaseId;
  END IF;

/*  --COUNT CASES ASSIGNED TO AN EXTERNAL PARTY
  v_countEPCases := 0;
  IF v_ExternalPartyId > 0 THEN
    SELECT COUNT(c.col_id)
      INTO v_countEPCases
    FROM tbl_Case c
      INNER JOIN TBL_PPL_WORKBASKET wb ON wb.col_id = c.col_caseppl_workbasket AND wb.COL_WORKBASKETEXTERNALPARTY = v_ExternalPartyId;
  END IF;
*/
  --COUNT CASES LINKED TO AN EXTERNAL PARTY via CASE PARTY TABLE
  v_countEPCases := 0;
  IF v_ExternalPartyId > 0 THEN
    SELECT count(DISTINCT c.col_id)
    INTO v_countEPCases
    FROM TBL_CASEPARTY cp
      RIGHT JOIN TBL_CASE c ON c.COL_ID = cp.COL_CASEPARTYCASE
        AND f_dcm_iscasetypeaccessalwms(AccessObjectId => (SELECT Id FROM TABLE(f_dcm_getCaseTypeAOList()) WHERE CaseTypeId = c.COL_CASEDICT_CASESYSTYPE)) = 1
        AND f_dcm_iscasestateallowedms(AccessObjectId => (SELECT Id FROM TABLE(f_dcm_getCaseStateAOList()) WHERE CaseStateId = c.COL_CASEDICT_CASESTATE)) = 1
    WHERE cp.COL_CASEPARTYEXTERNALPARTY = v_ExternalPartyId or c.col_caseppl_workbasket = (select col_id from tbl_ppl_workbasket where COL_WORKBASKETEXTERNALPARTY = v_ExternalPartyId);
  END IF;

  --COUNT RELATED EXTERNAL PARTIES TO AN EXTERNAL PARTY
  v_countRelatedEPParties := 0;
  IF v_ExternalPartyId > 0 THEN
    SELECT COUNT(COL_ID) INTO v_countRelatedEPParties FROM TBL_EXTERNALPARTY WHERE COL_EXTPARTYEXTPARTY = v_ExternalPartyId;
  END IF;

  --CREATE OUTPUT
  OPEN :ITEMS FOR
    SELECT 0            AS COUNTTASKS,    -- TEST Custom Counter Function for https://jira.appbase.com/browse/DCM-6185
           v_countTaskDocuments    AS COUNTTASKDOCUMENTS,
           v_countCaseDocuments    AS COUNTCASEDOCUMENTS,
           v_countEPDocuments      AS COUNTEPDOCUMENTS,
           v_countThreads          AS COUNTTHREADS,
           v_countNotes            AS COUNTNOTES,
           v_countCaseParties      AS COUNTPARTIES,
           v_countActivities       AS COUNTACTIVITIES,
           v_countCaseLinks        AS COUNTCASELINKS,
           v_countEPCases          AS COUNTCASES,
           v_countRelatedEPParties AS COUNTRELATEDPARTIES
      FROM DUAL;
END;