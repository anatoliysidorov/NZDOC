DECLARE
  v_CaseId NUMBER;
  v_res    NUMBER;

  v_createdBy    NVARCHAR2(255);
  v_domain       NVARCHAR2(255);
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);

BEGIN
  v_errorCode    := 0;
  v_errorMessage := '';
  v_createdBy    := :TOKEN_USERACCESSSUBJECT;
  v_domain       := f_UTIL_getDomainFn();

  -- ALL DATA FOR CASE IDENTIFIED BY CASE ID AS FUNCTION PARAMETER
  v_CaseId := :Id;

  BEGIN
  
    -- CASE WORKITEM
    DELETE FROM (SELECT * FROM tbl_cw_workitem WHERE col_id = (SELECT col_cw_workitemcase FROM tbl_case WHERE col_id = v_CaseId));
  
    -- CASE EVENT QUEUE ELEMENTS RELATED TO CASE
    DELETE FROM (SELECT * FROM tbl_caseeventqueue WHERE col_caseeventqueuecase = v_CaseId);
  
    -- CASE EVENT QUEUE ELEMENTS RELATED TO CASE STATE INIT
    DELETE FROM (SELECT *
                   FROM tbl_caseeventqueue
                  WHERE col_caseeventqueuecaseevent IN
                        (SELECT col_id
                           FROM tbl_caseevent
                          WHERE col_caseeventcasestateinit IN
                                (SELECT col_id FROM tbl_map_casestateinitiation WHERE col_map_casestateinitcase = v_CaseId)));
  
    -- CASE QUEUE ELEMENTS
    DELETE FROM (SELECT * FROM tbl_casequeue WHERE col_casecasequeue = v_CaseId);
  
    -- TASK EVENT QUEUE ELEMENTS RELATED TO TASKS IN CASE
    DELETE FROM (SELECT * FROM tbl_taskeventqueue WHERE col_taskeventqueuetask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId));
  
    -- TASK EVENT QUEUE ELEMENTS RELATED TO TASK STATE INIT
    DELETE FROM (SELECT *
                   FROM tbl_taskeventqueue
                  WHERE col_taskeventqueuetaskevent IN
                        (SELECT col_id
                           FROM tbl_taskevent
                          WHERE col_taskeventtaskstateinit IN
                                (SELECT col_id
                                   FROM tbl_map_taskstateinitiation
                                  WHERE col_map_taskstateinittask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId))));
  
    -- AUTO RULE PARAMETERS RELATED TO AUTOMATIC TASKS
    DELETE FROM (SELECT * FROM tbl_autoruleparameter WHERE col_autoruleparametertask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId));
  
    -- AUTO RULE PARAMETERS RELATED TO TASK STATE INITIATION
    DELETE FROM (SELECT *
                   FROM tbl_autoruleparameter
                  WHERE col_ruleparam_taskstateinit IN
                        (SELECT col_id
                           FROM tbl_map_taskstateinitiation
                          WHERE col_map_taskstateinittask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId)));
  
    -- AUTO RULE PARAMETERS RELATED TO TASK DEPENDENCY
    DELETE FROM (SELECT *
                   FROM tbl_autoruleparameter
                  WHERE col_autoruleparamtaskdep IN
                        (SELECT col_id
                           FROM tbl_taskdependency
                          WHERE col_tskdpndchldtskstateinit IN
                                (SELECT col_id
                                   FROM tbl_map_taskstateinitiation
                                  WHERE col_map_taskstateinittask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId))
                            AND col_tskdpndprnttskstateinit IN
                                (SELECT col_id
                                   FROM tbl_map_taskstateinitiation
                                  WHERE col_map_taskstateinittask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId))));
  
    -- AUTO RULE PARAMETERS RELATED TO TASK EVENTS
    DELETE FROM (SELECT *
                   FROM tbl_autoruleparameter
                  WHERE col_taskeventautoruleparam IN
                        (SELECT col_id
                           FROM tbl_taskevent
                          WHERE col_taskeventtaskstateinit IN
                                (SELECT col_id
                                   FROM tbl_map_taskstateinitiation
                                  WHERE col_map_taskstateinittask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId))));
  
    -- AUTO RULE PARAMETERS RELATED TO CASE EVENTS
    DELETE FROM (SELECT *
                   FROM tbl_autoruleparameter
                  WHERE col_caseeventautoruleparam IN
                        (SELECT col_id
                           FROM tbl_caseevent
                          WHERE col_caseeventcasestateinit IN
                                (SELECT col_id FROM tbl_map_casestateinitiation WHERE col_map_casestateinitcase = v_CaseId)));
  
    -- TASK EVENTS
    DELETE FROM (SELECT *
                   FROM tbl_taskevent
                  WHERE col_taskeventtaskstateinit IN
                        (SELECT col_id
                           FROM tbl_map_taskstateinitiation
                          WHERE col_map_taskstateinittask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId)));
  
    -- CASE EVENTS
    DELETE FROM (SELECT *
                   FROM tbl_caseevent
                  WHERE col_caseeventcasestateinit IN (SELECT col_id FROM tbl_map_casestateinitiation WHERE col_map_casestateinitcase = v_CaseId));
  
    -- CASE STATE INITIATIONS
    DELETE FROM (SELECT * FROM tbl_map_casestateinitiation WHERE col_map_casestateinitcase = v_CaseId);
  
    -- TASK DEPENDENCIES
    DELETE FROM (SELECT *
                   FROM tbl_taskdependency
                  WHERE col_tskdpndchldtskstateinit IN
                        (SELECT col_id
                           FROM tbl_map_taskstateinitiation
                          WHERE col_map_taskstateinittask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId))
                    AND col_tskdpndprnttskstateinit IN
                        (SELECT col_id
                           FROM tbl_map_taskstateinitiation
                          WHERE col_map_taskstateinittask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId)));
  
    -- TASK STATE INITIATION
    DELETE FROM (SELECT *
                   FROM tbl_map_taskstateinitiation
                  WHERE col_map_taskstateinittask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId));
  
    -- CASE PARTIES
    DELETE FROM (SELECT * FROM tbl_caseparty WHERE col_casepartycase = v_CaseId);
  
    -- SLA EVENTS FOR CASE
    DELETE FROM (SELECT * FROM tbl_slaevent WHERE col_slaeventcase = v_CaseId);
  
    -- SLA ACTIONS
    DELETE FROM (SELECT *
                   FROM tbl_slaaction
                  WHERE col_slaactionslaevent IN
                        (SELECT col_id FROM tbl_slaevent WHERE col_slaeventtask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId)));
  
    -- SLA EVENTS FOR TASKS IN CASE
    DELETE FROM (SELECT * FROM tbl_slaevent WHERE col_slaeventtask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId));
  
    -- CASE HISTORY
    DELETE FROM (SELECT * FROM tbl_history WHERE col_historycase = v_CaseId);
  
    -- CASE TASKS HISTORY
    DELETE FROM (SELECT * FROM tbl_history WHERE col_historytask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId));
  
    -- MAPPING BETWEEN DOCUMENTS AND DYNAMIC TASKS
    /*  delete from (
    select * from tbl_documentdynamictask where col_tbl_dynamictask in
      (select col_id from tbl_dynamictask where col_casedynamictask = v_CaseId)
    ); */
  
    -- DATE EVENTS FOR CASE
    DELETE FROM (SELECT * FROM tbl_dateevent WHERE col_dateeventcase = v_CaseId);
  
    -- DATE EVENTS FOT TASKS
    DELETE FROM (SELECT * FROM tbl_dateevent WHERE col_dateeventtask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId));
  
    -- WORKITEMS
    DELETE FROM (SELECT * FROM tbl_tw_workitem WHERE col_id IN (SELECT col_tw_workitemtask FROM tbl_task WHERE col_casetask = v_CaseId));
  
    -- TASKEXT
    DELETE FROM (SELECT * FROM tbl_taskext WHERE col_taskexttask IN (SELECT col_id FROM tbl_task WHERE col_casetask = v_CaseId));
  
    -- TASK DOCUMENTS
    FOR cur IN (SELECT col_id AS id FROM tbl_task WHERE col_casetask = v_CaseId) LOOP
      v_res := f_doc_destroydocumentfn(case_id                 => NULL,
                                       casetype_id             => NULL,
                                       caseworker_id           => NULL,
                                       errorcode               => v_errorCode,
                                       errormessage            => v_errorMessage,
                                       extparty_id             => NULL,
                                       ids                     => NULL,
                                       task_id                 => cur.id,
                                       team_id                 => NULL,
                                       token_domain            => v_domain,
                                       token_useraccesssubject => v_createdBy);
    END LOOP;
  
    -- TASKS
    DELETE FROM (SELECT * FROM tbl_task WHERE col_casetask = v_CaseId);
  
    -- CASE SERVICE EXT
    DELETE FROM (SELECT * FROM tbl_caseserviceext WHERE col_casecaseserviceext = v_CaseId);
  
    -- CASEEXT
    DELETE FROM (SELECT * FROM tbl_caseext WHERE col_caseextcase = v_CaseId);
  
    -- CASELINK
    DELETE FROM (SELECT * FROM tbl_caselink WHERE col_caselinkparentcase = v_CaseId OR col_caselinkchildcase = v_CaseId);
  
    --Threads/ThreadCaseWorkers
    delete from tbl_threadcaseworker 
    where col_threadid in (select col_id 
                          from tbl_thread 
                          where col_threadcase = v_CaseId);

    delete from tbl_thread where col_threadcase = v_CaseId;

    -- CASE DOCUMENTS
    v_res := f_doc_destroydocumentfn(case_id                 => v_CaseId,
                                     casetype_id             => NULL,
                                     caseworker_id           => NULL,
                                     errorcode               => v_errorCode,
                                     errormessage            => v_errorMessage,
                                     extparty_id             => NULL,
                                     ids                     => NULL,
                                     task_id                 => NULL,
                                     team_id                 => NULL,
                                     token_domain            => v_domain,
                                     token_useraccesssubject => v_createdBy);
                                     
    --CLEAN UP DATA FROm CUSTOM BOs
    BEGIN
      v_res := f_DCM_cleanUpCustomBO(CASEID       =>v_CaseId,
                                     ERRORCODE    =>v_errorCode,
                                     ERRORMESSAGE =>v_errorMessage);
    EXCEPTION
      WHEN OTHERS THEN
        v_errorCode    := 305;
        v_errorMessage := f_UTIL_addToMessage(originalMsg => v_errorMessage, newMsg => 'ERROR: There was a problem clean up custom BOs data');
        v_errorMessage := f_UTIL_addToMessage(originalMsg => v_errorMessage, newMsg => 'ERROR CODE: ' || TO_CHAR(v_errorCode));
        v_errorMessage := f_UTIL_addToMessage(originalMsg => v_errorMessage, newMsg => 'ERROR MSG: ' || substr(SQLERRM, 1, 200));
        GOTO cleanup;
    END;

    -- CASE
    DELETE FROM (SELECT * FROM tbl_case WHERE col_id = v_CaseId);
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errorCode    := 102;
      v_errorMessage := substr(SQLERRM, 1, 200);
      GOTO cleanup;
  END;

  <<cleanup>>
  IF v_errorCode <> 0 THEN
    ROLLBACK;
  END IF;
  :errorCode    := v_errorCode;
  :errorMessage := v_errorMessage;
END;