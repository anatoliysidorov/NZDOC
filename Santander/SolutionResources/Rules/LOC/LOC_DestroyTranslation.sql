DECLARE
	v_id           NUMBER;
	v_errorCode    NUMBER;
	v_errorMessage NVARCHAR2(255);
	v_Exist		   NUMBER;

BEGIN
	v_errorCode    := 0;
	v_errorMessage := '';
	:affectedRows  := 0;
	v_id           := :Id;

	---Input params check 
	IF v_Id IS NULL THEN
		v_errorMessage := 'Id can not be empty';
		v_errorCode    := 101;
		GOTO cleanup;
	END IF;

	DELETE tbl_LOC_Translation WHERE col_id = v_id;

	--get affected rows
	:affectedRows := SQL%ROWCOUNT;

	<<cleanup>>
	:errorMessage := v_errorMessage;
	:errorCode    := v_errorCode;
END;