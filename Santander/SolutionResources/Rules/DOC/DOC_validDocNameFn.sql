DECLARE
  v_name             NVARCHAR2(255);
  v_newName          NVARCHAR2(255);
  i                  NUMBER;
  hits               NUMBER;
  v_query            VARCHAR(4000);
  v_docId            NUMBER;
  v_caseid           NUMBER;
  v_caseTypeId       NUMBER;
  v_taskId           NUMBER;
  v_partyId          NUMBER;
  v_teamId           NUMBER;
  v_cwId             NUMBER;
  v_parentId         NUMBER;
  v_isFolder         INTEGER;
  v_isGlobalResource INTEGER;

  v_errorMessage NVARCHAR2(255);
  v_errorCode    INTEGER;

BEGIN
  v_name             := :NAME;
  v_newName          := v_name;
  v_docId            := :DocId;
  v_caseTypeId       := :CaseTypeId;
  v_caseId           := :CaseId;
  v_taskId           := :TaskId;
  v_partyId          := :PartyId;
  v_teamId           := :TeamId;
  v_cwId             := :CwId;
  v_parentId         := :ParentId;
  v_isFolder         := NVL(:IsFolder, 0);
  v_isGlobalResource := NVL(:IsGlobalResource, 0);
  i                  := 0;

  v_errorCode    := 0;
  v_errorMessage := NULL;

  --Validate a Name
  IF v_name IS NOT NULL THEN
    IF REGEXP_INSTR(v_name, n'[\/:*?"<>|]') > 0 THEN
      v_errorMessage := 'Doc name must not contain characters \ / : * ? " < > |';
      v_errorCode    := 101;
      RETURN - 1;
    END IF;
  
    -- get object Ids by Doc_Id
    IF v_docId IS NOT NULL THEN
    
      BEGIN
        SELECT casetypeid,
               caseid,
               taskid,
               extpartyid,
               teamid,
               caseworkerid
          INTO v_caseTypeId,
               v_caseId,
               v_taskId,
               v_partyId,
               v_teamId,
               v_cwId
          FROM vw_doc_documents
         WHERE id = v_docId;
      EXCEPTION
        WHEN no_data_found THEN
          NULL;
      END;
    END IF;
  
    IF v_isFolder = 1 THEN
    
      v_query := 'begin ' || 'SELECT count(1) INTO :' || 'bind_count FROM vw_doc_documents WHERE UPPER(NAME) = UPPER(to_char(:' || 'bind_name)) AND isfolder = 1';
      v_query := v_query || ' AND calcparentid = ' || to_char(v_parentId);
    
      IF nvl(v_caseTypeId, 0) > 0 THEN
        v_query := v_query || ' AND (casetypeid = ' || to_char(v_caseTypeId);
        v_query := v_query || ' OR caseid IN (SELECT col_id FROM tbl_case WHERE col_casedict_casesystype = ' || to_char(v_caseTypeId) || '))';
      ELSIF nvl(v_caseId, 0) > 0 AND nvl(v_taskId, 0) = 0 THEN
        v_query := v_query || ' AND (caseid = ' || to_char(v_caseId);
        v_query := v_query || ' OR casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = ' || to_char(v_caseId) || '))';
      ELSIF nvl(v_taskId, 0) > 0 THEN
        v_query := v_query || ' AND taskid = ' || to_char(v_taskId);
      ELSIF nvl(v_partyId, 0) > 0 THEN
        v_query := v_query || ' AND extpartyid = ' || to_char(v_partyId);
      ELSIF nvl(v_teamId, 0) > 0 THEN
        v_query := v_query || ' AND teamid = ' || to_char(v_teamId);
      ELSIF nvl(v_cwId, 0) > 0 THEN
        v_query := v_query || ' AND caseworkerid = ' || to_char(v_cwId);
      ELSIF v_isGlobalResource > 0 THEN
        v_query := v_query || ' AND isglobalresource = ' || to_char(v_isGlobalResource);
      END IF;
    
      v_query := v_query || '; end;';
    
      LOOP
        BEGIN
          IF i = 0 THEN
            EXECUTE IMMEDIATE v_query
              USING OUT hits, v_name;
          ELSE
            v_newName := v_name || '_' || to_char(i);
            EXECUTE IMMEDIATE v_query
              USING OUT hits, v_newName;
          END IF;
          i := i + 1;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        EXIT WHEN hits = 0;
      END LOOP;
    
      IF i > 1 THEN
        v_name         := v_newName;
        v_errorMessage := 'Folder name must be unique!' || chr(10) || 'Please enter new Folder name.';
        v_errorCode    := 102;
      END IF;
    END IF;
  END IF;

  :NAME         := v_name;
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
END;
