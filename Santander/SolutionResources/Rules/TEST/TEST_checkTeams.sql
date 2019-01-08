DECLARE
  v_acl_ids NVARCHAR2(32767);

  v_errorCode    NUMBER;
  v_errorMessage NCLOB;
BEGIN
  v_errorCode    := 0;
  v_errorMessage := '';

  FOR rec IN (SELECT tm.col_name AS TM_Name,
                     tm.col_id   AS TM_ID
                FROM tbl_ppl_team TM
                LEFT JOIN tbl_ac_accesssubject acs
                  ON acs.col_id = tm.Col_teamaccesssubject
               WHERE tm.Col_teamaccesssubject IS NULL
                  OR acs.col_id IS NULL) LOOP
    v_errorCode    := 121;
    v_errorMessage := v_errorMessage || '<li>Team ' || rec.TM_Name || ' # ' || rec.TM_Id || ' does not have no Access Subject record</li>';
  END LOOP;
  --Check that linked AppBase Roles exist
  FOR rec IN (SELECT col_id   AS tm_id,
                     col_name AS tm_name
                FROM tbl_ppl_team
               WHERE col_groupid IN (SELECT col_groupid FROM tbl_ppl_team WHERE col_groupid IS NOT NULL MINUS SELECT id FROM Vw_Ppl_Appbasegroup)) LOOP
    v_errorCode    := 122;
    v_errorMessage := v_errorMessage || '<li>Team ' || rec.TM_Name || ' # ' || rec.TM_Id || ' is linked to non-existent AppBase Group</li>';
  END LOOP;
  -- Check if every Team has at least one personal WORKBASKET attached that is their default
  FOR rec IN (SELECT col_id   AS TeamId,
                     col_name AS TeamName
                FROM tbl_ppl_team
               WHERE f_ppl_getprimarywb(UnitId => col_id, UnitType => 'TEAM') = -1) LOOP
    v_errorcode    := 126;
    v_errormessage := v_errormessage || '<li>Team ' || rec.TeamName || ' # ' || rec.TeamId || ' doesn not have WORKBASKET attached' || '</li>';
  END LOOP;
  -- Check if every Team has unused ACL and AccessSubject
  FOR rec IN (SELECT acs.col_id   AS accessSubject_Id,
                     acs.col_name AS NAME
                FROM tbl_ac_accesssubject acs
                LEFT JOIN tbl_ppl_team t
                  ON t.col_teamaccesssubject = acs.col_id
               WHERE t.col_id IS NULL
                 AND acs.col_type = 'TEAM') LOOP
  
    v_errorCode    := 123;
    v_errorMessage := v_errorMessage || '<li>Team ' || rec.name || ' was lost and there are unused AccessSubject_Id# ' || to_char(rec.accessSubject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccesssubject = rec.accessSubject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
  END LOOP;
  --  Check if every Team has unused Workbasket
  FOR rec IN (SELECT wb.col_id   AS wb_id,
                     wb.col_name AS NAME
                FROM tbl_ppl_workbasket wb
                LEFT JOIN tbl_ppl_team t
                  ON t.col_id = wb.col_workbasketteam
               WHERE t.col_id IS NULL
                 AND wb.col_workbasketteam IS NOT NULL) LOOP
    v_errorCode    := 124;
    v_errorMessage := v_errorMessage || '<li>Team ' || rec.name || ' was lost and there is unused Workbasket_Id# ' || to_char(rec.wb_id) || '</li>';
  END LOOP;

  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
  --dbms_output.put_line(v_errorMessage);
END;
