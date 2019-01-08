DECLARE
  v_docid         INTEGER;
  v_caseid        INTEGER;
  v_casetypeid    INTEGER;
  v_folderid      INTEGER;
  v_url           NVARCHAR2(255);
  v_name          NVARCHAR2(255);
  v_description   NCLOB;
  v_errormessage  NVARCHAR2(255);
  v_errorcode     NUMBER;
  v_count         INTEGER;
  v_first         INTEGER;
  v_next          INTEGER;
  v_result        NUMBER;
  v_ScanLocation  NVARCHAR2(255);
  v_DocTypeId     NUMBER;
  v_Return        NUMBER;

BEGIN
  v_caseid       := :CaseId;
  v_casetypeid   := :CaseTypeId;
  v_folderid     := :FolderId;
  v_name         := :NAME;
  v_url          := :Url;
  v_description  := :Description;
  v_DocTypeId    := :DocTypeId;
  v_ScanLocation := :ScanLocation;

  --CHECK THAT CASE OR CASETYPE IS PASSED IN
  IF v_caseid IS NULL THEN
    :ErrorMessage := 'CaseId is required';
    :ErrorCode    := 101;
    RETURN - 1;
  END IF;

  v_Return := F_DOC_VALIDDOCNAMEFN(
      ERRORCODE => v_errorcode,
      ERRORMESSAGE => v_errormessage,
      NAME => v_name
  );
  IF v_errorcode <> 0 THEN
    :ErrorMessage := v_errormessage;
    :ErrorCode    := v_errorcode;
    RETURN - 1;
  END IF;

  --CREATE DOCUMENT RECORD
  INSERT INTO tbl_doc_Document
    (col_Name,
     col_Url,
     col_Description,
     col_isDeleted,
     col_IsFolder,
     col_ParentId,
     col_DocType)
  VALUES
    (v_name, v_url, v_description, 0, 0, v_folderid, v_DocTypeId)
  
  --GET DOCUMENT COL_ID
  RETURNING col_id INTO v_docid;

  --CREATE LINK TO CASE
  INSERT INTO tbl_doc_docCase (col_DocCaseDocument, col_DocCaseCase) VALUES (v_docid, v_caseid);

  :DocId := v_docid;
END;