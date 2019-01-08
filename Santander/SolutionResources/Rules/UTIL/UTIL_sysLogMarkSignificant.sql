DECLARE 
	v_id INTEGER;
	v_isId INTEGER;
	
BEGIN

	v_id := :ID;
	:ErrorCode := 0;
	:ErrorMessage := '';

	IF NVL(v_id, 0) > 0 THEN
		v_isId := f_UTIL_getId(errorcode    => :ErrorCode,
                             errormessage => :ErrorMessage,
                             id           => v_id,
                             tablename    => 'TBL_UTIL_Log');
		IF :ErrorCode > 0 THEN
			RETURN;
		END IF;
	END IF;
	
	UPDATE TBL_UTIL_Log SET
		col_IsSignificant = :IsSignificant
	WHERE col_Id = v_id;
END;