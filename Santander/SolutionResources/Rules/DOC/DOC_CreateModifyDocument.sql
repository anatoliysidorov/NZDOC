DECLARE
  --custom
  v_id                   INT;
  v_col_Name             NVARCHAR2(255);
  v_NameExt              NVARCHAR2(255);
  v_DocExt               NVARCHAR2(255);
  v_col_ParentId         INT;
  v_col_isDeleted        INT;
  v_col_IsFolder         INT;
  v_col_IsGlobalResource INT;
  v_col_URL              NVARCHAR2(255);
  v_col_Description      NCLOB;
  v_col_CustomData       NCLOB;
  v_col_Doctype          INT;
  v_workedItemType       NVARCHAR2(255);
  v_parentIsDeleted      INT;
  v_folderOrder          INT;
  v_currentUrl           NVARCHAR2(255);
  v_isVersionControl     INT;
  v_versionIndex         INT;
  v_case_isfinish        INT;

  v_TargetType NVARCHAR2(20);
  v_TargetId   INT;

  --links
  v_CaseType_Id INT;
  v_Case_Id     INT;
  v_Task_Id     INT;
  v_ExtParty_Id INT;
  v_Team_Id     INT;
  v_CW_Id       INT;

  --default
  v_errorcode      INT;
  v_errormessage   NCLOB;
  v_affectedRows   INT;
  v_DenyThisParent INT;
  v_trgtParent     INT;
  v_isId           INT;
  v_useOldParent   INT;
  v_result         INT;
