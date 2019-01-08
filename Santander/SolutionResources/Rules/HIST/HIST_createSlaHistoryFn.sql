DECLARE
    --input
    v_slaeventid INTEGER;
    v_messagecode NVARCHAR2(255);
    v_message NCLOB;
    v_additionalinfo NCLOB;
	v_attachTargetId INTEGER;
	v_attachTargetType NVARCHAR2(255);
	
    --calculated and other
    v_messagetype INTEGER;
    v_isincache INTEGER;
    v_prevstate INTEGER;
    v_targetid INTEGER;
    v_targettype NVARCHAR2(15);
    v_result INTEGER;
    v_historyid INTEGER;
BEGIN
    --bind variables
    v_slaeventid := :SlaEventId;
    v_messagecode := Lower(:MessageCode);
    v_message := :Message;
    v_additionalinfo := :AdditionalInfo;
	v_attachTargetId := :AttachTargetId;
	v_attachTargetType := lower(:AttachTargetType);
	
    --USE PASSED IN MESSAGE OR USE MESSAGE CODE TO GENERATE A MESSAGE
	v_messagetype := 0;
    IF v_message IS NULL AND v_messagecode IS NOT NULL THEN
        BEGIN
            SELECT col_messagetypemessage
            INTO   v_messagetype
            FROM   tbl_message
            WHERE  Lower(col_code) = v_messagecode;
        
        EXCEPTION
        WHEN no_data_found THEN
            v_messagetype := NULL;
        END;
        v_message := F_hist_genmsgfromtplfn(targetid => v_slaeventid,
                                            targettype => 'slaEvent',
                                            messagecode => v_messagecode);
    ELSE
        v_message := Nvl(v_message,'==no message for history==');
    END IF;
	
    --GET INFORMATION ABOUT THE SLA EVENT
    v_result := F_dcm_getslaeventinfo(slaeventid => v_slaeventid,
                                      targetid => v_targetid,
                                      targettype => v_targettype,
                                      isincache => v_isincache);
    
	--CREATE HISTORY
    IF v_attachTargetType = 'task' THEN
        v_historyid := F_hist_createtaskhistoryfn(taskid => v_attachTargetId,
                                                  issystem => :IsSystem,
                                                  message => v_message,
                                                  messagecode => NULL,
                                                  additionalinfo => NULL,
												  MessageTypeId => v_messagetype);
    ELSIF v_attachTargetType = 'case' THEN
        v_historyid := F_hist_createcasehistoryfn(caseid => v_attachTargetId,
                                                  issystem => :IsSystem,
                                                  message => v_message,
                                                  messagecode => NULL,
                                                  additionalinfo => NULL,
												  MessageTypeId => v_messagetype);
    END IF;
	
	--RETURN HISTORY ID
    RETURN NVL(v_historyid, 0);
END;