DECLARE
    v_result NUMBER;
    v_CaseId INTEGER;
    v_queueParams NCLOB;
    v_UserAccessSubject nvarchar2(255) ;
    v_Domain nvarchar2(255) ;
    v_status nvarchar2(255) ;
    --cursor cur_casequeue is select col_id, col_casecasequeue from tbl_casequeue where col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = 'INVALID') for update;
    CURSOR cur_casequeue IS
        SELECT col_id, col_casecasequeue FROM tbl_casequeue
        WHERE col_dict_vldtnstatcasequeue =
            (
                SELECT col_id FROM tbl_dict_validationstatus WHERE col_code = 'INVALID'
            )
            FOR UPDATE skip locked;
    
    v_id INTEGER;
BEGIN
    --READ USER ACCESS SUBJECT FROM CLIENT CONTEXT
    BEGIN
        v_status := 'INVALID';
        SELECT sys_context('CLIENTCONTEXT','AccessSubject') INTO v_UserAccessSubject FROM dual;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_UserAccessSubject := NULL;
    END;
    --READ DOMAIN FROM CONFIGURATION
    v_Domain := f_UTIL_getDomainFn();
    --START TASKS FOR ALL CASES IN CASE QUEUE WITH VALIDATION STATUS INVALID
    --for rec in (select col_id, col_casecasequeue from tbl_casequeue where col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = v_status))
    OPEN cur_casequeue;
    LOOP
        FETCH cur_casequeue INTO v_id, v_caseid;
        
        EXIT WHEN cur_casequeue%NOTFOUND;
        DELETE FROM tbl_casequeue WHERE col_id = v_id;
        
        --delete from tbl_casequeue where current of cur_casequeue;
        --v_result := f_dcm_validateCase(CaseId => v_caseid);
        v_result := f_DBG_addDebugTrace(CaseId => v_caseid,
                                        Location => 'DCM_caseQueueProc5 before call of DCM_routeCaseTasksFn3',
                                        MESSAGE => 'Case ' || TO_CHAR(v_caseid) || ' before DCM_routeCaseTasksFn3 invocation',
                                        Rule => 'DCM_caseQueueProc7',
                                        TaskId => NULL) ;
        v_result := f_dcm_routeCaseCCTasksCCFn3(CaseId => v_caseid) ;
        v_result := f_DBG_addDebugTrace(CaseId => v_caseid,
                                        Location => 'DCM_caseQueueProc5 after call of DCM_routeCaseTasksFn3',
                                        MESSAGE => 'Case ' || TO_CHAR(v_caseid) || ' after DCM_routeCaseTasksFn3 invocation',
                                        Rule => 'DCM_caseQueueProc7',
                                        TaskId => NULL) ;
        v_result := f_dcm_caseCCRouteAutomaticFn(CaseId => v_caseid) ;
        v_result := f_dcm_executeAutoTaskCCFn(CaseId => v_caseid) ;
        v_result := f_dcm_registerSlaActionCC(CaseId => v_caseid, geLinkedCacheRecords=>1);
        v_result := f_dcm_monitorQueueEventCCFn();
    END LOOP;
    CLOSE cur_casequeue;
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    --Checking SLAs for all cases will be only conducted by scheduled task (rule DCM_caseQueueProc6). It takes too much time to check SLAs for all cases during processing of each case
  /*
  v_result := f_dcm_regSlaActionGlobal();
  */
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
END;