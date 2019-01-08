DECLARE
    --input
    v_StateSLAActionId INTEGER;
	v_StateSLAEventId INTEGER;
    v_messagecode NVARCHAR2(255);
    v_message NCLOB;
	v_attachTargetId INTEGER;
	v_attachTargetType NVARCHAR2(255);
	
    --calculated and other
    v_isInCache INTEGER;
    v_messagetype INTEGER;
    v_targetid INTEGER;
    v_targettype NVARCHAR2(15);
    v_result INTEGER;
    v_historyid INTEGER;
BEGIN
    --bind variables
    v_StateSLAActionId := :StateSLAActionId;
	v_StateSLAEventId := :StateSLAEventId;
    v_messagecode := Trim(Lower(:MessageCode));
    v_message := Trim(:Message);
	v_attachTargetId := :AttachTargetId;
	v_attachTargetType := lower(:AttachTargetType);
	
	--get StateSLAEventId from StateSLAActionId if needed
	IF NVL(v_StateSLAEventId, 0) = 0 AND v_StateSLAActionId > 0 THEN
		SELECT COL_STATESLAACTNSTATESLAEVNT
		INTO v_StateSLAEventId
		FROM TBL_DICT_STATESLAACTION
		WHERE COL_ID = v_StateSLAActionId;		
	END IF;
	
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
        v_message := F_hist_genmsgfromtplfn(targetid => v_StateSLAEventId,
                                            targettype => 'slaMsEvent',
                                            messagecode => v_messagecode
                                            );
    ELSE
        v_message := Nvl(v_message,'==no message for history==');
    END IF;
	
    --GET INFORMATION ABOUT THE SLA EVENT
    v_result := F_dcm_getSlaMsEventInfo(StateSLAEventId => v_StateSLAEventId,
                                        targetid => v_targetid,
                                        targettype => v_targettype,
                                        isInCache => v_isInCache);
										
    --CREATE HISTORY
    IF Lower(v_attachTargetType) = 'case' THEN
        v_historyid := F_hist_createcasehistoryfn(caseid => v_attachTargetId,
                                                  issystem => :IsSystem,
                                                  message => v_message,
                                                  messagecode => NULL,
                                                  additionalinfo => :AdditionalInfo,
												  MessageTypeId => v_messagetype);
    ELSIF Lower(v_attachTargetType) = 'task' THEN
        v_historyid := F_hist_createtaskhistoryfn(taskid => v_attachTargetId,
                                                  issystem => :IsSystem,
                                                  message => v_message,
                                                  messagecode => NULL,
                                                  additionalinfo => :AdditionalInfo,
												  MessageTypeId => v_messagetype);
    ELSIF Lower(v_attachTargetType) = 'document' THEN
        NULL; --for future needs
    END IF;
    
    --RETURN HISTORY ID
    RETURN NVL(v_historyid,0);
	
EXCEPTION  
	WHEN OTHERS THEN 
		RETURN 0;
END;