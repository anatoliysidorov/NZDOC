DECLARE
  v_Id           NUMBER;
  v_ErrorCode    NUMBER;
  v_ErrorMessage NVARCHAR2(255);
BEGIN
  v_ErrorCode := 0;
  v_ErrorMessage := '';
  :affectedRows := 0;
  v_Id := :Id;
  
  -- validate params
  IF v_Id IS NULL
  THEN
    v_ErrorMessage := 'Id can not be empty';
    v_ErrorCode := 101;
    GOTO cleanup;
  END IF;

  DELETE tbl_dict_tasktransition WHERE col_id = v_Id;
  
  :affectedRows := SQL%ROWCOUNT;
  <<cleanup>>
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode := v_ErrorCode;
END;