DECLARE
    v_Id             NUMBER;
    v_errorcode NUMBER;
    v_errormessage NVARCHAR2(255);
    v_name NVARCHAR2(255);
    v_childdocs  NUMBER :=0;
    v_subfolders NUMBER :=0;
  BEGIN
    v_errorcode      := 0;
    v_ErrorMessage   := '';
    v_Id             := :FolderId;
     -- get cms url of document by id
     
    /*
    BEGIN
      SELECT col_name INTO  v_name FROM tbl_Docfolder WHERE col_id = v_Id;
    EXCEPTION
    WHEN no_data_found THEN
      v_ErrorMessage := 'Folder not found';
      v_ErrorCode    := 1;
      GOTO cleanup;
    WHEN OTHERS THEN
      v_ErrorCode    := 100;
      v_ErrorMessage := SUBSTR(SQLERRM, 1, 200);
      GOTO cleanup;
    END;
    */
    -- Check that the folder has not child  documents or subfolders
    /*
    BEGIN
      SELECT COUNT (COL_ID)
      INTO v_childdocs
      FROM TBL_DOCUMENT
      WHERE COL_DOCUMENTDOCFOLDER = v_Id;
    END;
    */
    /*
    BEGIN
      SELECT COUNT (COL_ID)
      INTO v_subfolders
      FROM TBL_DOCFOLDER
      WHERE COL_DOCFOLDERDOCFOLDER = v_Id;
    END;
    */
    IF(v_childdocs+v_subfolders >0) THEN
      v_errorcode              := 11;
      v_errormessage           := 'Folder '|| v_name||' is not empty!'||chr(10)||'Please, empty the folder before delete';
      GOTO cleanup;
    END IF;
   
    
    /*
    BEGIN
      DELETE FROM tbl_Docfolder WHERE col_id = v_Id;
    EXCEPTION
    WHEN no_data_found THEN
      v_ErrorMessage := 'Error during deleting folder';
      v_ErrorCode    := 2;
      GOTO cleanup;
    WHEN OTHERS THEN
      v_ErrorCode    := 100;
      v_ErrorMessage := SUBSTR(SQLERRM, 1, 200);
      GOTO cleanup;
    END;
    */
    <<cleanup>>
    ErrorMessage := v_ErrorMessage;
    ErrorCode    := v_errorcode;
  END;