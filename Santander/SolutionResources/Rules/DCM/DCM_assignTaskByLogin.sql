/*
Example rule for assigning an owner to a Task using an AppBase login 
Type: SQL Non Query
Deploy as Function: FALSE
Input:
- Task_Id (integer, required)
- Login (text, required)
Output:
- ErrorMessage
- ErrorCode
- SuccessResponse
*/

DECLARE
    v_taskid       NUMBER;
    v_workbasketid NUMBER;
    v_login NVARCHAR2(255) ;

    /*--standard*/
    v_result    NUMBER;
    v_errorcode NUMBER;
    v_errormessage NVARCHAR2(255) ;
    v_SuccessResponse NCLOB;
BEGIN
    v_taskid := :Task_Id;
    v_login := UPPER(TRIM(:Login));

    /*--get workbasket from login*/
    SELECT     wb.ID
    INTO       v_workbasketid
    FROM       VW_PPL_SIMPLEWORKBASKET wb
    INNER JOIN VW_PPL_ACTIVECASEWORKERSUSERS cw ON(cw.ID = wb.CASEWORKER_ID)
    WHERE      CASEWORKER_ID > 0
               AND UPPER(cw.LOGIN) LIKE v_login;

    /*--standard*/
    v_errorcode := 0;    
    v_errormessage := '';
    v_result := F_DCM_assignTaskFn(Action => 'ASSIGN',
                                   CaseParty_Id => NULL,
                                   errorCode => v_errorCode,
                                   errorMessage => v_errorMessage,
                                   Note => NULL,
                                   SuccessResponse => v_SuccessResponse,
                                   Task_Id => v_taskid,
                                   WorkBasket_Id => v_workbasketid) ;
    IF v_errorCode > 0 THEN
        :errorCode := v_errorCode;
        :errorMessage := v_errorMessage;
    END IF;
    
    :SuccessResponse := v_SuccessResponse;
EXCEPTION
WHEN OTHERS THEN
    :errorCode := 101;
    :errorMessage := SQLERRM;
    :SuccessResponse := '';
END;