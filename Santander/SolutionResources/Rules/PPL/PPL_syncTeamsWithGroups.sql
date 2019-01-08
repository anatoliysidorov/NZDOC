DECLARE 
    v_errorCode number;
    v_errorMessage nvarchar2(255);
    v_return number;
BEGIN 
    :ErrorCode := 0;
    :ErrorMessage := '';
    v_return := F_PPL_syncTeamsWithGroupsFn(ErrorCode => v_errorCode, ErrorMessage => v_errorMessage);
    IF v_errorCode <> 0 THEN
    	:ErrorCode := v_errorCode;
        :ErrorMessage := v_errorMessage;
        RollBack;
    END IF;
EXCEPTION 
	WHEN OTHERS THEN 
		:ErrorCode := 101; 
		:ErrorMessage := SQLERRM;
        rollback;
END;