DECLARE 
    v_caseid        INTEGER; 
    v_messagecode   NVARCHAR2(255); 
    v_result        NCLOB; 
    v_name          NVARCHAR2(255); 
    v_issystem      NUMBER; 
    v_prevcasestate INTEGER; 
    v_nextcasestate INTEGER; 
    v_result2       NUMBER; 
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
        SELECT cwi.col_cw_workitemccprevcasest, 
               cwi.col_cw_workitemccdict_casest 
        INTO   v_prevcasestate, v_nextcasestate 
        FROM   tbl_cw_workitemcc cwi 
               inner join tbl_casecc cse ON cwi.col_id = cse.col_cw_workitemcccasecc 
        WHERE  cse.col_id = v_caseid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_prevcasestate := NULL; 
          v_nextcasestate := NULL; 
    END; 

    v_result2 := F_dcm_fwrdhistorycc(); 

    INSERT INTO tbl_historycc 
                (col_historycccasecc, 
                 col_createdbyname, 
                 col_description, 
                 col_activitytimedate, 
                 col_issystem, 
                 col_historyccprevcasestate, 
                 col_historyccnextcasestate,
				 COL_MESSAGETYPEHISTORYCC,
				 col_historyCreatedBy) 
    VALUES     (v_caseid, 
                v_name, 
                v_result, 
                SYSTIMESTAMP, 
                v_issystem, 
                v_prevcasestate, 
                v_nextcasestate,
				v_messagetype,
				Sys_context('CLIENTCONTEXT', 'AccessSubject')); 
END; 