DECLARE
  v_id        NUMBER;
  v_typestate NVARCHAR2(255);

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id        := :Id;
  v_typestate := :TypeState;

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  ---Input params check 
  IF v_id IS NULL THEN
    v_errormessage := 'Id can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;
  IF (v_typestate IS NULL) THEN
    v_errormessage := 'TypeState can not be empty';
    v_errorcode    := 102;
    GOTO cleanup;
  END IF;
  IF (UPPER(v_typestate) NOT IN ('TASK', 'CASE')) THEN
    v_errormessage := 'TypeState can not be other type, than TASK or CASE';
    v_errorcode    := 103;
    GOTO cleanup;
  END IF;

  IF UPPER(v_typestate) = 'TASK' THEN
    DELETE TBL_DICT_TASKTRANSITION WHERE col_id = v_id;
  ELSE
    DELETE TBL_DICT_CASETRANSITION WHERE col_id = v_id;
  END IF;

  --get affected rows
  :affectedRows := SQL%ROWCOUNT;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;