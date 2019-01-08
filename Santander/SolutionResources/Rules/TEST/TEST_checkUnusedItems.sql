DECLARE
  v_errorCode    NUMBER;
  v_errorMessage NCLOB;
  v_acl_ids      NVARCHAR2(32767);
BEGIN

  v_errorCode    := 0;
  v_errorMessage := '';

  --Check unused ACLs by AccessObject
  FOR rec IN (SELECT ao.col_id   AS acessObject_Id,
                     ao.col_name AS NAME
                FROM tbl_ac_accessobject ao
                LEFT JOIN tbl_ac_accessobjecttype aot
                  ON ao.col_accessobjaccessobjtype = aot.col_id
                LEFT JOIN tbl_fom_uielement ui
                  ON ui.col_id = ao.col_accessobjectuielement
               WHERE ui.col_id IS NULL
                 AND (aot.col_code = 'PAGE_ELEMENT' OR aot.col_code = 'DASHBOARD_ELEMENT')) LOOP
    v_errorCode    := 135;
    v_errorMessage := v_errorMessage || '<li>' || rec.name || ' was lost and there are unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
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
    v_errorCode    := 136;
    v_errorMessage := v_errorMessage || '<li>Task Type ' || rec.name || ' was lost and there are unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
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
    v_errorCode    := 137;
    v_errorMessage := v_errorMessage || '<li>' || rec.name || ' was lost and there are unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
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
    v_errorCode    := 138;
    v_errorMessage := v_errorMessage || '<li>' || rec.name || ' was lost and there are unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
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
    v_errorCode    := 139;
    v_errorMessage := v_errorMessage || '<li>' || rec.name || ' was lost and there are unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
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
    v_errorCode    := 140;
    v_errorMessage := v_errorMessage || '<li>' || rec.name || ' was lost and there are unused AccessObject_Id# ' || to_char(rec.acessObject_Id);
    v_acl_ids      := NULL;
    SELECT LISTAGG(TO_CHAR(acl.col_id), ',') WITHIN GROUP(ORDER BY acl.col_id) INTO v_acl_ids FROM tbl_ac_acl acl WHERE acl.col_aclaccessobject = rec.acessObject_Id;
    IF v_acl_ids IS NOT NULL THEN
      v_errorMessage := v_errorMessage || ', ACL_Id# ' || v_acl_ids;
    END IF;
    v_errorMessage := to_char(v_errorMessage) || '</li>';
  END LOOP;
  --Check unused case types
  FOR rec IN (SELECT col_name NAME,
                     col_id   CaseTypeId
                FROM Tbl_Dict_Casesystype
               WHERE col_id IN (SELECT col_id
                                  FROM Tbl_Dict_Casesystype
                                 WHERE col_isdeleted = 0
                                    OR col_isdeleted IS NULL
                                MINUS
                                SELECT DISTINCT (Col_Casedict_Casesystype)
                                  FROM tbl_case)) LOOP
    v_errorCode    := 131;
    v_errorMessage := v_errorMessage || '<li>Case Type <b>' || rec.Name || '</b> with Id# ' || rec.CaseTypeId || ' is unused</li>';
  END LOOP;
  --Check unused TaskTypes
  FOR rec IN (SELECT col_id   TaskTypeId,
                     col_name NAME
                FROM tbl_dict_tasksystype
               WHERE col_id IN (SELECT col_id
                                  FROM tbl_dict_tasksystype
                                 WHERE col_isdeleted = 0
                                    OR col_isdeleted IS NULL
                                MINUS (SELECT DISTINCT (col_taskdict_tasksystype) FROM tbl_task UNION SELECT DISTINCT (col_tasktmpldict_tasksystype) FROM tbl_tasktemplate))) LOOP
    v_errorCode    := 132;
    v_errorMessage := v_errorMessage || '<li>Task Type ' || '<b>' || rec.Name || '</b> with Id# ' || rec.TaskTypeId || ' is unused</li>';
  END LOOP;
  --Check unused Resolution Codes
  FOR rec IN (SELECT col_name NAME,
                     col_id   ResolutionId
                FROM tbl_stp_resolutioncode
               WHERE col_id IN (SELECT col_id Res_ID
                                  FROM tbl_stp_resolutioncode
                                 WHERE lower(col_type) IN ('case', 'task')
                                   AND Col_Isdeleted = 0
                                    OR Col_Isdeleted IS NULL
                                MINUS (SELECT DISTINCT (col_casetyperesolutioncode) Res_Id
                                        FROM Tbl_Casesystyperesolutioncode
                                      UNION
                                      SELECT DISTINCT (col_stp_resolutioncodecase) Res_Id
                                        FROM tbl_case
                                       WHERE col_stp_resolutioncodecase IS NOT NULL
                                      UNION
                                      SELECT DISTINCT (Col_Tbl_Stp_Resolutioncode) Res_Id
                                        FROM Tbl_Tasksystyperesolutioncode
                                      UNION
                                      SELECT DISTINCT (col_taskstp_resolutioncode) Res_Id
                                        FROM tbl_task
                                       WHERE col_taskstp_resolutioncode IS NOT NULL))) LOOP
    v_errorCode    := 133;
    v_errorMessage := v_errorMessage || '<li>Resolution Code ' || '<b>' || rec.Name || '</b> with Id# ' || rec.ResolutionId || ' is unused</li>';
  END LOOP;
  --Check unused Priorities
  FOR rec IN (SELECT col_id   PriorityId,
                     col_name NAME
                FROM tbl_stp_priority
               WHERE col_id IN (SELECT col_id
                                  FROM tbl_stp_priority
                                 WHERE col_isdeleted = 0
                                    OR col_isdeleted IS NULL
                                MINUS (SELECT DISTINCT (col_stp_prioritycase) FROM tbl_case UNION SELECT DISTINCT (col_casetypepriority) FROM tbl_dict_casesystype))) LOOP
    v_errorCode    := 134;
    v_errorMessage := v_errorMessage || '<li>Priority ' || '<b>' || rec.Name || '</b> with Id# ' || rec.PriorityId || ' is unused</li>';
  END LOOP;

  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
  --  Dbms_output.put_line(v_errorMessage);
END;
