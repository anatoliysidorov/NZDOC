    SELECT 
        note.ID AS ID,
        note.NOTE AS NOTE,
        note.NOTENAME AS NOTENAME,
        note.CREATEDBY AS CREATEDBY,
        note.CREATEDDURATION AS CREATEDDURATION,
        note.MODIFIEDDURATION AS MODIFIEDDURATION,
        note.VERSION AS VERSION,
        note.MODIFIEDBY AS MODIFIEDBY,
        note.MODIFIEDDATE AS MODIFIEDDATE,
        note.CASENOTEID AS CASENOTEID,
        note.TASKNOTEID AS TASKNOTEID,
        note.DOCUMENTNOTEID AS DOCUMENTNOTEID,
        note.EXTERNALPARTYNOTE AS EXTERNALPARTYNOTE,
        note.CASEWORKERNOTE AS CASEWORKERNOTE,
        note.CREATEDBY_NAME AS CREATEDBY_NAME,
        note.MODIFIEDBY_NAME AS MODIFIEDBY_NAME,
    
        (CASE WHEN NVL(:Task_Id,0) = 0 then 
            (SELECT dcs.col_ISFINISH FROM tbl_case cs 
            INNER JOIN tbl_cw_workitem cw ON cs.col_cw_workitemcase = cw.col_id
            INNER JOIN tbl_dict_casestate dcs ON cw.col_cw_workitemdict_casestate = dcs.col_id
            WHERE cs.col_id = note.CASENOTEID)
        ELSE    
            (SELECT dts.col_ISFINISH FROM tbl_task tsk
            INNER JOIN tbl_tw_workitem tw ON tsk.col_tw_workitemtask = tw.col_id
            INNER JOIN tbl_dict_taskstate dts ON tw.col_tw_workitemdict_taskstate = dts.col_id
            WHERE tsk.col_id = note.TASKNOTEID)
        END) AS STATE_ISFINISH
    FROM (
        select 
            tn.COL_ID AS ID,
            tn.COL_NOTE AS NOTE,
            tn.COL_NOTENAME AS NOTENAME,
            tn.COL_CREATEDBY AS CREATEDBY,
            F_UTIL_GETDRTNFRMNOW (tn.COL_CREATEDDATE) AS CREATEDDURATION,
            F_UTIL_GETDRTNFRMNOW (tn.COL_MODIFIEDDATE) AS MODIFIEDDURATION,
            tn.COL_VERSION AS VERSION,
            tn.COL_MODIFIEDBY AS MODIFIEDBY,
            tn.COL_MODIFIEDDATE AS MODIFIEDDATE,
            tn.COL_CASENOTE AS CASENOTEID,
            tn.COL_TASKNOTE AS TASKNOTEID,
            tn.COL_NOTEDOCUMENT AS DOCUMENTNOTEID,
            tn.COL_EXTERNALPARTYNOTE AS EXTERNALPARTYNOTE,
            tn.COL_NOTEPPL_CASEWORKER AS CASEWORKERNOTE,
            F_getnamefromaccesssubject(tn.COL_CREATEDBY) AS CREATEDBY_NAME,
            F_getnamefromaccesssubject(tn.COL_MODIFIEDBY) AS MODIFIEDBY_NAME
        from TBL_NOTE tn
        where (:Document_Id IS NOT NULL
        <%= IfNotNull(":Document_Id", " AND tn.COL_NOTEDOCUMENT = :Document_Id") %>  )
         or 
         (:Document_Id IS NULL
        <%= IfNotNull(":Case_Id", " AND tn.COL_CASENOTE = :Case_Id") %>
        <%= IfNotNull(":Task_Id", " AND tn.COL_TASKNOTE = :Task_Id") %>
        <%= IfNotNull(":ExternalParty_Id", " AND tn.COL_EXTERNALPARTYNOTE = :ExternalParty_Id") %>
        <%= IfNotNull(":CaseWorker_Id", " AND tn.COL_NOTEPPL_CASEWORKER = :CaseWorker_Id") %>)		 
    ) note
    <%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>