BEGIN
  --custom
  v_id                   := :ID;
  v_col_Name             := :NAME;
  v_NameExt              := '';
  v_col_isDeleted        := NVL(:ISDELETED, 0);
  v_col_IsFolder         := NVL(:ISFOLDER, 1);
  v_col_IsGlobalResource := NVL(:ISGLOBALRESOURCE, 0);
  v_col_ParentId         := NVL(:CALCPARENTID, -1);
  v_useOldParent         := NVL(:USEOLDPARENT, 0);
  v_col_URL              := :URL;
  v_DocExt               := '';
  v_col_Description      := :DESCRIPTION;
  v_col_Doctype          := :DOCTYPE;
  v_col_CustomData       := :CUSTOMDATA;
  :SuccessResponse       := EMPTY_CLOB();
  v_isVersionControl     := 0;
  IF v_col_CustomData IS NULL THEN
    v_col_CustomData := '<CustomData><Attributes></Attributes></CustomData>';
  END IF;
  IF v_col_IsFolder = 1 THEN
    v_workedItemType := 'folder';
  ELSE
    v_workedItemType := 'document';
  END IF;
  IF v_col_Name IS NOT NULL AND INSTR(v_col_Name, '.', -1) <> 0 THEN
    v_NameExt := (substr(v_col_Name, instr(v_col_Name, '.', -1), length(v_col_Name) - (INSTR(v_col_Name, '.', -1) - 1)));
  END IF;
  IF v_col_URL IS NOT NULL AND INSTR(v_col_URL, '.', -1) <> 0 THEN
    v_DocExt := lower(substr(v_col_URL, instr(v_col_URL, '.', -1), length(v_col_URL) - (INSTR(v_col_URL, '.', -1) - 1)));
  END IF;
  IF v_col_Name IS NOT NULL AND (v_NameExt IS NULL OR v_NameExt = '' OR v_NameExt <> v_DocExt) THEN
    v_col_Name := v_col_Name || v_DocExt;
  END IF;

  --links
  v_CaseType_Id := :CASETYPE_ID;
  v_Case_Id     := :CASE_ID;
  v_Task_Id     := :TASK_ID;
  v_ExtParty_Id := :EXTPARTY_ID;
  v_Team_Id     := :TEAM_ID;
  v_CW_Id       := :CASEWORKER_ID;

  --default
  v_affectedRows := 0;
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  -- validation on Id is Exist
  -- TBL_DOC_DOCUMENT
  IF NVL(v_id, 0) > 0 THEN
    v_TargetType := 'DOCUMENT';
    v_TargetId   := v_id;
    v_isId       := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, tablename => 'TBL_DOC_DOCUMENT');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  -- CASETYPE_ID
  IF NVL(v_CaseType_Id, 0) > 0 THEN
    v_TargetType := 'CASETYPE';
    v_TargetId   := v_CaseType_Id;
    v_isId       := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_CaseType_Id, tablename => 'TBL_DICT_CASESYSTYPE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  -- CASE_ID
  IF NVL(v_Case_Id, 0) > 0 THEN
    v_TargetType := 'CASE';
    v_TargetId   := v_Case_Id;
    v_isId       := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_Case_Id, tablename => 'TBL_CASE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  
    -- Validate on IsFinished state for Case
    IF NVL(v_Task_Id, 0) = 0 THEN
      v_result := f_doc_checkstateobjectfn(case_id => v_Case_Id, errorcode => v_errorcode, errormessage => v_errormessage, id => NULL, task_id => NULL);
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  END IF;

  -- TASK_ID
  IF NVL(v_Task_Id, 0) > 0 THEN
    v_TargetType := 'TASK';
    v_TargetId   := v_Task_Id;
    v_isId       := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_Task_Id, tablename => 'TBL_TASK');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  
    -- Validate on IsFinished state for Task
    v_result := f_doc_checkstateobjectfn(case_id => NULL, errorcode => v_errorcode, errormessage => v_errormessage, id => NULL, task_id => v_Task_Id);
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  -- EXTPARTY_ID
  IF NVL(v_ExtParty_Id, 0) > 0 THEN
    v_TargetType := 'EXTERNALPARTY';
    v_TargetId   := v_ExtParty_Id;
    v_isId       := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_ExtParty_Id, tablename => 'TBL_EXTERNALPARTY');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  -- TEAM_ID
  IF NVL(v_Team_Id, 0) > 0 THEN
    v_TargetType := 'TEAM';
    v_TargetId   := v_Team_Id;
    v_isId       := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_Team_Id, tablename => 'TBL_PPL_TEAM');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  -- v_CW_Id
  IF NVL(v_CW_Id, 0) > 0 THEN
    v_TargetType := 'CASEWORKER';
    v_TargetId   := v_CW_Id;
    v_isId       := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_CW_Id, tablename => 'TBL_PPL_CASEWORKER');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  --validation
  IF v_col_IsFolder = 0 AND v_col_URL IS NULL THEN
    v_errorCode    := 101;
    v_errorMessage := 'Please upload document before save';
    GOTO cleanup;
  END IF;
  IF v_col_ParentId = v_id THEN
    v_errorCode    := 107;
    v_errorMessage := 'Please select another folder as parent';
    GOTO cleanup;
  END IF;
  IF v_useOldParent = 1 THEN
    BEGIN
      SELECT col_ParentId INTO v_col_ParentId FROM tbl_doc_document WHERE col_id = v_id;
    
    EXCEPTION
      WHEN no_data_found THEN
        v_errorCode    := 109;
        v_errorMessage := 'Record was not found';
        GOTO cleanup;
    END;
  END IF;
  IF v_col_IsFolder = 0 AND v_col_ParentId = -1 THEN
    v_errorCode    := 102;
    v_errorMessage := 'Can not save document to the home folder. Please select another folder for this document.';
    GOTO cleanup;
  END IF;
  IF v_useOldParent != 1 AND v_col_ParentId IS NOT NULL AND v_col_ParentId != -1 THEN
    SELECT col_isDeleted INTO v_parentIsDeleted FROM tbl_doc_Document WHERE col_id = v_col_ParentId;
  
    IF NVL(v_parentIsDeleted, 0) = 1 THEN
      v_errorCode    := 103;
      v_errorMessage := 'Parent of this {{MESS_NAME}} is disabled';
      v_result       := LOC_i18n(MessageText => v_errormessage, MessageResult => v_errormessage, MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_workedItemType)));
      GOTO cleanup;
    END IF;
  END IF;

  -- validate the doc/folder name
  v_result := f_doc_validdocnamefn(caseid           => v_Case_Id,
                                   casetypeid       => v_CaseType_Id,
                                   cwid             => v_CW_Id,
                                   docid            => v_id,
                                   errorcode        => v_errorcode,
                                   errormessage     => v_errormessage,
                                   isfolder         => v_col_IsFolder,
                                   isglobalresource => v_col_IsGlobalResource,
                                   NAME             => v_col_Name,
                                   parentid         => v_col_ParentId,
                                   partyid          => v_ExtParty_Id,
                                   taskid           => v_Task_Id,
                                   teamid           => v_Team_Id);
  IF v_errorcode <> 0 THEN
    GOTO cleanup;
  END IF;

  --set assumed success message for documents and folders
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated {{MESS_NAME}} {{MESS_ITEMTYPE}}';
  ELSE
    :SuccessResponse := 'Created {{MESS_NAME}} {{MESS_ITEMTYPE}}';
  END IF;

  --:SuccessResponse := :SuccessResponse || ' ' || v_col_Name || ' ' || v_workedItemType;
  v_result := LOC_i18n(MessageText => :SuccessResponse, MessageResult => :SuccessResponse, MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_col_Name), Key_Value('MESS_ITEMTYPE', v_workedItemType)));
  IF v_col_IsFolder = 1 AND v_id IS NULL THEN
    -- get MAX Order
    SELECT NVL(MAX(folderorder), 0)
      INTO v_folderOrder
      FROM vw_doc_documents
     WHERE isfolder = 1
       AND calcparentid = v_col_ParentId
       AND (v_CaseType_Id IS NULL OR casetypeid = v_CaseType_Id)
       AND (v_Case_Id IS NULL OR (caseid = v_Case_Id OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = v_Case_Id)))
       AND (v_Task_Id IS NULL OR taskid = v_Task_Id)
       AND (v_ExtParty_Id IS NULL OR extpartyid = v_ExtParty_Id)
       AND (v_Team_Id IS NULL OR teamid = v_Team_Id)
       AND (v_CW_Id IS NULL OR caseworkerid = v_CW_Id);
  
    v_folderOrder := v_folderOrder + 1;
  ELSIF v_col_IsFolder = 0 AND v_id IS NULL THEN
    v_folderOrder := NULL;
  END IF;
  BEGIN
    IF v_id IS NULL THEN
      IF v_col_IsFolder = 0 THEN
        v_versionIndex := 1;
      ELSE
        v_versionIndex := NULL;
      END IF;
    
      -- Insert new document
      INSERT INTO tbl_doc_Document
        (col_Name, col_folderorder, col_isDeleted, col_IsFolder, col_ParentId, col_Description, col_Doctype, col_URL, col_IsGlobalResource, col_CustomData, col_VersionIndex)
      VALUES
        (v_col_Name, v_folderOrder, v_col_isDeleted, v_col_IsFolder, v_col_ParentId, v_col_Description, v_col_Doctype, v_col_URL, v_col_IsGlobalResource, XMLTYPE(v_col_CustomData), v_versionIndex)
      RETURNING col_id INTO v_id;
    
      IF v_CaseType_Id IS NOT NULL THEN
        INSERT INTO tbl_doc_docCaseType (col_DocCseTypeDoc, col_DocCseTypeType) VALUES (v_id, v_CaseType_Id);
      
      END IF;
      IF v_Case_Id IS NOT NULL AND v_Task_Id IS NULL THEN
        INSERT INTO tbl_doc_docCase (col_DocCaseDocument, col_DocCaseCase) VALUES (v_id, v_Case_Id);
      
        IF v_col_IsFolder = 1 THEN
          v_result := f_HIST_createHistoryFn(AdditionalInfo => f_DOC_getDocumentPath(v_id), IsSystem => 0, Message => NULL, MessageCode => 'FolderCreated', TargetID => v_Case_Id, TargetType => 'CASE');
        ELSE
          v_result := f_HIST_createHistoryFn(AdditionalInfo => f_DOC_getDocumentPath(v_id), IsSystem => 0, Message => NULL, MessageCode => 'FileCreated', TargetID => v_Case_Id, TargetType => 'CASE');
        END IF;
      
      END IF;
      IF v_Task_Id IS NOT NULL THEN
        INSERT INTO tbl_doc_docTask (col_DocTaskDocument, col_DocTaskTask) VALUES (v_id, v_Task_Id);
      
        IF v_col_IsFolder = 1 THEN
          v_result := f_HIST_createHistoryFn(AdditionalInfo => f_DOC_getDocumentPath(v_id), IsSystem => 0, Message => NULL, MessageCode => 'FolderCreated', TargetID => v_Task_Id, TargetType => 'TASK');
        ELSE
          v_result := f_HIST_createHistoryFn(AdditionalInfo => f_DOC_getDocumentPath(v_id), IsSystem => 0, Message => NULL, MessageCode => 'FileCreated', TargetID => v_Task_Id, TargetType => 'TASK');
        END IF;
      
      END IF;
      IF v_ExtParty_Id IS NOT NULL THEN
        INSERT INTO tbl_doc_docExtPrt (col_docextprtdoc, col_docextprtextprt) VALUES (v_id, v_ExtParty_Id);
      
      END IF;
      IF v_Team_Id IS NOT NULL THEN
        INSERT INTO tbl_doc_docTeam (col_docteamdoc, col_docteamteam) VALUES (v_id, v_Team_Id);
      
      END IF;
      IF v_CW_Id IS NOT NULL THEN
        INSERT INTO tbl_doc_DocCW (col_doccwdoc, col_doccwcw) VALUES (v_id, v_CW_Id);
      
      END IF;
    ELSE
      -- Validate on IsFinished state for Case or Task
      v_result := f_doc_checkstateobjectfn(case_id => NULL, errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, task_id => NULL);
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    
      -- Update exist document
      --version control
      IF v_col_IsFolder = 0 THEN
        BEGIN
          SELECT col_url INTO v_currentUrl FROM tbl_doc_document WHERE col_id = v_id;
        
        EXCEPTION
          WHEN no_data_found THEN
            v_errorCode    := 108;
            v_errorMessage := 'Record was not found';
            GOTO cleanup;
        END;
        IF nvl(v_currentUrl, ' ') <> NVL(:url, ' ') THEN
          INSERT INTO tbl_doc_documentversion
            (COL_DOCVERSIONDOCID,
             COL_ISFOLDER,
             COL_PARENTID,
             COL_URL,
             COL_OWNER,
             COL_NAME,
             COL_MODIFIEDBY,
             COL_LOCKEDBY,
             COL_CREATEDBY,
             COL_MODIFIEDDATE,
             COL_LOCKEDEXPDATE,
             COL_LOCKEDDATE,
             COL_CREATEDDATE,
             COL_ISDELETED,
             COL_FOLDERORDER,
             COL_DOCTYPE,
             COL_DESCRIPTION,
             COL_ISGLOBALRESOURCE,
             COL_CUSTOMDATA,
             COL_VERSIONINDEX)
            SELECT COL_ID,
                   COL_ISFOLDER,
                   COL_PARENTID,
                   COL_URL,
                   COL_OWNER,
                   COL_NAME,
                   COL_MODIFIEDBY,
                   COL_LOCKEDBY,
                   COL_CREATEDBY,
                   COL_MODIFIEDDATE,
                   COL_LOCKEDEXPDATE,
                   COL_LOCKEDDATE,
                   COL_CREATEDDATE,
                   COL_ISDELETED,
                   COL_FOLDERORDER,
                   COL_DOCTYPE,
                   COL_DESCRIPTION,
                   COL_ISGLOBALRESOURCE,
                   COL_CUSTOMDATA,
                   NVL(COL_VERSIONINDEX, 1)
              FROM tbl_doc_document
             WHERE col_id = v_id;
        
          v_isVersionControl := 1;
        END IF;
      END IF;
      --end version control
    
      /* Search is this requested parent is children of current folder */
      IF v_col_IsFolder = 1 THEN
        BEGIN
          SELECT id
            INTO v_denyThisParent
            FROM (SELECT doc_doc.col_id       AS id,
                         doc_doc.col_parentid AS ParentId,
                         col_name             AS NAME,
                         LEVEL                AS NestingLevel
                    FROM tbl_doc_document doc_doc
                   START WITH doc_doc.col_id = v_id
                  CONNECT BY PRIOR doc_doc.col_id = doc_doc.col_parentId)
           WHERE id = v_col_ParentId;
        
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_denyThisParent := NULL;
        END;
        IF v_DenyThisParent IS NOT NULL THEN
          v_errorCode      := 106;
          v_errorMessage   := 'Denied to move parent to children folder';
          :SuccessResponse := '';
          GOTO cleanup;
        END IF;
        -- Get new FolderOrder
        SELECT calcparentid
          INTO v_trgtParent
          FROM vw_doc_documents
         WHERE isfolder = 1
           AND id = v_id
           AND (v_CaseType_Id IS NULL OR casetypeid = v_CaseType_Id)
           AND (v_Case_Id IS NULL OR (caseid = v_Case_Id OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = v_Case_Id)))
           AND (v_Task_Id IS NULL OR taskid = v_Task_Id)
           AND (v_ExtParty_Id IS NULL OR extpartyid = v_ExtParty_Id)
           AND (v_Team_Id IS NULL OR teamid = v_Team_Id)
           AND (v_CW_Id IS NULL OR caseworkerid = v_CW_Id);
      
        IF v_col_ParentId != v_trgtParent THEN
          SELECT NVL(MAX(folderorder), 0) + 1
            INTO v_folderOrder
            FROM vw_doc_documents
           WHERE isfolder = 1
             AND calcparentid = v_col_ParentId
             AND (v_CaseType_Id IS NULL OR casetypeid = v_CaseType_Id)
             AND (v_Case_Id IS NULL OR (caseid = v_Case_Id OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = v_Case_Id)))
             AND (v_Task_Id IS NULL OR taskid = v_Task_Id)
             AND (v_ExtParty_Id IS NULL OR extpartyid = v_ExtParty_Id)
             AND (v_Team_Id IS NULL OR teamid = v_Team_Id)
             AND (v_CW_Id IS NULL OR caseworkerid = v_CW_Id);
        
        END IF;
      END IF;
    
      UPDATE tbl_doc_Document
         SET col_Name             = v_col_Name,
             col_isDeleted        = v_col_isDeleted,
             col_IsFolder         = v_col_IsFolder,
             col_IsGlobalResource = v_col_IsGlobalResource,
             col_ParentId         = v_col_ParentId,
             col_Description      = v_col_Description,
             col_CustomData       = XMLTYPE(v_col_CustomData),
             col_Doctype          = v_col_Doctype,
             col_URL              = v_col_URL,
             col_folderorder      = v_folderOrder
       WHERE col_id = v_id;
    
      IF (v_isVersionControl = 1) THEN
        UPDATE tbl_doc_document SET col_versionindex = NVL(COL_VERSIONINDEX, 1) + 1 WHERE col_id = v_id;
      END IF;
    
      v_result := f_DOC_getContextFn(DocumentID => v_id, TargetID => v_TargetID, TargetType => v_TargetType);
      IF v_TargetID > 0 THEN
        IF v_col_IsFolder = 1 THEN
          v_result := f_HIST_createHistoryFn(AdditionalInfo => f_DOC_getDocumentPath(v_id),
                                             IsSystem       => 0,
                                             Message        => NULL,
                                             MessageCode    => 'FolderModified',
                                             TargetID       => v_TargetID,
                                             TargetType     => v_TargetType);
        ELSE
          v_result := f_HIST_createHistoryFn(AdditionalInfo => f_DOC_getDocumentPath(v_id),
                                             IsSystem       => 0,
                                             Message        => NULL,
                                             MessageCode    => 'FileModified',
                                             TargetID       => v_TargetID,
                                             TargetType     => v_TargetType);
        END IF;
      END IF;
    END IF;
    :affectedRows := SQL%ROWCOUNT;
    :recordId     := v_id;
    IF v_col_isDeleted = 1 THEN
      UPDATE tbl_doc_document
         SET col_isDeleted = 1
       WHERE col_id IN (SELECT doc_doc.col_id FROM tbl_doc_document doc_doc START WITH doc_doc.col_id = v_id CONNECT BY PRIOR doc_doc.col_id = doc_doc.col_parentId);
    
    END IF;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 104;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows  := 0;
      v_errorcode    := 105;
      v_errormessage := DBMS_UTILITY.format_error_backtrace;
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
