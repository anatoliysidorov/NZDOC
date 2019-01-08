DECLARE
  --INPUT  
  v_caseId        NUMBER;
  v_workitemId    NUMBER;
  v_workitemState NUMBER;
  v_isId          NUMBER;

  v_folderName  NVARCHAR2(255);
  v_folderId    NUMBER;
  v_parentId    NUMBER;
  v_folderOrder NUMBER;
  v_result      NUMBER;
  v_wi_parent   NUMBER;

  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
BEGIN

  -- Input
  v_caseId     := :CaseId;
  v_workitemId := :WorkitemId;

  v_folderName := f_dcm_getscalarsetting(defaultresult => 'Indexed', p_name => 'INDEXED_FOLDER_NAME');

  v_errorCode    := 0;
  v_errorMessage := '';

  BEGIN
    -- check on NULLs
    IF v_workitemId IS NULL OR v_caseId IS NULL THEN
      v_errorCode    := 100;
      v_errorMessage := 'WorkitemId or CaseId can not be NULL';
      GOTO cleanup;
    END IF;
  
    -- validation on Id is Exist
    IF NVL(v_workitemId, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode => v_errorCode, errormessage => v_errorMessage, id => v_workitemId, tablename => 'TBL_PI_WORKITEM');
      IF v_errorCode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
    IF NVL(v_caseId, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode => v_errorCode, errormessage => v_errorMessage, id => v_caseId, tablename => 'TBL_CASE');
      IF v_errorCode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    -- change WorkItem State to 'Reviewed'
    v_result := f_pi_setworkitemstate(actioncode => 'ATTACH_TO_CASE', errorcode => v_errorCode, errormessage => v_errorMessage, workitemid => v_workitemId);
    IF NVL(v_errorCode, 0) > 0 THEN
      GOTO cleanup;
    END IF;
  
    -- Get folderId
    -- Default Folder by Case Type
    BEGIN
      SELECT NVL(ct.col_defaultmailfolder, 0) INTO v_folderId FROM tbl_case c INNER JOIN tbl_dict_casesystype ct ON ct.col_id = c.col_casedict_casesystype WHERE c.col_id = v_CaseId;
    EXCEPTION
      WHEN no_data_found THEN
        v_folderId := 0;
    END;
  
    -- Define 'Indexed' folder
    IF v_folderId = 0 THEN
      BEGIN
        SELECT id
          INTO v_folderId
          FROM vw_doc_documents
         WHERE isfolder = 1
           AND UPPER(NAME) = UPPER(v_folderName)
           AND caseid = v_caseId;
      EXCEPTION
        WHEN no_data_found THEN
          -- Create folder for Document Indexing
          SELECT NVL(MAX(folderorder), 0) + 1
            INTO v_folderOrder
            FROM vw_doc_documents
           WHERE isfolder = 1
             AND caseid = v_caseId;
        
          INSERT INTO tbl_doc_Document
            (col_isfolder, col_parentid, col_name, col_description, col_folderorder)
          VALUES
            (1, -1, v_folderName, 'Automatically created when Document Workitem was attached', v_folderOrder)
          RETURNING col_id INTO v_folderId;
        
          -- Link Folder to Case
          INSERT INTO tbl_doc_docCase (col_DocCaseDocument, col_DocCaseCase) VALUES (v_folderId, v_caseId);
      END;
    END IF;
  
    -- Link Attachments to Folder
    UPDATE tbl_doc_Document SET col_parentid = v_folderId  WHERE col_doc_documentpi_workitem = v_workitemId;
  
    -- Link Attachments to Case
    FOR cur IN (SELECT col_id AS id FROM tbl_doc_Document WHERE col_doc_documentpi_workitem = v_workitemId) LOOP
      INSERT INTO tbl_doc_docCase (col_DocCaseDocument, col_DocCaseCase) VALUES (cur.id, v_caseId);
    END LOOP;

    -- Link email to Case
    BEGIN
      SELECT NVL(COL_PARENTWI, v_workitemId) INTO v_wi_parent
        FROM TBL_EMAIL_WORKITEM_EXT
      WHERE COL_EMAIL_WI_PI_WORKITEM = v_wi_parent;
      EXCEPTION
      WHEN no_data_found THEN
      v_wi_parent := NULL;
    END;

    INSERT INTO TBL_EMAIL_WORKITEM_EXT (
      COL_EMAIL_WI_PI_WORKITEM,
      COL_EMAIL_WORKITEM_EXTCASE,
      COL_PARENTWI
    ) VALUES (
      v_workitemId,
      v_caseId,
      v_wi_parent
    );
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errorCode    := 102;
      v_errorMessage := substr(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;

END;
