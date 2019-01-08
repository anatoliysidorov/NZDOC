DECLARE
   v_id             NUMBER;
   v_errorcode      NUMBER;
   v_errormessage   NVARCHAR2(255);
BEGIN
   v_id := :Id;
   :affectedRows := 0;
   v_errorcode := 0;
   v_errormessage := '';
  :SuccessResponse := EMPTY_CLOB();

   --Input params check
  IF v_id IS NULL
  THEN
    v_errormessage := 'Id can not be empty';
    v_errorcode := 101;
    GOTO cleanup;
  ELSE 
    :SuccessResponse := 'Record has been deleted';
  END IF;

  BEGIN
    DELETE tbl_ac_permission
     WHERE col_id = v_id;   
    :affectedRows := SQL%ROWCOUNT;
  EXCEPTION
  WHEN OTHERS THEN
    :affectedRows := 0;
    v_errorcode := 102;
    v_errormessage := SUBSTR(SQLERRM, 1, 200);
    :SuccessResponse := '';         
  END;

  <<cleanup>>
  :affectedRows := SQL%ROWCOUNT;
  :errorCode := v_errorcode;
  :errorMessage := v_errormessage;
END;