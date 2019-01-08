DECLARE
	--input
	v_code NVARCHAR2(255);
	
	--rule output
	v_name NVARCHAR2(255);
	v_config NCLOB;
	v_isDisabled INTEGER;
	v_found INTEGER;
	
	--system output
	v_ErrorCode INTEGER;
	v_ErrorMessage NCLOB;
  
BEGIN
	--init params
	v_code := :CODE;
	v_name := NULL;
	v_config := NULL;
	v_isDisabled := 0;
	
	v_ErrorCode := 0;
	v_ErrorMessage := NULL;	
	
	--get config
	BEGIN
		SELECT col_name, col_config, NVL(col_isdeleted, 0)
		INTO v_name, v_config, v_isDisabled
		FROM tbl_INT_IntegTarget
		WHERE lower(col_code) = lower(v_code);
	EXCEPTION
		WHEN OTHERS THEN 
			v_ErrorCode := 101;
			v_ErrorMessage := SUBSTR(SQLERRM, 1, 500);
	END;
	
	--populate output params
	:NAME := v_name;
	:CONFIG := v_config;
	:ISDISABLED := v_isDisabled;
	
	:ERRORCODE := v_ErrorCode;
	:ERRORMESSAGE := v_ErrorMessage;	
END;