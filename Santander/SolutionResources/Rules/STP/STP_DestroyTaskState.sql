DECLARE
  v_id NUMBER;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id := :Id;

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  ---Input params check 
  IF v_id IS NULL THEN
    v_errormessage := 'Id can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  DELETE TBL_DICT_TASKSTATE WHERE col_id = v_id;

  --get affected rows
  :affectedRows := SQL%ROWCOUNT;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
  --DBMS_output.put_line(v_errormessage);
END;