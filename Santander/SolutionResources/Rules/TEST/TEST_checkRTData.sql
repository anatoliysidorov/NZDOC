DECLARE
    /*--SYSTEM*/
    v_Message NCLOB;
    
    /*--OUTPUT*/
    v_errorcode NUMBER;
    v_errormessage NCLOB;
BEGIN
    v_errorcode := 0;
    v_errormessage := '';
    v_Message := '';
    
    /*--check that all Cases references exist*/
    FOR rec IN(SELECT CASEID AS CASEID,
            NVL(CASESYSTYPE_CODE,'missing case type') AS CASESYSTYPE,
            NVL(TO_CHAR(PRIORITY_VALUE),'missing priority') AS PRIORITY,
            NVL(STATECONFIG_CODE,'missing state config') AS STATECONFIG,
            NVL(CASESTATE_NAME,'missing state')  AS CASESTATE
    FROM    vw_DCM_SimpleCase
    WHERE   CASESYSTYPE_CODE IS NULL
            OR PRIORITY_VALUE IS NULL
            OR STATECONFIG_CODE IS NULL
            OR CASESTATE_ID IS NULL)
    LOOP
        v_errorCode := 101;
        v_message := v_message || f_UTIL_wrapTextInNode(NodeTag => 'li',
                                                        msg => rec.CASEID || '-' || rec.CASESYSTYPE || '-'|| rec.PRIORITY ||'-' || rec.STATECONFIG || '-' || rec.CASESTATE) ;
    END LOOP;
    
    /*--check that all Task references exist*/
    FOR rec IN(SELECT TASKID AS TASKID,
            NVL(TASKSYSTYPE_CODE,'missing task type') AS TASKSYSTYPE,
            NVL(STATECONFIG_CODE,'missing state config') AS STATECONFIG,
            NVL(TASKSTATE_NAME,'missing state')  AS TASKSTATE
    FROM    vw_DCM_SimpleTask3
     WHERE   PARENTID > 0 AND (
            TASKSYSTYPE_CODE IS NULL
            OR STATECONFIG_CODE IS NULL
            OR TASKSTATE_CODE IS NULL))
    LOOP
        v_errorCode := 101;
        v_message := v_message || f_UTIL_wrapTextInNode(NodeTag => 'li',
                                                        msg => rec.TASKID || '-' || rec.TASKSYSTYPE || '-' || rec.STATECONFIG || '-' || rec.TASKSTATE) ;
    END LOOP;
    
    /*--report any errors*/
    IF v_errorcode > 0 THEN
        :ErrorCode := v_errorcode;
        :ErrorMessage := v_message;
    ELSE
        :ErrorCode := 0;
        :ErrorMessage := 'Case and Task test passed';
    END IF;
END;