DECLARE
  v_acl_ids NVARCHAR2(32767);

  v_result       NUMBER;
  v_errorcode    NUMBER;
  v_errormessage NCLOB;
BEGIN
  v_errorcode    := 0;
  v_errorMessage := '';

  --Check if every CASEWORKER is assigned to an AppBase user 
  FOR rec IN (SELECT col_id,
                     col_name
                FROM tbl_ppl_caseworker
               WHERE NVL(col_isdeleted, 0) = 0
                 AND col_userid IS NULL) LOOP
    v_errorcode    := 124;
    v_errormessage := v_errormessage || '<li>Case Worker ' || rec.col_name || ' with Id# ' || rec.col_id || ' is not assigned to any of AppBase users' || '</li>';
  END LOOP;

  --Check if there are CASEWORKERs assigned to non-existent AppBase users 
  FOR rec IN (SELECT col_userid UserID FROM tbl_ppl_caseworker WHERE NVL(col_isdeleted, 0) = 0 MINUS SELECT userid UserID FROM vw_users) LOOP
    IF rec.userid IS NOT NULL THEN
      v_errorcode    := 125;
      v_errormessage := v_errormessage || '<li>Case Worker with User Id# ' || rec.userid || ' is not assigned to any AppBase users' || '</li>';
    END IF;
  END LOOP;

  -- Check if every CASEWORKER has at least one personal WORKBASKET attached that is their default
  FOR rec IN (SELECT cw.col_id CASEWORKER_ID,
                     NVL(cw.col_name, 'Deleted') CASEWORKER_NAME,
                     Wb.CASEWORKER_id WBCASEWORKER_ID
                FROM tbl_ppl_caseworker cw
                LEFT JOIN vw_ppl_simpleworkbasket wb
                  ON Wb.CASEWORKER_id = cw.col_id
                 AND lower(Wb.WORKBASKETtype_code) = 'personal'
                 AND wb.IsDefault = 1
               WHERE NVL(cw.col_isdeleted, 0) = 0
                 AND Wb.CASEWORKER_id IS NULL) LOOP
    v_errorcode    := 126;
    v_errormessage := v_errormessage || '<li>Case Worker ' || rec.CASEWORKER_NAME || ' with id# ' || rec.CASEWORKER_ID || ' does not have WORKBASKET attached' || '</li>';
  END LOOP;

  --Check if every CASEWORKER has Access Subject record 
  FOR rec IN (SELECT cw.col_id CASEWORKER_ID,
                     NVL(cw.col_name, 'DELETED') CASEWORKER_NAME,
                     acs.col_id ACCESSSUBJECT_ID
                FROM tbl_ppl_caseworker cw
                LEFT JOIN tbl_ac_accesssubject acs
                  ON cw.col_CASEWORKERaccesssubject = acs.col_id
                 AND Lower(acs.col_type) = 'caseworker'
               WHERE NVL(cw.col_isdeleted, 0) = 0
               ORDER BY cw.col_id) LOOP
    IF rec.ACCESSSUBJECT_ID IS NULL THEN
      v_errormessage := v_errormessage || '<li>Case Worker ' || rec.CASEWORKER_NAME || ' with id# ' || rec.CASEWORKER_ID || ' does not have Access Subject Id' || '</li>';
    END IF;
  END LOOP;

  -- Check if every CASEWORKER has one and only one corresponding Access Subject records 
  FOR rec IN (SELECT cw.col_id CASEWORKER_ID,
                     cw.col_name CASEWORKER_NAME,
                     COUNT(cw.col_id) amount
                FROM tbl_ppl_caseworker cw
               INNER JOIN tbl_ac_accesssubject acs
                  ON cw.col_CASEWORKERaccesssubject = acs.col_id
               WHERE NVL(cw.col_isdeleted, 0) = 0
               GROUP BY cw.col_id,
                        cw.col_name
              HAVING COUNT(cw.col_id) > 1
               ORDER BY cw.col_id) LOOP
    v_errorcode    := 127;
    v_errormessage := v_errormessage || '<li>Case Worker ' || rec.CASEWORKER_NAME || ' with id# ' || rec.CASEWORKER_ID || ' has more than one Access Subject' || '</li>';
  END LOOP;

  --every CASEWORKER is linked to one and only one User. Check that that there aren't 2 Case Workers linked to the same AppBase User
  FOR rec IN (SELECT COUNT(1) amount,
                     ep.col_userid
                FROM tbl_ppl_caseworker ep
               WHERE NVL(ep.col_isdeleted, 0) = 0
                 AND ep.col_userid IS NOT NULL
               GROUP BY Ep.col_userid
              HAVING(COUNT(1) > 1)) LOOP
    v_errorcode    := 142;
    v_errormessage := v_errormessage || '<li>' || rec.amount || ' Case Worker associated with AppBase UserId # ' || rec.col_userid || '</li>';
  END LOOP;
  --every AppBase User has to be linked either to a CASEWORKER or a External Party but not at both
  FOR rec IN (SELECT usr.userid USERID,
                     usr.name   USERNAME
                FROM vw_users usr
               INNER JOIN tbl_ppl_caseworker cw
                  ON usr.userid = cw.col_userid
               WHERE NVL(Cw.Col_Isdeleted, 0) = 0
              INTERSECT
              SELECT usr.userid userid,
                     usr.name   username
                FROM vw_users usr
               INNER JOIN tbl_externalparty ep
                  ON usr.userid = ep.col_userid
               WHERE NVL(ep.Col_Isdeleted, 0) = 0) LOOP
    v_errorcode    := 143;
    v_errormessage := v_errormessage || '<li>User ' || rec.username || ' is both linked to CaseWorker and External Party</li>';
  END LOOP;
  -- Check if every CaseWorker has unused ACL and AccessSubject
  FOR rec IN (SELECT acs.col_id   AS accessSubject_Id,
                     acs.col_name AS NAME
                FROM tbl_ac_accesssubject acs
                LEFT JOIN tbl_ppl_caseworker cw
                  ON cw.col_caseworkeraccesssubject = acs.col_id
               WHERE cw.col_id IS NULL
                 AND acs.col_type = 'CASEWORKER') LOOP
    v_errorCode    := 122;
    v_errorMessage := v_errorMessage || '<li>Case Worker ' || rec.name || ' was lost and there are unused AccessSubject_Id# ' || to_char(rec.accessSubject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccesssubject = rec.accessSubject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
  END LOOP;
  --  Check if every CaseWorker has unused Workbasket
  FOR rec IN (SELECT wb.col_id   AS wb_id,
                     wb.col_name AS NAME
                FROM tbl_ppl_workbasket wb
                LEFT JOIN tbl_ppl_caseworker cw
                  ON cw.col_id = wb.col_caseworkerworkbasket
               WHERE cw.col_id IS NULL
                 AND wb.col_caseworkerworkbasket IS NOT NULL) LOOP
    v_errorCode    := 123;
    v_errorMessage := v_errorMessage || '<li>Case Worker ' || rec.name || ' was lost and there is unused Workbasket_Id# ' || to_char(rec.wb_id) || '</li>';
  END LOOP;

  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
END;
