DECLARE 
    v_taskid        INTEGER; 
    v_messagecode   NVARCHAR2(255); 
    v_result        NCLOB; 
    v_name          NVARCHAR2(255); 
    v_issystem      NUMBER; 
    v_prevtaskstate INTEGER; 
    v_nexttaskstate INTEGER; 
    v_result2       NUMBER; 
	v_messagetype   INTEGER; 
BEGIN 
    v_taskid := :TaskId; 
    v_messagecode := lower(:MessageCode);
    v_issystem := :IsSystem; 
    v_result := f_HIST_genMsgFromTplFn(TargetType=>'task', TargetId=>v_TaskId, MessageCode=> v_MessageCode); 
	v_name := f_getNameFromAccessSubject(Sys_context('CLIENTCONTEXT', 'AccessSubject'));

    BEGIN 
        SELECT COL_MESSAGETYPEMESSAGE
        INTO   v_messagetype
        FROM   tbl_message
        WHERE  lower(col_code) = v_messagecode; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_messagetype := NULL;
    END;

    BEGIN 
        SELECT twi.col_tw_workitemccprevtaskst, 
               twi.col_tw_workitemccdict_taskst 
        INTO   v_prevtaskstate, v_nexttaskstate 
        FROM   tbl_tw_workitemcc twi 
               inner join tbl_taskcc tsk 
                       ON twi.col_id = tsk.col_tw_workitemcctaskcc 
        WHERE  tsk.col_id = v_taskid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_prevtaskstate := NULL; 

          v_nexttaskstate := NULL; 
    END; 

    v_result2 := F_dcm_fwrdhistorycc(); 

    INSERT INTO tbl_historycc 
                (col_historycctaskcc, 
                 col_createdbyname, 
                 col_description, 
                 col_activitytimedate, 
                 col_issystem, 
                 col_historyccprevtaskstate, 
                 col_historyccnexttaskstate,
				 COL_MESSAGETYPEHISTORYCC,
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
END;