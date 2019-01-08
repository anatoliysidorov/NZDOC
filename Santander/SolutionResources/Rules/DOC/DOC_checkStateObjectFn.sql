DECLARE
  v_id            NUMBER;
  v_Case_Id       NUMBER;
  v_Task_Id       NUMBER;
  v_case_isfinish INT;
  v_task_isfinish INT;

  v_errorcode    INT;
  v_errormessage NCLOB;
BEGIN
  v_id            := :ID;
  v_Case_Id       := :CASE_ID;
  v_Task_Id       := :TASK_ID;
  v_case_isfinish := 0;
  v_task_isfinish := 0;

  v_errorcode    := 0;
  v_errormessage := '';

  IF v_id IS NULL THEN
    IF v_Task_Id IS NOT NULL THEN
      BEGIN
        SELECT nvl(ts.col_isfinish, 0)
          INTO v_task_isfinish
          FROM tbl_task t
         INNER JOIN tbl_dict_taskstate ts
            ON ts.col_id = t.col_taskdict_taskstate
         WHERE t.col_id = v_Task_Id;
      EXCEPTION
        WHEN no_data_found THEN
          v_task_isfinish := 0;
      END;
    ELSIF v_Case_Id IS NOT NULL THEN
      BEGIN
        SELECT nvl(cs.col_isfinish, 0)
          INTO v_case_isfinish
          FROM tbl_case cse
         INNER JOIN tbl_dict_casestate cs
            ON cs.col_id = cse.col_casedict_casestate
         WHERE cse.col_id = v_Case_Id;
      EXCEPTION
        WHEN no_data_found THEN
          v_case_isfinish := 0;
      END;
    END IF;
  ELSE
    BEGIN
      SELECT nvl(cs.col_isfinish, 0)
        INTO v_case_isfinish
        FROM tbl_doc_doccase dc
       INNER JOIN tbl_case c
          ON c.col_id = dc.col_doccasecase
       INNER JOIN tbl_dict_casestate cs
          ON cs.col_id = c.col_casedict_casestate
       WHERE dc.col_doccasedocument = v_id;
    EXCEPTION
      WHEN no_data_found THEN
        v_case_isfinish := 0;
        BEGIN
          SELECT nvl(ts.col_isfinish, 0)
            INTO v_task_isfinish
            FROM tbl_doc_doctask dt
           INNER JOIN tbl_task t
              ON t.col_id = dt.col_doctasktask
           INNER JOIN tbl_dict_taskstate ts
              ON ts.col_id = t.col_taskdict_taskstate
           WHERE dt.col_doctaskdocument = v_id;
        EXCEPTION
          WHEN no_data_found THEN
            v_task_isfinish := 0;
        END;
    END;
  
  END IF;

  IF v_case_isfinish = 1 THEN
    v_errorcode    := 110;
    v_errormessage := 'Case is finished. You can not modify Case Documents';
  END IF;
  IF v_task_isfinish = 1 THEN
    v_errorcode    := 111;
    v_errormessage := 'Task is finished. You can not modify Task Documents';
  END IF;

  :errorcode    := v_errorcode;
  :errormessage := v_errormessage;
END;
