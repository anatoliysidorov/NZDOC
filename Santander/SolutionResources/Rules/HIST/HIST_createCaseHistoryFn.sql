DECLARE
    --input
    v_caseid INTEGER;
    v_messagecode NVARCHAR2(255);
    v_message NCLOB;
    v_additionalinfo NCLOB;
    v_issystem NUMBER;
    v_MessageTypeId INTEGER; --used to override the message template's type if needed	
    --calculated and other
    v_result NCLOB;
    v_prevstate INTEGER;
    v_nextstate INTEGER;
    v_historyid INTEGER;
    v_isincache INTEGER;
    v_CSisInCache INTEGER;
	v_ignore INTEGER;
    
BEGIN
    --bind variables
    v_caseid := :CaseId;
    v_messagecode := Lower(:MessageCode);
    v_message := :Message;
    v_issystem := :IsSystem;
    v_additionalinfo := :AdditionalInfo;
    v_MessageTypeId := :MessageTypeId;
    v_isincache := F_dcm_iscaseincache(v_caseid);
    v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache
	
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
        v_result := F_hist_genmsgfromtplfn(targetid => v_caseid,
                                           targettype => 'case',
                                           messagecode => v_messagecode);
    ELSE
        v_result := Nvl(v_message,'==no message for history==');
    END IF;

    --CASE IS IN old CACHE
    IF v_isincache = 1 THEN	
        v_ignore := F_dcm_fwrdhistorycc();
        BEGIN
            SELECT     wi.COL_CW_WORKITEMCCPREVCASEST,
                       wi.COL_CW_WORKITEMCCDICT_CASEST
            INTO       v_prevstate,
                       v_nextstate
            FROM       tbl_cw_workitemcc wi
            inner join tbl_casecc rec ON wi.col_id = rec.COL_CW_WORKITEMCCCASECC
            WHERE      rec.col_id = v_caseid;
        
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
                            col_messagetypehistoryCC,
                            col_historycreatedby,
                            --task specific--
                            COL_HISTORYCCCASECC,
                            COL_HISTORYCCPREVCASESTATE,
                            COL_HISTORYCCNEXTCASESTATE)
                  VALUES(F_getnamefromaccesssubject(Sys_context('CLIENTCONTEXT','AccessSubject')),
                            v_result,
                            v_additionalinfo,
                            SYSTIMESTAMP,
                            v_issystem,
                            v_MessageTypeId,
                            Sys_context('CLIENTCONTEXT','AccessSubject'),
                            --task specific--
                            v_caseid,
                            v_prevstate,
                            v_nextstate)
        returning col_id
        INTO      v_historyid;    
    END IF;


    --case in new cache 
    IF v_CSisInCache=1 THEN	 
        BEGIN
            SELECT     wi.COL_CW_WORKITEMPREVCASESTATE,
                       wi.COL_CW_WORKITEMDICT_CASESTATE
            INTO       v_prevstate,
                       v_nextstate
            FROM       TBL_CSCW_WORKITEM wi
            inner join TBL_CSCASE rec ON wi.col_id = rec.COL_CW_WORKITEMCASE
            WHERE      rec.col_id = v_caseid;
        
        EXCEPTION
        WHEN OTHERS THEN
            v_prevstate := NULL;
            v_nextstate := NULL;
        END;

        SELECT gen_tbl_History.nextval INTO v_historyid FROM dual;

        INSERT INTO TBL_CSHISTORY(COL_ID,
                            col_createdbyname,
                            col_description,
                            col_additionalinfo,
                            col_activitytimedate,
                            col_issystem,
                            col_messagetypehistory,
                            col_historycreatedby,
                            --case specific--
                            COL_HISTORYCASE,
                            COL_HISTORYPREVCASESTATE,
                            COL_HISTORYNEXTCASESTATE)
                  VALUES(v_historyid,
                         F_getnamefromaccesssubject(Sys_context('CLIENTCONTEXT','AccessSubject')),
                         v_result,
                         v_additionalinfo,
                         SYSTIMESTAMP,
                         v_issystem,
                         v_MessageTypeId,
                         Sys_context('CLIENTCONTEXT','AccessSubject'),
                         --case specific--
                         v_caseid,
                         v_prevstate,
                         v_nextstate);
    END IF;


    --case not in cache
    IF (v_isincache = 0) AND (v_CSisInCache=0) THEN	
        BEGIN
            SELECT     wi.COL_CW_WORKITEMPREVCASESTATE,
                       wi.COL_CW_WORKITEMDICT_CASESTATE
            INTO       v_prevstate,
                       v_nextstate
            FROM       tbl_cw_workitem wi
            inner join tbl_case rec ON wi.col_id = rec.COL_CW_WORKITEMCASE
            WHERE      rec.col_id = v_caseid;
        
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
                            --case specific--
                            COL_HISTORYCASE,
                            COL_HISTORYPREVCASESTATE,
                            COL_HISTORYNEXTCASESTATE)
                  VALUES(F_getnamefromaccesssubject(Sys_context('CLIENTCONTEXT','AccessSubject')),
                            v_result,
                            v_additionalinfo,
                            SYSTIMESTAMP,
                            v_issystem,
                            v_MessageTypeId,
                            Sys_context('CLIENTCONTEXT','AccessSubject'),
                            --case specific--
                            v_caseid,
                            v_prevstate,
                            v_nextstate)
        returning col_id
        INTO      v_historyid;    
    END IF;

    RETURN v_historyid;
END;