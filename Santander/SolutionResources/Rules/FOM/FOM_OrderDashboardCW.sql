DECLARE 
    v_errorCode 	   number;
    v_errorMessage 	   nvarchar2(255);
    v_return 		   number;
    v_affectedRows	   number; 
	v_FromID		   NUMBER;
	v_ToID			   NUMBER;
    v_Position     	   NVARCHAR2(255);
BEGIN 
	v_FromID        := :FromID;
	v_ToID          := :ToID;
	v_Position      := :Position;
    :ErrorCode := 0;
    :ErrorMessage := '';
    
    v_return := F_FOM_OrderDashboardCWFn(FromID => v_FromID, Position => v_Position, ToID => v_ToID, affectedRows => v_affectedRows, ErrorCode => v_errorCode, ErrorMessage => v_errorMessage);
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