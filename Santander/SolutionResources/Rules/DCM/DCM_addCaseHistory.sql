DECLARE 
    v_caseid        INTEGER; 
    v_messagecode   NVARCHAR2(255); 
    v_result        NCLOB; 
    v_name          NVARCHAR2(255); 
    v_issystem      NUMBER; 
    v_prevcasestate INTEGER; 
    v_nextcasestate INTEGER; 
	v_messagetype   INTEGER; 
BEGIN 
    v_caseid := :CaseId; 
    v_messagecode := lower(:MessageCode); 
    v_issystem := :IsSystem; 
    v_result := f_HIST_genMsgFromTplFn(TargetType=>'case', TargetId=>v_caseid, MessageCode=> v_messagecode)	; 
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
        SELECT cwi.col_cw_workitemprevcasestate, 
               cwi.col_cw_workitemdict_casestate 
        INTO   v_prevcasestate, v_nextcasestate 
        FROM   tbl_cw_workitem cwi 
               inner join tbl_case cse 
                       ON cwi.col_id = cse.col_cw_workitemcase 
        WHERE  cse.col_id = v_caseid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_prevcasestate := NULL; 
          v_nextcasestate := NULL; 
    END; 

    INSERT INTO tbl_history 
                (col_historycase, 
                 col_createdbyname, 
                 col_description, 
                 col_activitytimedate, 
                 col_issystem, 
                 col_historyprevcasestate, 
                 col_historynextcasestate,
				 COL_MESSAGETYPEHISTORY,
				 col_historyCreatedBy
				 ) 
    VALUES     (v_caseid, 
                v_name, 
                v_result, 
                SYSDATE,  
                v_issystem, 
                v_prevcasestate, 
                v_nextcasestate,
				v_messagetype,
				Sys_context('CLIENTCONTEXT', 'AccessSubject')); 
				
	
END; 