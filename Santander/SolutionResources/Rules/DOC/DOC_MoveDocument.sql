DECLARE
  v_SourceRecId NUMBER;
  v_TargetRecId NUMBER;

  v_srcid       NUMBER;
  v_srcIsFolder NUMBER;
  v_srcname     NVARCHAR2(255);
  v_srcrecid    NVARCHAR2(255);
  v_srcrecorder NUMBER;
  v_srcparentid NUMBER;

  v_trgid       NUMBER;
  v_trgname     NVARCHAR2(255);
  v_trgrecid    NVARCHAR2(255);
  v_trgrecorder NUMBER;
  v_trgparentid NUMBER;

  v_Position NVARCHAR2(32);

  v_NewParentId NUMBER;
  v_NewRecOrder NUMBER;

  --default
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  --default 
  v_errorcode      := 0;
  v_errormessage   := '';
  :SuccessResponse := 'Folder was moved';

  v_SourceRecId := :SourceRecId;
  v_TargetRecId := :TargetRecId;
  v_Position    := :Position; --"before", "after" or "append"

  BEGIN
    --get source folder
    BEGIN
      SELECT id, NAME, folderorder, calcparentid, isfolder
        INTO v_srcid, v_srcname, v_srcrecorder, v_srcparentid, v_srcIsFolder
        FROM vw_doc_documents
       WHERE id = v_SourceRecId
         AND (:CaseType_Id IS NULL OR casetypeid = :CaseType_Id)
         AND (:Case_Id IS NULL OR (caseid = :Case_Id OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = :Case_Id)))
         AND (:Task_Id IS NULL OR taskid = :Task_Id)
         AND (:ExtParty_Id IS NULL OR extpartyid = :ExtParty_Id)
         AND (:Team_Id IS NULL OR teamid = :Team_Id)
         AND (:CaseWorker_Id IS NULL OR caseworkerid = :CaseWorker_Id)
         AND (:IsGlobalResource IS NULL OR NVL(IsGlobalResource,0) = :IsGlobalResource);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorcode      := 101;
        v_errormessage   := 'Folder with source id ' || to_char(v_SourceRecId) || ' is not found: operation is not allowed';
        :SuccessResponse := '';
        GOTO cleanup;
    END;
  
    --get target folder
    BEGIN
      SELECT id, NAME, folderorder, calcparentid
        INTO v_trgid, v_trgname, v_trgrecorder, v_trgparentid
        FROM vw_doc_documents
       WHERE id = v_TargetRecId
         AND (:CaseType_Id IS NULL OR casetypeid = :CaseType_Id)
         AND (:Case_Id IS NULL OR (caseid = :Case_Id OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = :Case_Id)))
         AND (:Task_Id IS NULL OR taskid = :Task_Id)
         AND (:ExtParty_Id IS NULL OR extpartyid = :ExtParty_Id)
         AND (:Team_Id IS NULL OR teamid = :Team_Id)
         AND (:CaseWorker_Id IS NULL OR caseworkerid = :CaseWorker_Id)
         AND (:IsGlobalResource IS NULL OR NVL(IsGlobalResource,0) = :IsGlobalResource);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorcode      := 101;
        v_errormessage   := 'Folder with target id ' || to_char(v_TargetRecId) || ' is not found: operation is not allowed';
        :SuccessResponse := '';
        GOTO cleanup;
    END;
  
    IF v_srcIsFolder = 0 THEN
      UPDATE tbl_doc_document SET col_parentid = v_TargetRecId WHERE col_id = v_SourceRecId;
      :SuccessResponse := 'Document was moved to the folder ' || v_trgname;
      GOTO cleanup;
    END IF;
  
    v_NewParentId := v_trgparentid;
    v_NewRecOrder := v_trgrecorder;
  
    --move records by algorithm
    IF (v_Position = 'append') THEN
    
      v_NewParentId := v_TargetRecId;
    
      SELECT NVL(MAX(folderorder), 0) + 1
        INTO v_NewRecOrder
        FROM vw_doc_documents
       WHERE isfolder = 1
         AND calcparentid = v_TargetRecId
         AND (:CaseType_Id IS NULL OR casetypeid = :CaseType_Id)
         AND (:Case_Id IS NULL OR (caseid = :Case_Id OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = :Case_Id)))
         AND (:Task_Id IS NULL OR taskid = :Task_Id)
         AND (:ExtParty_Id IS NULL OR extpartyid = :ExtParty_Id)
         AND (:Team_Id IS NULL OR teamid = :Team_Id)
         AND (:CaseWorker_Id IS NULL OR caseworkerid = :CaseWorker_Id)
         AND (:IsGlobalResource IS NULL OR NVL(IsGlobalResource,0) = :IsGlobalResource);
    
    ELSIF (v_Position = 'after') THEN
    
      v_NewRecOrder := v_trgrecorder + 1;
    
      FOR i IN (SELECT id
                  FROM vw_doc_documents
                 WHERE isfolder = 1
                   AND folderorder >= v_NewRecOrder
                   AND calcparentid = v_trgparentid
                   AND (:CaseType_Id IS NULL OR casetypeid = :CaseType_Id)
                   AND (:Case_Id IS NULL OR
                       (caseid = :Case_Id OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = :Case_Id)))
                   AND (:Task_Id IS NULL OR taskid = :Task_Id)
                   AND (:ExtParty_Id IS NULL OR extpartyid = :ExtParty_Id)
                   AND (:Team_Id IS NULL OR teamid = :Team_Id)
                   AND (:CaseWorker_Id IS NULL OR caseworkerid = :CaseWorker_Id)
                   AND (:IsGlobalResource IS NULL OR NVL(IsGlobalResource,0) = :IsGlobalResource)) LOOP
      
        UPDATE tbl_doc_document SET col_folderorder = col_folderorder + 1 WHERE col_id = i.id;
      END LOOP;
    
    ELSIF (v_Position = 'before') THEN
    
      v_NewRecOrder := v_trgrecorder;
    
      FOR i IN (SELECT id
                  FROM vw_doc_documents
                 WHERE isfolder = 1
                   AND folderorder >= v_NewRecOrder
                   AND calcparentid = v_trgparentid
                   AND (:CaseType_Id IS NULL OR casetypeid = :CaseType_Id)
                   AND (:Case_Id IS NULL OR
                       (caseid = :Case_Id OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = :Case_Id)))
                   AND (:Task_Id IS NULL OR taskid = :Task_Id)
                   AND (:ExtParty_Id IS NULL OR extpartyid = :ExtParty_Id)
                   AND (:Team_Id IS NULL OR teamid = :Team_Id)
                   AND (:CaseWorker_Id IS NULL OR caseworkerid = :CaseWorker_Id)
                   AND (:IsGlobalResource IS NULL OR NVL(IsGlobalResource,0) = :IsGlobalResource)) LOOP
      
        UPDATE tbl_doc_document SET col_folderorder = col_folderorder + 1 WHERE col_id = i.id;
      END LOOP;
    
    END IF;
  
    UPDATE tbl_doc_document SET col_folderorder = v_NewRecOrder/*, col_parentid = v_NewParentId*/ WHERE col_id = v_SourceRecId;
  
    FOR i IN (SELECT id, rownum rn
                FROM (SELECT id, folderorder
                        FROM vw_doc_documents
                       WHERE isfolder = 1
                         AND calcparentid = v_trgparentid
                         AND (:CaseType_Id IS NULL OR casetypeid = :CaseType_Id)
                         AND (:Case_Id IS NULL OR
                             (caseid = :Case_Id OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = :Case_Id)))
                         AND (:Task_Id IS NULL OR taskid = :Task_Id)
                         AND (:ExtParty_Id IS NULL OR extpartyid = :ExtParty_Id)
                         AND (:Team_Id IS NULL OR teamid = :Team_Id)
                         AND (:CaseWorker_Id IS NULL OR caseworkerid = :CaseWorker_Id)
                         AND (:IsGlobalResource IS NULL OR NVL(IsGlobalResource,0) = :IsGlobalResource)
                       ORDER BY folderorder)) LOOP
    
      UPDATE tbl_doc_document SET col_folderorder = i.rn WHERE col_id = i.id;
    
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode      := 100;
      v_errormessage   := SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;