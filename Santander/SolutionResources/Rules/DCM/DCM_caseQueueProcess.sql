DECLARE
    v_result   NUMBER;
    v_caseid   INTEGER;
    v_id       INTEGER;
    CURSOR cur_casequeue IS 
        SELECT
            col_id,
            col_casecasequeue
        FROM tbl_casequeue
        WHERE
        col_dict_vldtnstatcasequeue = (
            SELECT col_id
            FROM tbl_dict_validationstatus
            WHERE col_code = 'INVALID'
        )
    FOR UPDATE;

BEGIN 

    --START TASKS FOR ALL CASES IN CASE QUEUE WITH VALIDATION STATUS INVALID 
    OPEN cur_casequeue;
    LOOP
        FETCH cur_casequeue INTO v_id,v_CaseId;
        EXIT WHEN cur_casequeue%notfound;

       --INSERT INTO TBL_LOG (col_data1)   values('DCM_CASEQUEUEPROC6 LOOP, caseID='||TO_CHAR(v_CaseId)||', v_id='||TO_CHAR(v_id));
        
        DELETE FROM tbl_casequeue WHERE CURRENT OF cur_casequeue;

        v_result := f_dbg_adddebugtrace(
        caseid => v_CaseId,
        location => 'DCM_caseQueueProc5 before call of DCM_routeCaseTasksFn3',
        message => 'Case '|| TO_CHAR(v_CaseId)|| ' before DCM_routeCaseTasksFn3 invocation',
        rule => 'DCM_caseQueueProcCC6',
        taskid => NULL
        );

       v_result := f_DCM_copyCaseToCache(CaseId => v_CaseId); 

        --v_result := f_dcm_routecasetasksfn3(caseid => v_caseid);
        v_result := f_dcm_routeCaseCCTasksCCFn3(CaseId => v_caseid);
      
        v_result := f_dbg_adddebugtrace(
                    caseid => v_caseid,
                    location => 'DCM_caseQueueProc5 after call of DCM_routeCaseTasksFn3',
                    message => 'Case '|| TO_CHAR(v_caseid) || ' after DCM_routeCaseTasksFn3 invocation',
                    rule => 'DCM_caseQueueProc6',
                    taskid => NULL
                    );

        --v_result := f_dcm_caserouteautomaticfn(caseid => v_caseid);
        v_result := f_dcm_caseCCRouteAutomaticFn(caseid => v_caseid);
        
        --v_result := f_dcm_executeautotaskfn(caseid => v_caseid);
        v_result := f_dcm_executeAutoTaskCCFn(CaseId => v_caseid);
         
        --v_result := f_DCM_setSlaHistory(caseid => v_caseid);
        v_result := f_DCM_setSlaHistoryCC(caseid => v_caseid, geLinkedCacheRecords=>1);
        
        --v_result := f_dcm_registerslaaction(caseid => v_caseid);
        v_result := f_dcm_registerSlaActionCC(caseid => v_caseid, geLinkedCacheRecords=>1);
        
        --v_result := f_dcm_monitorqueueeventfn ();
        v_result := f_dcm_monitorQueueEventCCFn ();

        v_result := f_DCM_updateCaseFromCache(CaseId => v_CaseId);
        v_result := f_DCM_clearCache(CaseId => v_CaseId);
    END LOOP;

    --moved into DCM_taskSLAProcess
    --DCM-5496    
    --v_result := f_DCM_regSlaActionGlobal();    
    v_result := f_util_createsyslogfn(message => 'FOR TASKS: Auto Route Event Triggered');
END;