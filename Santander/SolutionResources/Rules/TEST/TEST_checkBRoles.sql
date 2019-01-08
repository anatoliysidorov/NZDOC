DECLARE
  v_acl_ids NVARCHAR2(32767);

  v_errorCode    NUMBER;
  v_errorMessage NCLOB;
BEGIN
  v_errorCode    := 0;
  v_errorMessage := '';

  FOR rec IN (SELECT br.col_name BR_Name,
                     br.col_id   BR_ID
                FROM tbl_ppl_businessrole br
                LEFT JOIN tbl_ac_accesssubject acs
                  ON acs.col_id = br.Col_Businessroleaccesssubject
               WHERE Br.Col_Businessroleaccesssubject IS NULL
                  OR acs.col_id IS NULL) LOOP
    v_errorCode    := 121;
    v_errorMessage := v_errorMessage || '<li>Business Role ' || rec.BR_Name || ' # ' || rec.BR_Id || ' does not have no Access Subject record</li>';
  END LOOP;
  --Check that linked AppBase Roles exist
  FOR rec IN (SELECT col_id   br_id,
                     col_name br_name
                FROM tbl_ppl_businessrole
               WHERE col_roleid IN (SELECT col_roleid FROM tbl_ppl_businessrole WHERE col_roleid IS NOT NULL MINUS SELECT roleid FROM Vw_Role)) LOOP
    v_errorCode    := 122;
    v_errorMessage := v_errorMessage || '<li>Business Role ' || rec.BR_Name || ' # ' || rec.BR_Id || ' is linked to non-existent AppBase Role</li>';
  END LOOP;
  -- Check if every BR has at least one personal WORKBASKET attached that is their default
  FOR rec IN (SELECT col_id   BRId,
                     col_name BrName
                FROM tbl_ppl_businessrole
               WHERE f_ppl_getprimarywb(UnitId => col_id, UnitType => 'BUSINESSROLE') = -1) LOOP
    v_errorcode    := 126;
    v_errormessage := v_errormessage || '<li>Business Role ' || rec.BrName || ' with id# ' || rec.BrId || ' does not have no WORKBASKET attached' || '</li>';
  END LOOP;
  -- Check if every Business Role has unused ACL and AccessSubject
  FOR rec IN (SELECT acs.col_id   AS accessSubject_Id,
                     acs.col_name AS NAME
                FROM tbl_ac_accesssubject acs
                LEFT JOIN tbl_ppl_businessrole br
                  ON br.col_businessroleaccesssubject = acs.col_id
               WHERE br.col_id IS NULL
                 AND acs.col_type = 'BUSINESSROLE') LOOP
    v_errorCode    := 123;
    v_errorMessage := v_errorMessage || '<li>Business Role ' || rec.name || ' was lost and there are unused AccessSubject_Id# ' || to_char(rec.accessSubject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccesssubject = rec.accessSubject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
  END LOOP;
  --  Check if every Business Role has unused Workbasket
  FOR rec IN (SELECT wb.col_id   AS wb_id,
                     wb.col_name AS NAME
                FROM tbl_ppl_workbasket wb
                LEFT JOIN tbl_ppl_businessrole br
                  ON br.col_id = wb.col_workbasketbusinessrole
               WHERE br.col_id IS NULL
                 AND wb.col_workbasketbusinessrole IS NOT NULL) LOOP
    v_errorCode    := 124;
    v_errorMessage := v_errorMessage || '<li>Business Role ' || rec.name || ' was lost and there is unused Workbasket_Id# ' || to_char(rec.wb_id) || '</li>';
  END LOOP;

  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
  --  dbms_output.put_line(v_errorMessage);
END;
