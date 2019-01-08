DECLARE 
    v_recordid         INTEGER; 
    v_caseid        INTEGER; 
    v_casetypeid    INTEGER; 
    v_parentfolderid      INTEGER; 
    v_name          NVARCHAR2(255); 
    v_errormessage  NVARCHAR2(255); 
    v_errorcode     NUMBER; 
    v_count         INTEGER; 
    v_first         INTEGER; 
    v_next          INTEGER; 
    v_result        NUMBER; 
    v_tempresult    INTEGER;
BEGIN 
    v_caseid := :CaseId; 
    v_casetypeid := :CaseTypeId; 
    v_parentfolderid := :ParentFolderId; 
    v_name := :Name; 
   	--CHECK THAT CASE OR CASETYPE IS PASSED IN
    IF v_caseid IS NULL 
       AND v_casetypeid IS NULL THEN 
      :ErrorMessage := 'Either CaseId or CaseTypeId is required'; 
      :ErrorCode := 101; 
      RETURN -1; 
    END IF; 

    IF v_caseid IS NOT NULL 
       AND v_casetypeid IS NOT NULL THEN 
      :ErrorMessage := 'Either CaseId or CaseTypeId is required'; 
      :ErrorCode := 102; 
      RETURN -1; 
    END IF; 

	/*CREATE DOCUMENT NAME
    v_result := F_doc_generatefoldername(
					caseid => v_caseid, 
					casetypeid => v_casetypeid , 
					errorcode => v_errorcode, 
					errormessage => v_errormessage, 
					folderid => v_parentfolderid, 
					generatedname => v_name, 
					name => v_name
				); 

	CREATE DOCUMENT RECORD
    INSERT INTO tbl_docfolder 
                (col_name, 
                 COL_DOCFOLDERCASE, 
                 COL_DOCFOLDERCASESYSTYPE, 
                 COL_DOCFOLDERDOCFOLDER) 
                 
    VALUES     (v_name, 
                v_caseid, 
                v_casetypeid, 
                v_parentfolderid)
                
    CREATE DOCUMENT COL_ID	
    returning col_id INTO v_recordid;  */

   v_tempresult := f_doc_createfolderfn(CaseId         => v_CaseId,
                                         NAME           => v_name,
                                         ParentFolderId => NULL,
                                         ErrorCode      => v_errorCode,
                                         ErrorMessage   => v_errorMessage,
                                         RecordId       => v_result);

	
    v_recordid := v_result;
    :RecordId := v_recordid; 
END; 