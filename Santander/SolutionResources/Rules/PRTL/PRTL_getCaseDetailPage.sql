DECLARE
  --input
  v_case_id INTEGER;

  --calculated
  v_TARGET_RAWTYPE   NVARCHAR2(255);
  v_TARGET_ELEMENTID NVARCHAR2(255);
  v_PAGECODE         NVARCHAR2(255);
  v_ASSOCPAGE        INTEGER;
  v_PAGEPARAMS       NCLOB;

BEGIN
  --input
  v_case_id := :Case_Id;

  --calculated
  v_TARGET_RAWTYPE   := NULL;
  v_TARGET_ELEMENTID := NULL;
  v_PAGEPARAMS       := NULL;
  v_PAGECODE         := NULL;
  v_ASSOCPAGE        := NULL;

  --system
  :ErrorCode    := 0;
  :ErrorMessage := '';

  --get FULL_PAGE_PORTALCASE_DETAIL config if it exists
  BEGIN
    SELECT ap.TARGET_RAWTYPE, ap.TARGET_ELEMENTID, ap.PAGEPARAMS, ap.id
      INTO v_TARGET_RAWTYPE, v_TARGET_ELEMENTID, v_PAGEPARAMS, v_ASSOCPAGE
      FROM vw_dcm_assocpage ap
     INNER JOIN tbl_dict_casesystype cst
        ON ap.casesystype = cst.col_id
     INNER JOIN tbl_case cs
        ON cst.col_id = cs.col_casedict_casesystype
     WHERE cs.col_id = v_case_id
       AND lower(ap.PAGETYPE_CODE) = lower('FULL_PAGE_PORTALCASE_DETAIL');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END;

  --try to find the default FOM_PAGE if one wasn't set for the Case Type
  IF v_TARGET_RAWTYPE IS NULL OR v_TARGET_ELEMENTID IS NULL THEN
    BEGIN
      SELECT col_id
        INTO v_TARGET_ELEMENTID
        FROM tbl_FOM_PAGE
       WHERE lower(col_usedfor) = 'portalcase'
         AND col_systemdefault = 1
         AND ROWNUM = 1;
      v_TARGET_RAWTYPE := 'PAGE';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;

  --set the remaining params if target FOM_PAGE is found
  IF v_TARGET_RAWTYPE IS NOT NULL AND v_TARGET_ELEMENTID IS NOT NULL THEN
    IF upper(v_TARGET_RAWTYPE) = 'PAGE' THEN
      v_PAGECODE := 'root_UTIL_BasePage';
      OPEN :CUR_PARAMS FOR
        SELECT 'app' AS NAME, 'PortalCaseDetailRuntime' AS VALUE
          FROM DUAL
        UNION
        SELECT 'group' AS NAME, 'FOM' AS VALUE
          FROM DUAL
        UNION
        SELECT 'usePageConfig' AS NAME, '1' AS VALUE
          FROM DUAL;
    ELSE
      v_PAGECODE := v_TARGET_ELEMENTID;
    END IF;
  ELSE
    v_PAGECODE := 'root_UTIL_BasePage';
    OPEN :CUR_PARAMS FOR
      SELECT 'app' AS NAME, 'ErrorNotice' AS VALUE
        FROM DUAL
      UNION
      SELECT 'group' AS NAME, 'UTIL' AS VALUE
        FROM DUAL
      UNION
      SELECT 'usePageConfig' AS NAME, '0' AS VALUE
        FROM DUAL;
  END IF;

  --set output params
  :TARGET_RAWTYPE   := v_TARGET_RAWTYPE;
  :TARGET_ELEMENTID := v_TARGET_ELEMENTID;
  :USERPAGEPARAMS   := v_PAGEPARAMS;
  :PAGECODE         := v_PAGECODE;
  :ASSOCPAGE        := v_ASSOCPAGE;
END;