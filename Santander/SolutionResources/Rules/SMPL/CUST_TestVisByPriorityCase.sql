DECLARE
  v_priorityCode NVARCHAR2(255);
  v_caseId       NUMBER;
BEGIN
  v_caseID := :CASE_ID;

  -- select priority code
  SELECT p.col_Code INTO v_priorityCode FROM tbl_case cs INNER JOIN tbl_stp_priority p ON p.col_id = cs.col_stp_prioritycase WHERE cs.col_id = v_caseId;

  IF v_priorityCode = 'MINOR' THEN
    RETURN 0; --ELEMENT SHOULD BE HIDDEN
  ELSE
    RETURN 1; --ELEMENT SHOULD BE VISIBLE
  END IF;
END;