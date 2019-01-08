DECLARE
    v_ConfigId INTEGER;
    v_input NCLOB;
    v_RootObjectId INTEGER;
    v_RootObjectName nvarchar2(255) ;
    v_session nvarchar2(255) ;

    /*--standard*/
    v_result    NUMBER;
BEGIN
    v_ConfigId := :ConfigId;
    v_input := :Input;
    v_RootObjectId := :RootObjectIdId;
    v_RootObjectName := UPPER(:RootObjectName) ;
	
	:errorCode := 0;
    :errorMessage := '';
    :SuccessResponse := '';

	/*--save data*/
    v_result := f_DOM_populateDynInsCache(ConfigId => v_ConfigId,
                                          Input => v_input,
                                          RootObjectId => v_RootObjectId,
                                          RootObjectName => v_RootObjectName,
                                          Session => v_session) ;
    v_result := f_DOM_executeDynIns(ConfigId => v_ConfigId,
                                    Session => v_session) ;
    :SuccessResponse := 'Saved data to ' || v_RootObjectName;

EXCEPTION
WHEN OTHERS THEN
    :errorCode := 101;
    :errorMessage := dbms_utility.format_error_stack;
    :SuccessResponse := '';
END;