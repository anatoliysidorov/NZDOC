DECLARE
  v_fromid      NUMBER;
  v_toid        NUMBER;
  v_position    NVARCHAR2(255);
  v_order       NUMBER;
  v_toorder     NUMBER;
  v_casetypeid  NUMBER;
  v_tasktypeid  NUMBER;
  v_procedureid NUMBER;

  v_errorcode    INTEGER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_fromid   := :FromID;
  v_toid     := :ToID;
  v_position := :Position;
  v_order    := 1;

  v_errorcode    := 0;
  v_errormessage := '';

  --Check the input params
  IF v_fromid IS NULL THEN
    v_errormessage := 'From Id can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  ELSIF v_toid IS NULL THEN
    v_errormessage := 'To Id can not be empty';
    v_errorcode    := 102;
    GOTO cleanup;
  ELSIF v_position IS NULL THEN
    v_errormessage := 'Position can not be empty';
    v_errorcode    := 103;
    GOTO cleanup;
  END IF;

  -- Get info
  SELECT col_commoneventtmplcasetype,
         col_commoneventtmplprocedure,
         col_commoneventtmpltasktype
    INTO v_casetypeid,
         v_procedureid,
         v_tasktypeid
    FROM tbl_commoneventtmpl
   WHERE col_id = v_fromid;

  BEGIN
    FOR rec IN (SELECT col_id AS id
                  FROM tbl_commoneventtmpl
                 WHERE col_commoneventtmplcasetype = v_casetypeid
                    OR col_commoneventtmplprocedure = v_procedureid
                    OR col_commoneventtmpltasktype = v_tasktypeid
                 ORDER BY col_eventorder) LOOP
    
      IF rec.id = v_fromid THEN
        CONTINUE;
      END IF;
    
      IF (rec.id = v_toid AND lower(v_position) = 'before') THEN
        v_toorder := v_order;
        v_order   := v_order + 1;
      END IF;
    
      UPDATE tbl_commoneventtmpl SET col_eventorder = v_order WHERE col_id = rec.id;
    
      IF (rec.id = v_toid AND lower(v_position) = 'after') THEN
        v_order   := v_order + 1;
        v_toorder := v_order;
      END IF;
    
      v_order := v_order + 1;
    END LOOP;
  
    UPDATE tbl_commoneventtmpl SET col_eventorder = v_toorder WHERE col_id = v_fromid;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errormessage := substr(SQLERRM, 1, 200);
      v_errorcode    := 104;
      ROLLBACK;
      GOTO cleanup;
  END;

  <<cleanup>>
  :errorMessage := v_errormessage;
  :errorCode    := v_errorcode;
END;
