DECLARE
  v_finalreport     NCLOB;
  v_res             NUMBER;
  v_uniquecode      NVARCHAR2(255);
  v_accesssubjectid NUMBER;
  v_objectprefix    NVARCHAR2(255);
  v_acl_ids         NVARCHAR2(32767);

  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);

BEGIN

  v_finalreport  := NULL;
  v_errorCode    := 0;
  v_errorMessage := '';
  v_objectprefix := 'TEAM';

  -- Add AccessSubjects and Workbaskets
  FOR rec IN (SELECT wb.col_id  AS workbasketid,
                     acs.col_id AS accesssubjectid,
                     t.col_id   AS id,
                     t.col_name AS NAME,
                     t.col_code AS code
                FROM tbl_ppl_team t
                LEFT JOIN tbl_ac_accesssubject acs
                  ON t.col_teamaccesssubject = acs.col_id
                LEFT JOIN tbl_ppl_workbasket wb
                  ON wb.col_workbasketteam = t.col_id
               WHERE wb.col_id IS NULL
                  OR acs.col_id IS NULL) LOOP
  
    --create Workbasket record 
    IF rec.workbasketid IS NULL THEN
      v_uniquecode := f_UTIL_calcUniqueCode(BaseCode => v_objectprefix || '_' || rec.code, TableName => 'tbl_ppl_team');
      v_res        := f_ppl_createmodifywbfn(caseworkerowner    => NULL,
                                             externalpartyowner => NULL,
                                             businessroleowner  => NULL,
                                             skillowner         => NULL,
                                             teamowner          => rec.id,
                                             NAME               => rec.name,
                                             code               => v_uniquecode,
                                             description        => 'Automatically created workbasket for the' || ' ''' || rec.name || ''' Team',
                                             isdefault          => 1,
                                             isprivate          => 1,
                                             workbaskettype     => 'PERSONAL',
                                             id                 => NULL,
                                             resultid           => v_res,
                                             errorcode          => v_errorCode,
                                             errormessage       => v_errorMessage);
    
      v_finalreport := v_finalreport || '<li>Created personal Workbasket for Team ' || rec.name || '(#' || rec.id || ')</li>';
    END IF;
  
    --create Access Subject record 
    IF rec.accesssubjectid IS NULL THEN
      v_uniquecode := f_UTIL_calcUniqueCode(BaseCode => v_objectprefix || '_' || rec.code, TableName => 'tbl_ac_accesssubject');
      INSERT INTO tbl_ac_accesssubject (col_type, col_code, col_name) VALUES (v_objectprefix, v_uniquecode, rec.name) RETURNING col_id INTO v_accesssubjectid;
    
      --update AccessObjectId
      UPDATE tbl_ppl_team SET col_teamaccesssubject = v_accesssubjectid WHERE col_id = rec.id;
    
      v_finalreport := v_finalreport || '<li>Created Access Subject record for Team ' || rec.name || '(#' || rec.id || ')</li>';
    END IF;
  END LOOP;

  --Fix broken AppBase Group links
  FOR rec IN (SELECT col_id   AS id,
                     col_name AS NAME
                FROM tbl_ppl_team
               WHERE col_groupid IN (SELECT col_groupid FROM tbl_ppl_team WHERE col_groupid IS NOT NULL GROUP BY col_groupid MINUS SELECT id FROM vw_ppl_appbasegroup)) LOOP
  
    UPDATE tbl_ppl_team SET col_groupid = NULL WHERE col_id = rec.id;
  
    v_finalreport := v_finalreport || '<li>Team broken AppBase Group link fixed: ' || rec.name || '(#' || rec.id || ')</li>';
  END LOOP;

  -- Fix unused AccessSubjects, Acls
  FOR rec IN (SELECT acs.col_id   AS accessSubject_Id,
                     acs.col_name AS NAME
                FROM tbl_ac_accesssubject acs
                LEFT JOIN tbl_ppl_team t
                  ON t.col_teamaccesssubject = acs.col_id
               WHERE t.col_id IS NULL
                 AND acs.col_type = v_objectprefix) LOOP
  
    v_acl_ids     := NULL;
    v_finalreport := v_finalreport || '<li>Unused AccessSubject_Id# ' || to_char(rec.accessSubject_Id);
  
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccesssubject = rec.accessSubject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_finalreport := v_finalreport || ', ACL_Ids# ' || v_acl_ids;
    END IF;
    v_finalreport := v_finalreport || ' were deleted for lost Team ' || rec.name || '</li>';
  
    DELETE FROM tbl_ac_acl WHERE col_aclaccesssubject = rec.accessSubject_Id;
    DELETE FROM tbl_ac_accesssubject WHERE col_id = rec.accessSubject_Id;
  END LOOP;

  -- Fix unused Workbaskets
  FOR rec IN (SELECT wb.col_id   AS wb_id,
                     wb.col_name AS NAME
                FROM tbl_ppl_workbasket wb
                LEFT JOIN tbl_ppl_team t
                  ON t.col_id = wb.col_workbasketteam
               WHERE t.col_id IS NULL
                 AND wb.col_workbasketteam IS NOT NULL) LOOP
    v_finalreport := v_finalreport || '<li>Unused Workbasket_Id# ' || to_char(rec.wb_id) || ' was deleted for lost Team ' || rec.name || '</li>';
    DELETE FROM tbl_ppl_workbasket WHERE col_id = rec.wb_id;
  END LOOP;

  :Report := Nvl(v_finalreport, 'No Fixes Needed');
END;
