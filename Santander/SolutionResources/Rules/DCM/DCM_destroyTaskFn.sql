DECLARE
  v_TaskId NUMBER;
  v_CaseId NUMBER;
  v_res    NUMBER;
  v_TaskName     NVARCHAR2(255);
  v_strToReplace NVARCHAR2(255);
  v_createdBy    NVARCHAR2(255);
  v_domain       NVARCHAR2(255);
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);

BEGIN
  v_errorCode    := 0;
  v_errorMessage := '';
  v_createdBy    := :TOKEN_USERACCESSSUBJECT;
  v_domain       := :TOKEN_DOMAIN;

  -- ALL DATA FOR TASK IDENTIFIED BY TASK ID AS FUNCTION PARAMETER
  v_TaskId := :Id;

  BEGIN
  
    --RECORD TASK HISTORY
    v_res := f_DCM_createTaskHistory (IsSystem => 0, MessageCode => 'TaskDeleted', TaskId => v_TaskId);
    --REWRITE TASK HISTORY TO CASE HISTORY
    SELECT COL_CASETASK, COL_NAME
      INTO v_CaseId, v_TaskName
    FROM tbl_task
      WHERE col_id = v_TaskId;

    v_strToReplace := 'Task <b>' || v_TaskName || '</b> (ID: <b>' || TO_CHAR(v_TaskId) || '</b>)';

    UPDATE tbl_history SET
      COL_HISTORYCASE = v_CaseId,
      COL_DESCRIPTION = Replace(COL_DESCRIPTION, 'Task', v_strToReplace)
    WHERE col_historytask = v_TaskId;

    -- TASK EVENT QUEUE ELEMENTS RELATED TO TASKS IN CASE
    DELETE FROM (SELECT * FROM tbl_taskeventqueue WHERE col_taskeventqueuetask = v_TaskId);
  
    -- TASK EVENT QUEUE ELEMENTS RELATED TO TASK STATE INIT
    DELETE FROM (SELECT *
                   FROM tbl_taskeventqueue
                  WHERE col_taskeventqueuetaskevent IN
                        (SELECT col_id
                           FROM tbl_taskevent
                          WHERE col_taskeventtaskstateinit IN
                                (SELECT col_id
                                   FROM tbl_map_taskstateinitiation
                                  WHERE col_map_taskstateinittask = v_TaskId)));
  
    -- AUTO RULE PARAMETERS RELATED TO AUTOMATIC TASKS
    DELETE FROM (SELECT * FROM tbl_autoruleparameter WHERE col_autoruleparametertask = v_TaskId);
  
    -- AUTO RULE PARAMETERS RELATED TO TASK STATE INITIATION
    DELETE FROM (SELECT *
                   FROM tbl_autoruleparameter
                  WHERE col_ruleparam_taskstateinit IN
                        (SELECT col_id
                           FROM tbl_map_taskstateinitiation
                          WHERE col_map_taskstateinittask = v_TaskId));
  
    -- AUTO RULE PARAMETERS RELATED TO TASK DEPENDENCY
    DELETE FROM (SELECT *
                   FROM tbl_autoruleparameter
                  WHERE col_autoruleparamtaskdep IN
                        (SELECT col_id
                           FROM tbl_taskdependency
                          WHERE col_tskdpndchldtskstateinit IN
                                (SELECT col_id
                                   FROM tbl_map_taskstateinitiation
                                  WHERE col_map_taskstateinittask = v_TaskId)
                            AND col_tskdpndprnttskstateinit IN
                                (SELECT col_id
                                   FROM tbl_map_taskstateinitiation
                                  WHERE col_map_taskstateinittask = v_TaskId)));
  
    -- AUTO RULE PARAMETERS RELATED TO TASK EVENTS
    DELETE FROM (SELECT *
                   FROM tbl_autoruleparameter
                  WHERE col_taskeventautoruleparam IN
                        (SELECT col_id
                           FROM tbl_taskevent
                          WHERE col_taskeventtaskstateinit IN
                                (SELECT col_id
                                   FROM tbl_map_taskstateinitiation
                                  WHERE col_map_taskstateinittask = v_TaskId)));
  
    -- TASK EVENTS
    DELETE FROM (SELECT *
                   FROM tbl_taskevent
                  WHERE col_taskeventtaskstateinit IN
                        (SELECT col_id
                           FROM tbl_map_taskstateinitiation
                          WHERE col_map_taskstateinittask = v_TaskId));
  
    -- TASK DEPENDENCIES
    DELETE FROM (SELECT *
                   FROM tbl_taskdependency
                  WHERE col_tskdpndchldtskstateinit IN
                        (SELECT col_id
                           FROM tbl_map_taskstateinitiation
                          WHERE col_map_taskstateinittask = v_TaskId)
                    AND col_tskdpndprnttskstateinit IN
                        (SELECT col_id
                           FROM tbl_map_taskstateinitiation
                          WHERE col_map_taskstateinittask = v_TaskId));
  
    -- TASK STATE INITIATION
    DELETE FROM (SELECT *
                   FROM tbl_map_taskstateinitiation
                  WHERE col_map_taskstateinittask = v_TaskId);
  
    -- SLA ACTIONS
    DELETE FROM (SELECT *
                   FROM tbl_slaaction
                  WHERE col_slaactionslaevent IN
                        (SELECT col_id FROM tbl_slaevent WHERE col_slaeventtask = v_TaskId));
  
    -- SLA EVENTS FOR TASKS IN CASE
    DELETE FROM (SELECT * FROM tbl_slaevent WHERE col_slaeventtask = v_TaskId);
  
--    -- CASE TASKS HISTORY
--    DELETE FROM (SELECT * FROM tbl_history WHERE col_historytask = v_TaskId);
  
    -- DATE EVENTS FOT TASKS
    DELETE FROM (SELECT * FROM tbl_dateevent WHERE col_dateeventtask = v_TaskId);
  
    -- WORKITEMS
    DELETE FROM (SELECT * FROM tbl_tw_workitem WHERE col_id IN (SELECT col_tw_workitemtask FROM tbl_task WHERE col_id = v_TaskId));
  
    -- TASKEXT
    DELETE FROM (SELECT * FROM tbl_taskext WHERE col_taskexttask = v_TaskId);
  
    -- TASK DOCUMENTS
    v_res := f_doc_destroydocumentfn(case_id                 => NULL,
                                     casetype_id             => NULL,
                                     caseworker_id           => NULL,
                                     errorcode               => v_errorCode,
                                     errormessage            => v_errorMessage,
                                     extparty_id             => NULL,
                                     ids                     => NULL,
                                     task_id                 => v_TaskId,
                                     team_id                 => NULL,
                                     token_domain            => v_domain,
                                     token_useraccesssubject => v_createdBy);

    -- TASKS
    DELETE FROM (SELECT * FROM tbl_task WHERE col_id = v_TaskId);
  
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