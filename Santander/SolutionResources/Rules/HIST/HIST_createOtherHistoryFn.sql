DECLARE 
    --input 
    v_messagecode    NVARCHAR2(255); 
    v_message        NCLOB; 
    v_additionalinfo NCLOB; 
    v_issystem       NUMBER; 
	
    --calculated and other        
    v_result         NCLOB; 
    v_prevstate      INTEGER; 
    v_nextstate      INTEGER; 
    v_messagetype    INTEGER; 
    v_historyid      INTEGER; 
BEGIN 
    --bind variables 
    v_messagecode := Lower(:MessageCode); 
    v_message := :Message; 
    v_issystem := :IsSystem; 
    v_additionalinfo := :AdditionalInfo; 

    --GET MESSAGE TYPE CODE AND PERSON'S NAME   
    BEGIN 
        SELECT col_messagetypemessage 
        INTO   v_messagetype 
        FROM   tbl_message 
        WHERE  Lower(col_code) = v_messagecode; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_messagetype := NULL; 
    END; 

    --USE PASSED IN MESSAGE OR USE MESSAGE CODE TO GENERATE A MESSAGE 
    IF v_message IS NULL AND v_messagecode IS NOT NULL THEN 
      v_result := F_hist_genmsgfromtplfn(targetid => NULL, targettype => NULL, messagecode => v_messagecode); 
    ELSE 
      v_result := Nvl(v_message, '==no message for history=='); 
    END IF; 

	
	INSERT INTO tbl_history(
		col_createdbyname, 
		col_description, 
		col_additionalinfo, 
		col_activitytimedate, 
		col_issystem, 
		col_messagetypehistory, 
		col_historycreatedby
	) 
	VALUES (
		F_getnamefromaccesssubject(Sys_context('CLIENTCONTEXT', 'AccessSubject') ), 
		v_result, 
		v_additionalinfo, 
		SYSTIMESTAMP, 
		v_issystem, 
		v_messagetype, 
		Sys_context('CLIENTCONTEXT', 'AccessSubject')
	) 
	returning col_id INTO v_historyid;
    RETURN v_historyid; 
END; 