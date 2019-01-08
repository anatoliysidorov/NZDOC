DECLARE
  --input
  v_entity_id   INTEGER;
  v_entity_type NVARCHAR2(255);

  --calculated
  v_target_elementid NVARCHAR2(255);

BEGIN
  --input
  v_entity_id   := :Entity_Id;
  v_entity_type := lower(:Entity_Type);

  --calculated
  v_target_elementid := NULL;

  -- Case
  --get FULL_PAGE_CASE_DETAIL config if it exists
  IF (v_entity_type = 'case') THEN
    BEGIN
      SELECT p.TARGET_ELEMENTID
        INTO v_target_elementid
        FROM (SELECT ap.TARGET_ELEMENTID
                FROM vw_dcm_assocpage ap
               INNER JOIN tbl_dict_casesystype cst
                  ON ap.casesystype = cst.col_id
               INNER JOIN tbl_case cs
                  ON cst.col_id = cs.col_casedict_casesystype
               WHERE cs.col_id = v_entity_id
                 AND lower(ap.PAGETYPE_CODE) = 'full_page_case_detail'
                 AND lower(ap.TARGET_RAWTYPE) = 'page'
               ORDER BY ap.SHOWORDER) p
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;

  -- Task
  --get FULL_PAGE_TASK_DETAIL config if it exists
  IF (v_entity_type = 'task') THEN
    BEGIN
      SELECT p.TARGET_ELEMENTID
        INTO v_target_elementid
        FROM (SELECT ap.TARGET_ELEMENTID
                FROM vw_dcm_assocpage ap
               INNER JOIN tbl_dict_tasksystype cst
                  ON ap.tasksystype = cst.col_id
               INNER JOIN tbl_task cs
                  ON cst.col_id = cs.col_taskdict_tasksystype
               WHERE cs.col_id = v_entity_id
                 AND lower(ap.PAGETYPE_CODE) = 'full_page_task_detail'
                 AND lower(ap.TARGET_RAWTYPE) = 'page'
               ORDER BY ap.SHOWORDER) p
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;

  -- External Party
  --get FULL_PAGE_PARTY_DETAIL config if it exists
  IF (v_entity_type = 'extparty') THEN
    BEGIN
      SELECT p.TARGET_ELEMENTID
        INTO v_target_elementid
        FROM (SELECT ap.TARGET_ELEMENTID
                FROM vw_dcm_assocpage ap
               INNER JOIN tbl_dict_PartyType pt
                  ON ap.PARTYTYPE = pt.col_id
               INNER JOIN tbl_ExternalParty ep
                  ON pt.col_id = ep.COL_EXTERNALPARTYPARTYTYPE
               WHERE ep.col_id = v_entity_id
                 AND lower(ap.PAGETYPE_CODE) = 'full_page_party_detail'
                 AND lower(ap.TARGET_RAWTYPE) = 'page'
               ORDER BY ap.SHOWORDER) p
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;

  -- Portal Case
  --get FULL_PAGE_PORTALCASE_DETAIL config if it exists
  IF (v_entity_type = 'portalcase') THEN
    BEGIN
      SELECT p.TARGET_ELEMENTID
        INTO v_target_elementid
        FROM (SELECT ap.TARGET_ELEMENTID
                FROM vw_dcm_assocpage ap
               INNER JOIN tbl_dict_casesystype cst
                  ON ap.casesystype = cst.col_id
               INNER JOIN tbl_case cs
                  ON cst.col_id = cs.col_casedict_casesystype
               WHERE cs.col_id = v_entity_id
                 AND lower(ap.PAGETYPE_CODE) = 'full_page_portalcase_detail'
                 AND lower(ap.TARGET_RAWTYPE) = 'page'
               ORDER BY ap.SHOWORDER) p
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;

  -- PortalTask
  --get FULL_PAGE_PORTALTASK_DETAIL config if it exists
  IF (v_entity_type = 'portaltask') THEN
    BEGIN
      SELECT p.TARGET_ELEMENTID
        INTO v_target_elementid
        FROM (SELECT ap.TARGET_ELEMENTID
                FROM vw_dcm_assocpage ap
               INNER JOIN tbl_dict_tasksystype cst
                  ON ap.tasksystype = cst.col_id
               INNER JOIN tbl_task cs
                  ON cst.col_id = cs.col_taskdict_tasksystype
               WHERE cs.col_id = v_entity_id
                 AND lower(ap.PAGETYPE_CODE) = 'full_page_portaltask_detail'
                 AND lower(ap.TARGET_RAWTYPE) = 'page'
               ORDER BY ap.SHOWORDER) p
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;

  --try to find the default FOM_PAGE if one wasn't set for the Entity Type
  IF v_target_elementid IS NULL THEN
    BEGIN
      SELECT col_id
        INTO v_target_elementid
        FROM tbl_FOM_PAGE
       WHERE lower(col_usedfor) = v_entity_type
         AND col_systemdefault = 1 
         AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;

  RETURN v_target_elementid;

END;