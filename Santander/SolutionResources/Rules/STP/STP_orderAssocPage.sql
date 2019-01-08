DECLARE
  v_fromid         NUMBER;
  v_toid           NUMBER;
  v_position       NVARCHAR2(255);
  v_order          NUMBER;
  v_toorder        NUMBER;
  v_casetypeid     NUMBER;
  v_tasktypeid     NUMBER;
  v_partytypeid    NUMBER;
  v_workactivityid NUMBER;
  v_pagetypeid     NUMBER;

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
  SELECT col_assocpagedict_casesystype, col_assocpagedict_tasksystype, col_partytypeassocpage, col_dict_watypeassocpage, col_assocpageassocpagetype
    INTO v_casetypeid, v_tasktypeid, v_partytypeid, v_workactivityid, v_pagetypeid
    FROM tbl_assocpage
   WHERE col_id = v_fromid;

  BEGIN
    FOR rec IN (SELECT col_id AS id
                  FROM tbl_assocpage
                 WHERE (nvl(v_casetypeid, 0) = 0 OR (nvl(v_casetypeid, 0) > 0 AND col_assocpagedict_casesystype = v_casetypeid))
                   AND (nvl(v_tasktypeid, 0) = 0 OR (nvl(v_tasktypeid, 0) > 0 AND col_assocpagedict_tasksystype = v_tasktypeid))
                   AND (nvl(v_partytypeid, 0) = 0 OR (nvl(v_partytypeid, 0) > 0 AND col_partytypeassocpage = v_partytypeid))
                   AND (nvl(v_workactivityid, 0) = 0 OR (nvl(v_workactivityid, 0) > 0 AND col_dict_watypeassocpage = v_workactivityid))
                   AND col_assocpageassocpagetype = v_pagetypeid
                 ORDER BY col_order) LOOP
    
      IF rec.id = v_fromid THEN
        continue;
      END IF;
    
      IF (rec.id = v_toid AND lower(v_position) = 'before') THEN
        v_toorder := v_order;
        v_order   := v_order + 1;
      END IF;
    
      UPDATE tbl_assocpage SET col_order = v_order WHERE col_id = rec.id;
    
      IF (rec.id = v_toid AND lower(v_position) = 'after') THEN
        v_order   := v_order + 1;
        v_toorder := v_order;
      END IF;
    
      v_order := v_order + 1;
    END LOOP;
  
    UPDATE tbl_assocpage SET col_order = v_toorder WHERE col_id = v_fromid;
  
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