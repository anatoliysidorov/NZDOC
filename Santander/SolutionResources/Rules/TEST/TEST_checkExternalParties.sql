DECLARE
  v_acl_ids NVARCHAR2(32767);

  v_result       NUMBER;
  v_errorCode    NUMBER;
  v_errorMessage NCLOB;
BEGIN

  v_errorCode    := 0;
  v_errorMessage := '';

  --Check if an external party is assigned to existent AppBase user
  FOR rec IN (SELECT col_id,
                     col_name,
                     col_userid
                FROM Tbl_Externalparty
               WHERE col_userid IN (SELECT ep.col_userid
                                      FROM tbl_externalparty ep
                                     WHERE ep.col_userid IS NOT NULL
                                       AND NVL(ep.col_isdeleted, 0) = 0
                                    MINUS
                                    SELECT userid
                                      FROM vw_users)) LOOP
    v_errorCode    := 128;
    v_errorMessage := v_errorMessage || '<li>External Party ' || rec.col_name || ' with Id# ' || rec.col_id || ' is assigned to non-existant AppBase user' || '</li>';
  END LOOP;
  --Check if every external party has a workbasket
  FOR rec IN (SELECT ex.col_id   ExtParyId,
                     ex.col_name ExtPartyName,
                     wb.col_id
                FROM Tbl_Externalparty ex
                LEFT JOIN (SELECT col_id,
                                 Col_Workbasketexternalparty
                            FROM tbl_ppl_workbasket
                           WHERE Col_Workbasketexternalparty IS NOT NULL) wb
                  ON ex.col_id = wb.Col_Workbasketexternalparty
               WHERE wb.col_id IS NULL
                 AND NVL(ex.col_isdeleted, 0) = 0) LOOP
    v_errorCode    := 128;
    v_errorMessage := v_errorMessage || '<li>External Party ' || rec.ExtPartyName || ' with Id# ' || rec.ExtParyId || ' does not have workbasket' || '</li>';
  END LOOP;
  -- Check if every External Party has Access Subject record
  FOR rec IN (SELECT ex.col_id                    ExId,
                     ex.col_name                  ExName,
                     Ex.Col_Extpartyaccesssubject ExAccessSubjectId
                FROM Tbl_Externalparty ex
                LEFT JOIN Tbl_Ac_Accesssubject acs
                  ON Ex.Col_Extpartyaccesssubject = acs.col_id
               WHERE Ex.Col_Extpartyaccesssubject IS NULL
                 AND NVL(ex.col_isdeleted, 0) = 0
               ORDER BY ex.col_id) LOOP
    v_errorCode    := 129;
    v_errorMessage := v_errorMessage || '<li>External Party ' || rec.ExName || ' with id# ' || rec.ExId || ' does not have Access Subject record' || '</li>';
  END LOOP;
  -- Check if evry external party has one and only one corresponding Access Subject records
  FOR REC IN (SELECT Col_Extpartyaccesssubject AccessSubjectId,
                     COUNT(col_id)
                FROM Tbl_Externalparty
               WHERE Col_Extpartyaccesssubject IS NOT NULL
                 AND NVL(col_isdeleted, 0) = 0
               GROUP BY Col_Extpartyaccesssubject
              HAVING(COUNT(col_id)) > 1) LOOP
    v_errorCode    := 130;
    v_errorMessage := v_errorMessage || '<li>External Party  with Access Subject Id# ' || rec.AccessSubjectId || ' has more than one Access Subject' || '</li>';
  END LOOP;
  --Check that that there aren't 2 ExternalParties linked to the same AppBase User
  FOR rec IN (SELECT COUNT(1) amount,
                     ep.col_userid,
                     Usr.Name AppBaseName
                FROM Tbl_Externalparty ep
                LEFT JOIN vw_users usr
                  ON usr.userid = Ep.Col_Userid
               WHERE ep.col_userid IS NOT NULL
                 AND NVL(ep.col_isdeleted, 0) = 0
               GROUP BY Ep.Col_Userid,
                        Usr.Name
              HAVING(COUNT(1) > 1)) LOOP
    v_errorCode    := 141;
    v_errorMessage := V_Errormessage || '<li>' || rec.amount || ' external parties associated with AppBase User: ' || rec.AppBaseName || ' with Id # ' || rec.col_userid || '</li>';
  END LOOP;
  --every AppBase User has to be linked either to a CASEWORKER or a External Party but not at both
  FOR rec IN (SELECT usr.userid USERID,
                     usr.name   USERNAME
                FROM vw_users usr
               INNER JOIN tbl_ppl_caseworker cw
                  ON usr.userid = cw.col_userid
               WHERE NVL(cw.col_isdeleted, 0) = 0
              INTERSECT
              SELECT usr.userid userid,
                     usr.name   username
                FROM vw_users usr
               INNER JOIN tbl_externalparty ep
                  ON usr.userid = ep.col_userid
               WHERE NVL(ep.col_isdeleted, 0) = 0) LOOP
    v_errorcode    := 143;
    v_errormessage := v_errormessage || '<li>User ' || rec.username || ' is both linked to CaseWorker and External Party</li>';
  END LOOP;
  -- Check if every External Party has unused ACL and AccessSubject
  FOR rec IN (SELECT acs.col_id   AS accessSubject_Id,
                     acs.col_name AS NAME
                FROM tbl_ac_accesssubject acs
                LEFT JOIN tbl_externalparty ep
                  ON ep.col_extpartyaccesssubject = acs.col_id
               WHERE ep.col_id IS NULL
                 AND acs.col_type = 'EXTERNALPARTY') LOOP
    v_errorCode    := 122;
    v_errorMessage := v_errorMessage || '<li>External Party ' || rec.name || ' was lost and there are unused AccessSubject_Id# ' || to_char(rec.accessSubject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccesssubject = rec.accessSubject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
  END LOOP;
  --  Check if every External Party has unused Workbasket
  FOR rec IN (SELECT wb.col_id   AS wb_id,
                     wb.col_name AS NAME
                FROM tbl_ppl_workbasket wb
                LEFT JOIN tbl_externalparty ep
                  ON ep.col_id = wb.col_workbasketexternalparty
               WHERE ep.col_id IS NULL
                 AND wb.col_workbasketexternalparty IS NOT NULL) LOOP
    v_errorCode    := 123;
    v_errorMessage := v_errorMessage || '<li>External Party ' || rec.name || ' was lost and there is unused Workbasket_Id# ' || to_char(rec.wb_id) || '</li>';
  END LOOP;

  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
END;
