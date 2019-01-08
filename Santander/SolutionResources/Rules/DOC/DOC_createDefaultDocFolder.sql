DECLARE
  v_result        INTEGER;
  v_tempresult    INTEGER;
  v_caseid        INTEGER;
  v_casetype      INTEGER;
  v_docfoldertype NVARCHAR2(255);
  v_defaultName   NVARCHAR2(255);
  ErrorCode       NUMBER;
  ErrorMessage    NVARCHAR2(255);
BEGIN
  v_caseid        := :CaseId;
  v_casetype      := f_DCM_getCaseTypeForCase(v_caseid);
  v_docfoldertype := Lower(:DocFolderType);

  --get all default folders for the Case
  BEGIN
    SELECT CASE v_docfoldertype
             WHEN N'portal' THEN
              col_DefaultPrtlCaseDocFolder
             WHEN N'mail' THEN
              COL_DEFAULTMAILCASEDOCFOLDER
             WHEN N'main' THEN
              col_defaultcasedocfolder
             ELSE
              NULL
           END
      INTO v_result
      FROM tbl_case
     WHERE col_id = v_caseid;
  EXCEPTION
    WHEN no_data_found THEN
      RETURN NULL;
  END;

  --get default folders for the Case Type if Case doesn't have it's own configuration
  IF NVL(v_result, 0) = 0 THEN
    BEGIN
      SELECT CASE v_docfoldertype
               WHEN N'portal' THEN
                col_defaultportaldocfolder
               WHEN N'mail' THEN
                col_defaultmailfolder
               WHEN N'main' THEN
                col_defaultdocfolder
               ELSE
                NULL
             END
        INTO v_result
        FROM tbl_dict_casesystype
       WHERE col_id = v_casetype;
    EXCEPTION
      WHEN no_data_found THEN
        RETURN NULL;
    END;
  END IF;

  --if no default folder, then create one
  IF NVL(v_result, 0) = 0 THEN --commented for DCM-2736
    SELECT CASE v_docfoldertype
             WHEN N'portal' THEN
              'Initial Documents'
             WHEN N'mail' THEN
              'Correspondence'
             WHEN N'main' THEN
              'Initial Documents'
             ELSE
              'Miscellaneous'
           END
      INTO v_defaultName
      FROM dual;
  
    v_tempresult := f_doc_createfolderfn(CaseId         => v_CaseId,
                                         NAME           => v_defaultName,
                                         ParentFolderId => NULL,
                                         ErrorCode      => errorCode,
                                         ErrorMessage   => errorMessage,
                                         RecordId       => v_result);
  
    IF v_docfoldertype = 'portal' THEN
      UPDATE tbl_CASE SET col_DefaultPrtlCaseDocFolder = v_result WHERE col_id = v_caseid;
    ELSIF v_docfoldertype = 'mail' THEN
      UPDATE tbl_CASE SET COL_DEFAULTMAILCASEDOCFOLDER = v_result WHERE col_id = v_caseid;
    ELSE
      UPDATE tbl_CASE SET col_defaultcasedocfolder = v_result WHERE col_id = v_caseid;
    END IF;
  
  END IF;

  RETURN v_result;
END;