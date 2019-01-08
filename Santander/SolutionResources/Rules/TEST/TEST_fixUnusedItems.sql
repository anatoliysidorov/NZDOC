DECLARE
  v_finalreport NCLOB;
  v_acl_ids     NVARCHAR2(32767);
BEGIN

  v_finalreport  := NULL;

  -- Fix unused AccessObjects, Acls
  FOR rec IN (SELECT ao.col_id   AS acessObject_Id,
                     ao.col_name AS NAME
                FROM tbl_ac_accessobject ao
                LEFT JOIN tbl_ac_accessobjecttype aot
                  ON ao.col_accessobjaccessobjtype = aot.col_id
                LEFT JOIN tbl_fom_uielement ui
                  ON ui.col_id = ao.col_accessobjectuielement
               WHERE ui.col_id IS NULL
                 AND (aot.col_code = 'PAGE_ELEMENT' OR aot.col_code = 'DASHBOARD_ELEMENT')) LOOP
  
    v_acl_ids     := NULL;
    v_finalreport := v_finalreport || '<li>Unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
  
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_finalreport := v_finalreport || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_finalreport := v_finalreport || ' were deleted for lost ' || rec.name || '</li>';
  
    DELETE FROM tbl_ac_acl WHERE col_aclaccessobject = rec.acessObject_Id;
    DELETE FROM tbl_ac_accessobject WHERE col_id = rec.acessObject_Id;
  END LOOP;
  FOR rec IN (SELECT ao.col_id   AS acessObject_Id,
                     ao.col_name AS NAME
                FROM tbl_ac_accessobject ao
                LEFT JOIN tbl_ac_accessobjecttype aot
                  ON ao.col_accessobjaccessobjtype = aot.col_id
                LEFT JOIN tbl_dict_tasksystype tt
                  ON ao.col_accessobjecttasksystype = tt.col_id
               WHERE tt.col_id IS NULL
                 AND aot.col_code = 'TASK_TYPE') LOOP
  
    v_acl_ids     := NULL;
    v_finalreport := v_finalreport || '<li>Unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
  
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_finalreport := v_finalreport || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_finalreport := v_finalreport || ' were deleted for lost Task Type ' || rec.name || '</li>';
  
    DELETE FROM tbl_ac_acl WHERE col_aclaccessobject = rec.acessObject_Id;
    DELETE FROM tbl_ac_accessobject WHERE col_id = rec.acessObject_Id;
  END LOOP;
  FOR rec IN (SELECT ao.col_id   AS acessObject_Id,
                     ao.col_name AS NAME
                FROM tbl_ac_accessobject ao
                LEFT JOIN tbl_ac_accessobjecttype aot
                  ON ao.col_accessobjaccessobjtype = aot.col_id
                LEFT JOIN tbl_dict_casesystype ct
                  ON ao.col_accessobjectcasesystype = ct.col_id
               WHERE ct.col_id IS NULL
                 AND aot.col_code = 'CASE_TYPE') LOOP
  
    v_acl_ids     := NULL;
    v_finalreport := v_finalreport || '<li>Unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
  
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_finalreport := v_finalreport || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_finalreport := v_finalreport || ' were deleted for lost ' || rec.name || '</li>';
  
    DELETE FROM tbl_ac_acl WHERE col_aclaccessobject = rec.acessObject_Id;
    DELETE FROM tbl_ac_accessobject WHERE col_id = rec.acessObject_Id;
  END LOOP;
  FOR rec IN (SELECT ao.col_id   AS acessObject_Id,
                     ao.col_name AS NAME
                FROM tbl_ac_accessobject ao
                LEFT JOIN tbl_ac_accessobjecttype aot
                  ON ao.col_accessobjaccessobjtype = aot.col_id
                LEFT JOIN tbl_dict_casestate cs
                  ON ao.col_accessobjectcasestate = cs.col_id
               WHERE cs.col_id IS NULL
                 AND aot.col_code = 'CASE_STATE') LOOP
  
    v_acl_ids     := NULL;
    v_finalreport := v_finalreport || '<li>Unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
  
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_finalreport := v_finalreport || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_finalreport := v_finalreport || ' were deleted for lost ' || rec.name || '</li>';
  
    DELETE FROM tbl_ac_acl WHERE col_aclaccessobject = rec.acessObject_Id;
    DELETE FROM tbl_ac_accessobject WHERE col_id = rec.acessObject_Id;
  END LOOP;
  FOR rec IN (SELECT ao.col_id   AS acessObject_Id,
                     ao.col_name AS NAME
                FROM tbl_ac_accessobject ao
                LEFT JOIN tbl_ac_accessobjecttype aot
                  ON ao.col_accessobjaccessobjtype = aot.col_id
                LEFT JOIN tbl_dict_accesstype act
                  ON ao.col_accessobjectaccesstype = act.col_id
               WHERE act.col_id IS NULL
                 AND aot.col_code = 'ACCESS_TYPE') LOOP
  
    v_acl_ids     := NULL;
    v_finalreport := v_finalreport || '<li>Unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
  
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_finalreport := v_finalreport || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_finalreport := v_finalreport || ' were deleted for lost ' || rec.name || '</li>';
  
    DELETE FROM tbl_ac_acl WHERE col_aclaccessobject = rec.acessObject_Id;
    DELETE FROM tbl_ac_accessobject WHERE col_id = rec.acessObject_Id;
  END LOOP;
  FOR rec IN (SELECT ao.col_id   AS acessObject_Id,
                     ao.col_name AS NAME
                FROM tbl_ac_accessobject ao
                LEFT JOIN tbl_ac_accessobjecttype aot
                  ON ao.col_accessobjaccessobjtype = aot.col_id
                LEFT JOIN tbl_dict_casetransition ct
                  ON ao.col_accessobjcasetransition = ct.col_id
               WHERE ct.col_id IS NULL
                 AND aot.col_code = 'CASE_TRANSITION') LOOP
  
    v_acl_ids     := NULL;
    v_finalreport := v_finalreport || '<li>Unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
  
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_finalreport := v_finalreport || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_finalreport := v_finalreport || ' were deleted for lost ' || rec.name || '</li>';
  
    DELETE FROM tbl_ac_acl WHERE col_aclaccessobject = rec.acessObject_Id;
    DELETE FROM tbl_ac_accessobject WHERE col_id = rec.acessObject_Id;
  END LOOP;

  :Report := Nvl(v_finalreport, 'No Fixes Needed');
END;