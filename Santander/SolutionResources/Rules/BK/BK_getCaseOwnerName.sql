DECLARE
  v_name VARCHAR2(255);
BEGIN
  SELECT cw.name
    INTO v_name
    FROM tbl_Case c
    LEFT JOIN tbl_ppl_workbasket wb
      ON (c.col_caseppl_workbasket = wb.col_id)
    LEFT JOIN vw_ppl_activecaseworkersusers cw
      ON (wb.col_caseworkerworkbasket = cw.id)
   WHERE c.col_id = :Case_Id;

  :ResultText := v_name;
EXCEPTION
  WHEN no_data_found THEN
    :ResultText := 'Unassigned Case';
END;