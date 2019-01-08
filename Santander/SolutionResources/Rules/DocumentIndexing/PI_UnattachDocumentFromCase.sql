DECLARE
  --INPUT
  v_docId        NUMBER;
  v_isId         NUMBER;
  v_workitemId   NUMBER;
  v_isfolder     INTEGER;
  v_folderId     NUMBER;
  v_count        NUMBER;
  v_msg          NVARCHAR2(255);
  v_workbasketID NUMBER;
  v_containerId  NUMBER;
  v_docName      NVARCHAR2(255);
  v_res          NUMBER;
  v_uniqCode     NVARCHAR2(255);

  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
BEGIN

  -- Input
  v_docId        := :DocId;
  v_workbasketID := :WorkbasketId;

  v_errorCode    := 0;
  v_errorMessage := '';

  :SuccessResponse := '';

  BEGIN
    -- check on NULLs
    IF v_docId IS NULL THEN
      v_errorCode    := 100;
      v_errorMessage := 'DocumentId can not be NULL';
      GOTO cleanup;
    END IF;
  
    IF v_workbasketID IS NULL THEN
      v_errorCode    := 100;
      v_errorMessage := 'WorkbasketId can not be NULL';
      GOTO cleanup;
    END IF;
  
    -- validation on Id is Exist
    IF NVL(v_docId, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode => v_errorCode, errormessage => v_errorMessage, id => v_docId, tablename => 'TBL_DOC_DOCUMENT');
      IF v_errorCode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    -- get Data
    SELECT col_doc_documentpi_workitem,
           col_isfolder,
           col_name
      INTO v_workitemId,
           v_isfolder,
           v_docName
      FROM tbl_doc_document
     WHERE col_id = v_docId;
    IF NVL(v_isfolder, 0) = 0 THEN
      v_msg := 'Document';
    
      SELECT col_parentid INTO v_folderId FROM tbl_doc_document WHERE col_id = v_docId;
      -- check on Document is linked to Folder
      IF NVL(v_folderId, 0) = 0 THEN
        v_errorCode    := 101;
        v_errorMessage := 'Document does not have a Folder.';
        GOTO cleanup;
      END IF;
    
      -- check Document on linked to Workitem
      IF NVL(v_workitemId, 0) = 0 THEN
        v_uniqCode := upper(REPLACE(REPLACE(v_docName, ' ', '_'), '.', '_'));
        v_uniqCode := substr(v_uniqCode, 0, 245) || '_' || to_char(SYSDATE, 'MMDDYYYY');
      
        INSERT INTO tbl_container (col_name, col_code, col_containercontainertype) VALUES (v_docName, v_uniqCode, (SELECT col_id FROM tbl_dict_containertype WHERE col_code = 'ENVELOPE'));
      
        SELECT gen_tbl_container.currval INTO v_containerId FROM dual;
      
        INSERT INTO tbl_pi_workitem
          (col_name, col_code, col_currmsactivity, col_pi_workitemdict_state)
        VALUES
          (v_docName,
           v_uniqCode,
           (SELECT s.col_activity
              FROM tbl_dict_state s
             INNER JOIN tbl_dict_stateconfig sc
                ON sc.col_id = s.col_statestateconfig
               AND sc.col_iscurrent = 1
             WHERE s.col_code = 'DOCINDEXINGSTATES_CREATED'),
           (SELECT s.col_id
              FROM tbl_dict_state s
             INNER JOIN tbl_dict_stateconfig sc
                ON sc.col_id = s.col_statestateconfig
               AND sc.col_iscurrent = 1
             WHERE s.col_code = 'DOCINDEXINGSTATES_CREATED'));
      
        SELECT gen_tbl_pi_workitem.currval INTO v_workitemId FROM dual;
      
        UPDATE tbl_doc_document
           SET col_doc_documentcontainer = v_containerId, col_doc_documentpi_workitem = v_workitemId, col_isprimary = 1
         WHERE col_id = v_docId;
      
        UPDATE tbl_pi_workitem SET col_title = 'DOC-' || to_char(SYSDATE, 'YYYY') || '-' || to_char(v_workitemId) WHERE col_id = v_workitemId;
      END IF;
    ELSE
      -- It's a folder
      v_msg      := 'Folder';
      v_folderId := v_docId;
    END IF;
  
    -- unattach documents
    FOR cur IN (SELECT col_id AS id
                  FROM tbl_doc_document
                 WHERE col_parentid = v_folderId
                   AND col_doc_documentpi_workitem = v_workitemId) LOOP
      DELETE FROM tbl_doc_docCase WHERE col_doccasedocument = cur.id;
      UPDATE tbl_doc_document SET col_parentid = NULL  WHERE col_id = cur.id;
    END LOOP;
  
    -- check on folder is depended in Case Type
    SELECT COUNT(col_id) INTO v_count FROM tbl_doc_doccasetype WHERE col_doccsetypedoc = v_folderId;
  
    IF (v_count = 0) THEN
      -- check on document is present in the folder
      SELECT COUNT(col_id) INTO v_count FROM tbl_doc_document WHERE col_parentid = v_folderId;
      -- delete Folder
      IF v_count = 0 THEN
        DELETE FROM tbl_doc_docCase WHERE col_doccasedocument = v_folderId;
        DELETE FROM tbl_doc_document WHERE col_id = v_folderId;
      END IF;
    END IF;
  
    -- update Workbasket
    UPDATE tbl_pi_workitem
       SET col_pi_workitemppl_workbasket = v_workBasketId,
           col_pi_workitemprevworkbasket =
           (SELECT col_pi_workitemppl_workbasket FROM TBL_PI_WORKITEM WHERE col_Id = v_workitemId)
     WHERE col_id = v_workitemId;
  
    -- change WorkItem State to 'Waiting to Review'
    v_res := f_PI_setWorkitemState(ActionCode => 'UNATTACH_FROM_CASE', WorkitemId => v_workitemId, ErrorCode => v_errorCode, ErrorMessage => v_errorMessage);
  
    IF (v_errorCode <> 0) THEN
      ROLLBACK;
      GOTO cleanup;
    ELSE
      :SuccessResponse := v_msg || ' was successfully unattached from Case';
    END IF;

    DELETE FROM TBL_EMAIL_WorkItem_EXT WHERE COL_EMAIL_WI_PI_WORKITEM = v_workitemId;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      v_errorCode    := 103;
      v_errorMessage := substr(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;

END;
