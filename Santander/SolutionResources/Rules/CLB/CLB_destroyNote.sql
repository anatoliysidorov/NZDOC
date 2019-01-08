DECLARE
  v_id NUMBER;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id := :Id;

  v_errorcode    := 0;
  v_errormessage := '';

  --Input params check
  IF v_id IS NULL THEN
    v_errormessage := 'Id can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  -- delete from tbl_note
  DELETE tbl_note WHERE col_id = v_id;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;