DECLARE
  --INPUT
  v_id             INT;
  v_ids            NVARCHAR2(32767);
  v_parentThreadId INT;
  v_mode           NVARCHAR2(30);

  --INTERNAL
  allowJoINDiscussion    NVARCHAR2(30);
  allowAddPeople         NVARCHAR2(30);
  allowCommentDiscussion NVARCHAR2(30);
  v_currentUserCWID      INT;
  v_validationresult     INT;
  v_Attributes           NVARCHAR2(4000);
  v_IndivAttributes      NVARCHAR2(4000);
  v_caseId               INT;
  v_currentCaseOwner     INT;
  v_ignore               INT;
  v_historymsg           NVARCHAR2(4000);

  --OUTPUT
  v_errorcode    INT;
  v_errormessage NCLOB;
  v_outData CLOB;
  
BEGIN
  --INPUT
  v_id             := :Id;
  v_ids            := :Ids;
  v_parentThreadId := :ParentThreadId;
  v_mode           := :CurrentMode;
  v_outData      := NULL;

  --INTERNAL
  v_caseId               := NULL;
  allowJoINDiscussion    := '';
  allowCommentDiscussion := '';
  allowAddPeople         := '';
  v_currentUserCWID      := 0;
  v_Attributes           := '';
  v_IndivAttributes      := '';

  --OUTPUT
  v_errorcode    := NULL;
  v_errormessage := '';

  --BASIC ERROR HANDLING
  IF (NVL(v_id, 0) = 0 AND v_ids IS NULL AND v_mode != 'JOIN') THEN
    v_errormessage := 'Either ID or IDs is required for this rule';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  --GET CASE INFO
  BEGIN
    SELECT c.COL_ID,
           c.COL_CASEPPL_WORKBASKET
      INTO v_caseId,
           v_currentCaseOwner
      FROM TBL_THREAD t
     INNER JOIN TBL_CASE c
        ON c.col_id = t.COL_THREADCASE
     WHERE t.COL_ID = v_parentThreadId;

    IF v_caseId IS NULL THEN
      v_errormessage := 'Thread is missing Thread or parent Case';
      v_errorcode    := 102;
      GOTO cleanup;
    END IF;
  EXCEPTION
    WHEN no_data_found THEN
      v_errormessage := 'Thread is missing Thread or parent Case';
      v_errorcode    := 103;
      GOTO cleanup;
  END;

  --GET DISCUSSION SETTINGS
  BEGIN
    SELECT col_allowjoINdiscussion,
           col_allowaddpeople,
           col_allowcommentdiscussion
      INTO allowJoINDiscussion,
           allowAddPeople,
           allowCommentDiscussion
      FROM tbl_threadsettINg
     WHERE ROWNUM = 1;
  EXCEPTION
    WHEN no_data_found THEN
      allowJoINDiscussion := 'YES';
      allowAddPeople      := 'ANYONE';
  END;

  IF (allowCommentDiscussion = 'ANYONE') THEN
    v_errormessage := 'Anyone can comment on this Thread, you don''t need to add anyone';
    v_errorcode    := 104;
    GOTO cleanup;
  END IF;

  BEGIN
    --CREATE XML FOR INPUT INTO DISCUSSION THREADS
    v_Attributes := v_Attributes || f_UTIL_wrapTextInNode(NodeTag => 'AllowCommentDiscussion', msg => TO_CHAR(allowCommentDiscussion));
    v_Attributes := v_Attributes || f_UTIL_wrapTextInNode(NodeTag => 'AllowAddPeople', msg => TO_CHAR(allowAddPeople));
    v_Attributes := v_Attributes || f_UTIL_wrapTextInNode(NodeTag => 'AllowJoINDiscussion', msg => TO_CHAR(allowJoINDiscussion));
    v_Attributes := v_Attributes || f_UTIL_wrapTextInNode(NodeTag => 'MemberId', msg => TO_CHAR(v_id));
    v_Attributes := v_Attributes || f_UTIL_wrapTextInNode(NodeTag => 'MemberIds', msg => v_ids);
    v_Attributes := v_Attributes || f_UTIL_wrapTextInNode(NodeTag => 'Mode', msg => v_mode);
    v_Attributes := v_Attributes || f_UTIL_wrapTextInNode(NodeTag => 'CurrentUserCWID', msg => TO_CHAR(v_currentUserCWID));
    v_Attributes := v_Attributes || f_UTIL_wrapTextInNode(NodeTag => 'ParentThreadId', msg => TO_CHAR(v_parentThreadId));

    --DO SECURITY CHECK
    IF (v_mode = 'JOIN') THEN
      --Allow JoIN to Discussion
      IF (allowJoINDiscussion = 'NO') THEN
        v_errormessage := 'You don''t have permissions to JOIN this thread';
        v_errorcode    := 106;
        GOTO cleanup;
      END IF;
      v_id := f_DCM_getCaseWorkerId();
      IF NVL(v_id, 0) = 0 THEN
        v_errormessage := 'Case Worker or their work basket is not found';
        v_errorcode    := 105;
        GOTO cleanup;
      END IF;
    ELSE
      IF (allowAddPeople = 'NOBODY') THEN
        v_errormessage := 'Nobody is allowed to JOIN this thread';
        v_errorcode    := 107;
        GOTO cleanup;
      ELSIF (allowAddPeople = 'ONLY_CASE_OWNER') THEN
        IF f_DCM_getMyPersonalWorkbasket() != v_currentCaseOwner THEN
          v_errormessage := 'Only the Case Owner can add people to this thread';
          v_errorcode    := 108;
          GOTO cleanup;
        END IF;
      END IF;
    END IF;

    --LOOP THROUGH EACH PERSON TO ADD
    IF (v_id > 0) THEN
      v_ids := TO_CHAR(v_id);
    END IF;

    FOR rec IN (SELECT TO_NUMBER(column_value) AS CWid
                  FROM TABLE(asf_split(v_ids))
                MINUS
                SELECT col_caseworkerid AS CWid
                  FROM tbl_threadcaseworker
                 WHERE col_threadid = v_parentThreadId)

     LOOP
      v_IndivAttributes := v_Attributes || f_UTIL_wrapTextInNode(NodeTag => 'CaseWorkerId', msg => TO_CHAR(rec.CWid));

      --COMMON EVENT - THREAD_PEOPLE_JOINED - VALIDATION - BEFORE
      v_validationresult := 1;
      v_ignore           := f_dcm_processcommonevent(InData           => NULL,
                                                     OutData          => v_outData,
                                                     Attributes       => v_IndivAttributes,
                                                     code             => NULL,
                                                     caseid           => v_caseid,
                                                     casetypeid       => NULL,
                                                     commoneventtype  => 'THREAD_PEOPLE_JOINED',
                                                     errorcode        => v_errorcode,
                                                     errormessage     => v_errormessage,
                                                     eventmoment      => 'BEFORE',
                                                     eventtype        => 'VALIDATION',
                                                     historymessage   => v_historymsg,
                                                     procedureid      => NULL,
                                                     taskid           => NULL,
                                                     tasktypeid       => NULL,
                                                     validationresult => v_validationresult);
      IF NVL(v_validationresult, 0) = 0 THEN
        v_errormessage := 'Error adding Case Worker to Thread';
        v_errorcode    := 198;
        GOTO cleanup;
      END IF;

      --COMMON EVENT - THREAD_PEOPLE_JOINED - ACTION - BEFORE
      v_validationresult := 1;
      v_ignore           := f_dcm_processcommonevent(InData           => NULL,
                                                     OutData          => v_outData,
                                                     Attributes       => v_IndivAttributes,
                                                     code             => NULL,
                                                     caseid           => v_caseid,
                                                     casetypeid       => NULL,
                                                     commoneventtype  => 'THREAD_PEOPLE_JOINED',
                                                     errorcode        => v_errorcode,
                                                     errormessage     => v_errormessage,
                                                     eventmoment      => 'BEFORE',
                                                     eventtype        => 'ACTION',
                                                     historymessage   => v_historymsg,
                                                     procedureid      => NULL,
                                                     taskid           => NULL,
                                                     tasktypeid       => NULL,
                                                     validationresult => v_validationresult);
      --MAIN ACTION
      INSERT INTO TBL_THREADCASEWORKER (COL_CASEWORKERID, COL_THREADID) VALUES (rec.CWid, v_parentThreadId);

      --COMMON EVENT - THREAD_PEOPLE_JOINED - ACTION - AFTER
      v_validationresult := 1;
      v_ignore           := f_dcm_processcommonevent(InData           => NULL,
                                                     OutData          => v_outData,
                                                     Attributes       => v_IndivAttributes,
                                                     code             => NULL,
                                                     caseid           => v_caseid,
                                                     casetypeid       => NULL,
                                                     commoneventtype  => 'THREAD_PEOPLE_JOINED',
                                                     errorcode        => v_errorcode,
                                                     errormessage     => v_errormessage,
                                                     eventmoment      => 'AFTER',
                                                     eventtype        => 'ACTION',
                                                     historymessage   => v_historymsg,
                                                     procedureid      => NULL,
                                                     taskid           => NULL,
                                                     tasktypeid       => NULL,
                                                     validationresult => v_validationresult);
    END LOOP;

    v_errorcode    := NULL;
    v_errormessage := '';

  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode    := 199;
      v_errormessage := DBMS_UTILITY.FORMAT_ERROR_STACK;
  END;

  <<cleanup>>
  IF NVL(v_errorcode, 0) <> 0 THEN
    ROLLBACK;
  END IF;
  :ErrorCode    := v_errorcode;
  :ErrorMessage := v_errormessage;

END;