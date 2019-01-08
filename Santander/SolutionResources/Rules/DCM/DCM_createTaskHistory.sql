DECLARE 
  v_taskid        INTEGER; 
  v_messagecode   NVARCHAR2(255); 
  v_result        NCLOB; 
  v_name          NVARCHAR2(255); 
  v_issystem      NUMBER; 
  v_prevtaskstate INTEGER; 
  v_nexttaskstate INTEGER; 
  v_messagetype   INTEGER; 
  v_CSisInCache   INTEGER;
  v_historyid     INTEGER;

BEGIN 
  v_taskid := :TaskId; 
  v_messagecode := Lower(:MessageCode); 
  v_issystem := :IsSystem; 

  v_CSisInCache := f_DCM_CSisTaskInCache(v_taskid);--new cache
  v_result := f_HIST_genMsgFromTplFn(TargetType=>'task', TargetId=>v_TaskId, MessageCode=> v_MessageCode); 
  v_name := F_getnamefromaccesssubject(Sys_context('CLIENTCONTEXT', 'AccessSubject')); 

  BEGIN 
      SELECT col_messagetypemessage 
      INTO   v_messagetype 
      FROM   tbl_message 
      WHERE  Lower(col_code) = v_messagecode; 
  EXCEPTION 
      WHEN no_data_found THEN 
        v_messagetype := NULL; 
  END; 


  --not in new cache 
  IF v_CSisInCache=0 THEN	 
  BEGIN 
      SELECT twi.col_tw_workitemprevtaskstate, 
             twi.col_tw_workitemdict_taskstate 
      INTO   v_prevtaskstate, v_nexttaskstate 
      FROM   tbl_tw_workitem twi 
             inner join tbl_task tsk 
                     ON twi.col_id = tsk.col_tw_workitemtask 
      WHERE  tsk.col_id = v_taskid; 
  EXCEPTION 
      WHEN no_data_found THEN 
        v_prevtaskstate := NULL; 
        v_nexttaskstate := NULL; 
  END; 

  INSERT INTO tbl_history 
              (col_historytask, 
               col_createdbyname, 
               col_description, 
               col_activitytimedate, 
               col_issystem, 
               col_historyprevtaskstate, 
               col_historynexttaskstate, 
               col_messagetypehistory,
		 col_historyCreatedBy) 
  VALUES      (v_taskid, 
               v_name, 
               v_result, 
               SYSTIMESTAMP, 
               v_issystem, 
               v_prevtaskstate, 
               v_nexttaskstate, 
               v_messagetype,
		 Sys_context('CLIENTCONTEXT', 'AccessSubject')); 
  END IF;


  --in new cache 
  IF v_CSisInCache=1 THEN	 
  BEGIN 
      SELECT TWI.COL_TW_WORKITEMPREVTASKSTATE, 
             TWI.COL_TW_WORKITEMDICT_TASKSTATE 
      INTO   v_prevtaskstate, v_nexttaskstate 
      FROM   TBL_CSTW_WORKITEM twi 
      INNER JOIN TBL_CSTASK tsk  ON twi.col_id = tsk.col_tw_workitemtask 
      WHERE  tsk.col_id = v_taskid; 
  EXCEPTION 
      WHEN no_data_found THEN 
        v_prevtaskstate := NULL; 
        v_nexttaskstate := NULL; 
  END; 

  SELECT gen_tbl_History.nextval INTO v_historyid FROM dual;

  INSERT INTO TBL_CSHISTORY 
              (COL_ID, 
              col_historytask, 
               col_createdbyname, 
               col_description, 
               col_activitytimedate, 
               col_issystem, 
               col_historyprevtaskstate, 
               col_historynexttaskstate, 
               col_messagetypehistory,
		           col_historyCreatedBy) 
  VALUES      (v_historyid,
               v_taskid, 
               v_name, 
               v_result, 
               SYSTIMESTAMP, 
               v_issystem, 
               v_prevtaskstate, 
               v_nexttaskstate, 
               v_messagetype,
		           SYS_CONTEXT('CLIENTCONTEXT', 'AccessSubject')); 
  END IF;


END; 