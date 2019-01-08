DECLARE
  v_recordid       NUMBER;
  v_caseid         NUMBER;
  v_parentfolderid INTEGER;
  v_name           NVARCHAR2(255);
  v_errormessage   NVARCHAR2(255);
  v_errorcode      NUMBER;
  v_result         NUMBER;
BEGIN
  v_caseid         := :CaseId;
  v_parentfolderid := NVL(:ParentFolderId, -1);
  v_name           := :NAME;

  --CHECK THAT CASE IS PASSED IN
  IF v_caseid IS NULL THEN
    :ErrorMessage := 'CaseId is required';
    :ErrorCode    := 101;
    RETURN - 1;
  END IF;

  -- validate Folder name
  v_result := f_doc_validdocnamefn(caseid => v_caseid, errorcode => v_errorcode, errormessage => v_errormessage, isfolder => 1, NAME => v_name, parentid => v_parentfolderid);

  --CREATE DOCFOLDER RECORD
  INSERT INTO tbl_doc_Document
    (col_Name, col_isDeleted, col_IsFolder, col_ParentId, col_Doctype)
  VALUES
    (v_name, 0, 1, v_parentfolderid, 0)
  
  --CREATE DOCUMENT COL_ID  
  RETURNING col_id INTO v_recordid;

  --CREATE LINK TO CASE
  INSERT INTO tbl_doc_docCase (col_DocCaseDocument, col_DocCaseCase) VALUES (v_recordid, v_caseid);

  :RecordId := v_recordid;
END;
