DECLARE
    v_userId number;
    v_MessageParams NES_TABLE;
    v_result number;
BEGIN
    v_userId := -1;
    :UserId := 0;
    :errorCode :=0;
    :errorMessage := '';
    
    IF :UCode IS NULL THEN
        :errorCode := 120;
        :errorMessage := 'User Code can not be empty!';
    ELSE
        BEGIN
            SELECT USERID
            INTO v_userId
            FROM VW_USERS
            WHERE CODE = :UCode;
        
            :UserId := v_userId;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            :errorCode := 121;
            v_MessageParams:= NES_TABLE(); 
            v_MessageParams.extend(1);
            v_MessageParams(1) := Key_Value('UCode', :UCode);
            
            v_result := LOC_i18n(MessageText => 'No User was found with Code = {{UCode}}', MessageResult => :errorMessage, MessageParams => v_MessageParams, MessageParams2 => NULL);
            --DBMS_OUTPUT.PUT_LINE(var_var);
            --:errorMessage := 'No User was found with Code = '|| :UCode;
        END;
    END IF;
    
END;