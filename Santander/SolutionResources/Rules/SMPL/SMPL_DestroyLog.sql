DECLARE
  v_Id Number;
  v_ErrorCode     NUMBER;
  v_ErrorMessage  NVARCHAR2(255); 
  v_caseExist Number;
  
BEGIN
  v_ErrorCode := 0; 
  v_ErrorMessage := '';
  :affectedRows := 0; 
  v_Id := :Id;
  
	---Input params check 
	IF v_Id IS NULL THEN
	v_ErrorMessage := 'Id can not be empty';
	v_ErrorCode := 101;
	GOTO cleanup;
	END IF;

	---Check if there are Cases with this priority
	DELETE tbl_SMPL_Log
	WHERE col_id = v_Id;

	--get affected rows
	:affectedRows := SQL%ROWCOUNT; 	
	
	<<cleanup>> 
	:ErrorMessage := v_ErrorMessage;
	:ErrorCode := v_ErrorCode; 
END;