DECLARE
    --input
    v_taskid INTEGER;
    v_messagecode NVARCHAR2(255);
    v_message NCLOB;
    v_additionalinfo NCLOB;
    v_issystem INTEGER;
    v_MessageTypeId INTEGER; --used to override the message template's type if needed
    --calculated and other
    v_result NCLOB;
    v_prevstate INTEGER;
    v_nextstate INTEGER;
    v_historyid INTEGER;
    v_isincache INTEGER;
	v_ignore INTEGER;
BEGIN
    --bind variables
    v_taskid := :TaskId;
    v_messagecode := Lower(:MessageCode);
    v_message := :Message;
    v_issystem := :IsSystem;
    v_additionalinfo := :AdditionalInfo;
    v_MessageTypeId := :MessageTypeId;
    v_isincache := F_dcm_istaskincache(v_taskid);
	
    --GET MESSAGE TYPE CODE
    IF NVL(v_MessageTypeId,0) = 0 THEN
        BEGIN
            SELECT col_messagetypemessage
            INTO   v_MessageTypeId
            FROM   tbl_message
            WHERE  Lower(col_code) = v_messagecode;
        
        EXCEPTION
        WHEN no_data_found THEN
            v_MessageTypeId := NULL;
        END;
    END IF;
	
    --USE PASSED IN MESSAGE OR USE MESSAGE CODE TO GENERATE A MESSAGE
    IF v_message IS NULL AND v_messagecode IS NOT NULL THEN
        v_result := F_hist_genmsgfromtplfn(targetid => v_taskid,
                                           targettype => 'task',
                                           messagecode => v_messagecode);
    ELSE
        v_result := Nvl(v_message,'==no message for history==');
    END IF;
    IF v_isincache = 1 THEN
		v_ignore := F_dcm_fwrdhistorycc();
        --TASK IS IN CACHE
        BEGIN
            SELECT     wi.col_tw_workitemccprevtaskst,
                       wi.col_tw_workitemccdict_taskst
            INTO       v_prevstate,
                       v_nextstate
            FROM       tbl_tw_workitemcc wi
            inner join tbl_taskcc rec ON wi.col_id = rec.col_tw_workitemcctaskcc
            WHERE      rec.col_id = v_taskid;
        
        EXCEPTION
        WHEN OTHERS THEN
            v_prevstate := NULL;
            v_nextstate := NULL;
        END;
        INSERT INTO tbl_historycc(col_createdbyname,
                            col_description,
                            col_additionalinfo,
                            col_activitytimedate,
                            col_issystem,
                            col_messagetypehistorycc,
                            col_historycreatedby,
                            --task specific--
                            col_historycctaskcc,
                            col_historyccprevtaskstate,
                            col_historyccnexttaskstate)
                  VALUES(F_getnamefromaccesssubject(Sys_context('CLIENTCONTEXT','AccessSubject')),
                            v_result,
                            v_additionalinfo,
                            SYSTIMESTAMP,
                            v_issystem,
                            v_MessageTypeId,
                            Sys_context('CLIENTCONTEXT','AccessSubject'),
                            --task specific--
                            v_taskid,
                            v_prevstate,
                            v_nextstate)
        returning col_id
        INTO      v_historyid;
    
    ELSE
        BEGIN
            SELECT     wi.col_tw_workitemprevtaskstate,
                       wi.col_tw_workitemdict_taskstate
            INTO       v_prevstate,
                       v_nextstate
            FROM       tbl_tw_workitem wi
            inner join tbl_task rec ON wi.col_id = rec.col_tw_workitemtask
            WHERE      rec.col_id = v_taskid;
        
        EXCEPTION
        WHEN OTHERS THEN
            v_prevstate := NULL;
            v_nextstate := NULL;
        END;
        INSERT INTO tbl_history(col_createdbyname,
                            col_description,
                            col_additionalinfo,
                            col_activitytimedate,
                            col_issystem,
                            col_messagetypehistory,
                            col_historycreatedby,
                            --task specific--
                            col_historytask,
                            col_historyprevtaskstate,
                            col_historynexttaskstate)
                  VALUES(F_getnamefromaccesssubject(Sys_context('CLIENTCONTEXT','AccessSubject')),
                            v_result,
                            v_additionalinfo,
                            SYSTIMESTAMP,
                            v_issystem,
                            v_MessageTypeId,
                            Sys_context('CLIENTCONTEXT','AccessSubject'),
                            --task specific--
                            v_taskid,
                            v_prevstate,
                            v_nextstate)
        returning col_id
        INTO      v_historyid;
    
    END IF;
    RETURN v_historyid;
END;