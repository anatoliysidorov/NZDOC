DECLARE
  v_createdby         NVARCHAR2(255);
  v_domain            NVARCHAR2(255);
  v_errorcode         NUMBER;
  v_errormessage      NVARCHAR2(255);
  v_id                NUMBER;
  v_casetype_id       NUMBER;
  v_case_id           NUMBER;
  v_task_id           NUMBER;
  v_extparty_id       NUMBER;
  v_team_id           NUMBER;
  v_cw_id             NUMBER;
  v_ids               NVARCHAR2(255);
  v_linkedIds         NVARCHAR2(255);
  v_queuerecordids    NVARCHAR2(255);
  v_destrversions     NUMBER;
  v_docsinbranchcount NUMBER;
  localhash           ecxtypes.params_hash;
  v_case_isfinish     INTEGER;

  v_TargetID   INT;
  v_TargetType NVARCHAR2(255);
  v_result     NUMBER;
BEGIN
  v_errorcode      := 0;
  v_errormessage   := '';
  v_queuerecordids := '';
  v_ids            := :ids;
  v_casetype_id    := :casetype_id;
  v_case_id        := :case_id;
  v_task_id        := :task_id;
  v_extparty_id    := :extparty_id;
  v_team_id        := :team_id;
  v_cw_id          := :caseworker_id;
  v_createdby      := :token_useraccesssubject;
  v_domain         := :token_domain;
  SELECT listagg(to_char(col_id), ',') WITHIN GROUP(ORDER BY col_id)
    INTO v_linkedIds
    FROM (SELECT col_id
            FROM (SELECT col_id
                    FROM tbl_doc_document
                   WHERE col_id IN (SELECT col_doccsetypedoc FROM tbl_doc_doccasetype WHERE col_doccsetypetype = v_casetype_id)
                  UNION ALL
                  SELECT col_id
                    FROM tbl_doc_document
                   WHERE col_id IN (SELECT col_doccasedocument FROM tbl_doc_doccase WHERE col_doccasecase = v_case_id)
                  UNION ALL
                  SELECT col_id
                    FROM tbl_doc_document
                   WHERE col_id IN (SELECT col_doctaskdocument FROM tbl_doc_doctask WHERE col_doctasktask = v_task_id)
                  UNION ALL
                  SELECT col_id
                    FROM tbl_doc_document
                   WHERE col_id IN (SELECT col_docextprtdoc FROM tbl_doc_docextprt WHERE col_docextprtextprt = v_extparty_id)
                  UNION ALL
                  SELECT col_id
                    FROM tbl_doc_document
                   WHERE col_id IN (SELECT col_docteamdoc FROM tbl_doc_docteam WHERE col_docteamteam = v_team_id)
                  UNION ALL
                  SELECT col_id
                    FROM tbl_doc_document
                   WHERE col_id IN (SELECT col_doccwdoc FROM tbl_doc_doccw WHERE col_doccwcw = v_cw_id))
           GROUP BY col_id);

  IF v_ids IS NULL AND v_linkedIds IS NOT NULL THEN
    v_ids := v_linkedIds;
  ELSIF v_ids IS NOT NULL AND v_linkedIds IS NOT NULL THEN
    v_ids := v_ids || ',' || v_linkedIds;
  END IF;

  FOR doc IN (SELECT column_value AS document_id FROM TABLE(ASF_SPLIT(v_ids, ','))) LOOP
    v_id := doc.document_id;
    SELECT COUNT(*)
      INTO v_docsinbranchcount
      FROM tbl_doc_document
     WHERE col_isfolder = 0
     START WITH col_id = v_id
    CONNECT BY PRIOR col_id = col_parentid;
  
    -- Validate on IsFinished state for Case or Task
    v_result := f_doc_checkstateobjectfn(case_id => NULL, errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, task_id => NULL);
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  
    IF v_docsinbranchcount > 0 THEN
      FOR doc_record IN (SELECT col_id AS id, col_url AS url, col_pdfurl AS pdfurl
                           FROM tbl_doc_document
                          WHERE col_isfolder = 0
                          START WITH col_id = v_id
                         CONNECT BY PRIOR col_id = col_parentid) LOOP
        BEGIN
          localhash('CMS_URL') := doc_record.url;
          v_queuerecordids := v_queuerecordids || ' ' || QUEUE_addWithHash(v_code            => sys_guid(),
                                                                           v_domain          => v_domain,
                                                                           v_createddate     => SYSDATE,
                                                                           v_createdby       => v_createdby,
                                                                           v_owner           => v_createdby,
                                                                           v_scheduleddate   => SYSDATE,
                                                                           v_objecttype      => 1,
                                                                           v_processedstatus => 1,
                                                                           v_processeddate   => SYSDATE,
                                                                           v_errorstatus     => 0,
                                                                           v_parameters      => localhash,
                                                                           v_priority        => 0,
                                                                           v_objectcode      => 'root_DOC_deleteCMSFile',
                                                                           v_error           => '');
          -- add pdfurl from server if it exists
          IF (doc_record.pdfurl IS NOT NULL) THEN
            localhash('CMS_URL') := doc_record.pdfurl;
            v_queuerecordids := v_queuerecordids || ' ' || QUEUE_addWithHash(v_code            => sys_guid(),
                                                                             v_domain          => v_domain,
                                                                             v_createddate     => SYSDATE,
                                                                             v_createdby       => v_createdby,
                                                                             v_owner           => v_createdby,
                                                                             v_scheduleddate   => SYSDATE,
                                                                             v_objecttype      => 1,
                                                                             v_processedstatus => 1,
                                                                             v_processeddate   => SYSDATE,
                                                                             v_errorstatus     => 0,
                                                                             v_parameters      => localhash,
                                                                             v_priority        => 0,
                                                                             v_objectcode      => 'root_DOC_deleteCMSFile',
                                                                             v_error           => '');
          END IF;
          v_destrversions := f_doc_destrdocversfn(errorcode               => :errorcode,
                                                  errormessage            => :errormessage,
                                                  documentid              => doc_record.id,
                                                  versionids              => NULL,
                                                  token_domain            => v_domain,
                                                  token_useraccesssubject => v_createdby);
        EXCEPTION
          WHEN OTHERS THEN
            v_errorcode    := 102;
            v_errormessage := substr(SQLERRM, 1, 200);
            GOTO cleanup;
        END;
      END LOOP;
    END IF;
    BEGIN
      IF v_id IS NOT NULL THEN
        -- Delete by Id
        FOR cur IN (SELECT col_id AS id, col_doc_documentpi_workitem AS workitemId, col_doc_documentcontainer AS containerId, col_IsFolder AS IsFolder
                      FROM tbl_doc_document
                     START WITH col_id = v_id
                    CONNECT BY PRIOR col_id = col_parentid) LOOP
          --add history
          v_result := f_DOC_getContextFn(DocumentID => cur.id, TargetID => v_TargetID, TargetType => v_TargetType);
          IF v_TargetID > 0 THEN
            IF cur.IsFolder = 1 THEN
              v_result := f_HIST_createHistoryFn(AdditionalInfo => f_DOC_getDocumentPath(cur.id),
                                                 IsSystem       => 0,
                                                 Message        => NULL,
                                                 MessageCode    => 'FolderDeleted',
                                                 TargetID       => v_TargetID,
                                                 TargetType     => v_TargetType);
            ELSE
              v_result := f_HIST_createHistoryFn(AdditionalInfo => f_DOC_getDocumentPath(cur.id),
                                                 IsSystem       => 0,
                                                 Message        => NULL,
                                                 MessageCode    => 'FileDeleted',
                                                 TargetID       => v_TargetID,
                                                 TargetType     => v_TargetType);
            END IF;
          END IF;
        
          --delete from linked tables
          DELETE FROM tbl_doc_doccase WHERE col_doccasedocument = cur.id;
        
          DELETE FROM tbl_doc_doctask WHERE col_doctaskdocument = cur.id;
        
          DELETE FROM tbl_doc_doccasetype WHERE col_doccsetypedoc = cur.id;
        
          DELETE FROM tbl_doc_docteam WHERE col_docteamdoc = cur.id;
        
          DELETE FROM tbl_doc_docextprt WHERE col_docextprtdoc = cur.id;
        
          DELETE FROM tbl_doc_doccw WHERE col_doccwdoc = cur.id;
        
          IF (cur.containerId IS NOT NULL) THEN
            DELETE FROM tbl_container WHERE col_id = cur.containerId;
          
          END IF;
          IF (cur.workitemId IS NOT NULL) THEN
            DELETE FROM tbl_email_workitem_ext WHERE col_email_wi_pi_workitem = cur.workitemId;

            DELETE FROM tbl_pi_workitem WHERE col_id = cur.workitemId;
          END IF;
          --delete from main table
          DELETE FROM tbl_doc_document WHERE col_id = cur.id;
        
        END LOOP;
      ELSE
        -- Delete by ObjectId
        IF v_casetype_id IS NOT NULL THEN
          DELETE FROM tbl_doc_document WHERE col_id IN (SELECT col_doccsetypedoc FROM tbl_doc_doccasetype WHERE col_doccsetypetype = v_casetype_id);
        
          DELETE FROM tbl_doc_doccasetype WHERE col_doccsetypetype = v_casetype_id;
        
        END IF;
        IF v_case_id IS NOT NULL THEN
          DELETE FROM tbl_container
           WHERE col_id = (SELECT col_doc_documentcontainer
                             FROM tbl_doc_document
                            WHERE col_id IN (SELECT col_doccasedocument FROM tbl_doc_doccase WHERE col_doccasecase = v_case_id)
                              AND col_doc_documentcontainer IS NOT NULL);

          DELETE FROM tbl_email_workitem_ext WHERE col_email_workitem_extcase = v_case_id;

          DELETE FROM tbl_pi_workitem
           WHERE col_id = (SELECT col_doc_documentpi_workitem
                             FROM tbl_doc_document
                            WHERE col_id IN (SELECT col_doccasedocument FROM tbl_doc_doccase WHERE col_doccasecase = v_case_id)
                              AND col_doc_documentpi_workitem IS NOT NULL);
        
          DELETE FROM tbl_doc_document WHERE col_id IN (SELECT col_doccasedocument FROM tbl_doc_doccase WHERE col_doccasecase = v_case_id);
        
          DELETE FROM tbl_doc_doccase WHERE col_doccasecase = v_case_id;
        
        END IF;
        IF v_task_id IS NOT NULL THEN
          DELETE FROM tbl_doc_document WHERE col_id IN (SELECT col_doctaskdocument FROM tbl_doc_doctask WHERE col_doctasktask = v_task_id);
        
          DELETE FROM tbl_doc_doctask WHERE col_doctasktask = v_task_id;
        
        END IF;
        IF v_extparty_id IS NOT NULL THEN
          DELETE FROM tbl_doc_document WHERE col_id IN (SELECT col_docextprtdoc FROM tbl_doc_docextprt WHERE col_docextprtextprt = v_extparty_id);
        
          DELETE FROM tbl_doc_docextprt WHERE col_docextprtextprt = v_extparty_id;
        
        END IF;
        IF v_team_id IS NOT NULL THEN
          DELETE FROM tbl_doc_document WHERE col_id IN (SELECT col_docteamdoc FROM tbl_doc_docteam WHERE col_docteamteam = v_team_id);
        
          DELETE FROM tbl_doc_docteam WHERE col_docteamteam = v_team_id;
        
        END IF;
        IF v_cw_id IS NOT NULL THEN
          DELETE FROM tbl_doc_document WHERE col_id IN (SELECT col_doccwdoc FROM tbl_doc_doccw WHERE col_doccwcw = v_cw_id);
        
          DELETE FROM tbl_doc_doccw WHERE col_doccwcw = v_cw_id;
        
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        v_errorcode    := 102;
        v_errormessage := substr(SQLERRM, 1, 200);
        GOTO cleanup;
    END;
  END LOOP;

  <<cleanup>>
  :errorcode    := v_errorcode;
  :errormessage := v_errormessage;
END;