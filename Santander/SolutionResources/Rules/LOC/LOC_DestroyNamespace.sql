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

	---Check if there are Keys with this NamespaceID
	SELECT COUNT(*) INTO v_Exist FROM tbl_LOC_Key WHERE tbl_LOC_Key.col_NamespaceID = v_id;

	IF v_Exist > 0 THEN
		v_errorMessage := 'You can not delete this Namespace';
		v_errorMessage := v_errorMessage || '<br>There are one or more Keys referencing this Namespace.';
		v_errorMessage := v_errorMessage || '<br>Change the Namespace value of those Keys and try again.';
		v_errorCode    := 102;
		GOTO cleanup;
	ELSE
		DELETE tbl_LOC_Namespace WHERE col_id = v_id;
	END IF;

	--get affected rows
	:affectedRows := SQL%ROWCOUNT;

	<<cleanup>>
	:errorMessage := v_errorMessage;
	:errorCode    := v_errorCode;
END;