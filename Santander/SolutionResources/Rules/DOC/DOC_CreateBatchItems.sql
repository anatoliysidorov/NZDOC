DECLARE 
    v_rawtypes       NVARCHAR2(4000); 
    v_urls           NVARCHAR2(4000); 
    v_names          NVARCHAR2(4000); 
    v_scanlocation   NVARCHAR2(255); 
    v_parentfolderid NUMBER; 
    v_caseid         NUMBER; 
    v_taskid         NUMBER; 
    v_casetypeid     NUMBER; 
    v_doctypeid      NUMBER; 
    v_description    NCLOB; 
    v_errorcode      NUMBER; 
    v_errormessage   NVARCHAR2(255); 
    v_recordids      NVARCHAR2(4000); 
    v_docfoldertype    NVARCHAR2(255); 
    v_index          NUMBER := 1; 
    v_cur_name       NVARCHAR2(255); 
    v_cur_url        NVARCHAR2(255); 
    v_result         NUMBER; 
    v_newitemid      NUMBER; 
BEGIN 
    v_errormessage := ''; 
    v_errorcode := 0; 
    v_rawtypes := :RawTypes; 
    v_urls := :URLS; 
    v_names := :Names; 
    v_parentfolderid := :ParentFolderId;
    v_caseid := :CaseId; 
    v_taskid := :TaskId; 
    v_casetypeid := :CaseTypeId; 
    v_description := :Description;
    v_doctypeid := :DocTypeId; 
    v_docfoldertype := :DocFolderType; 
    v_scanlocation := :ScanLocation;
    :RecordIds := ''; 
    :ErrorMessage := ''; 
    :ErrorCode := 0; 

	--determine what Case this folder or document should be associated with
	IF (v_CaseId is NULL and v_CaseTypeId IS NULL AND v_TaskId IS NOT NULL) THEN
		BEGIN
			SELECT COL_CASETASK INTO v_CaseId FROM TBL_TASK WHERE COL_ID = v_TaskId;
		EXCEPTION
			WHEN NO_DATA_FOUND
		THEN
			v_CaseId := NULL;
		END;
	END IF;
		
	--loop through all of the folders/documents and add them  
	FOR rec IN (SELECT to_char(column_value) AS rawtype FROM TABLE(asf_split(v_rawtypes, '|||'))) 
	LOOP 
		--get names
		SELECT name 
		INTO   v_cur_name 
		FROM   ( 
					SELECT to_char(column_value) AS name, 
						   ROWNUM                AS rn1 
					FROM   TABLE(asf_split(v_names, '|||')) ) 
		WHERE  rn1 = v_index;
	  
		--get urls
		SELECT url 
		INTO   v_cur_url 
		FROM   ( 
					SELECT To_char(column_value) AS url, 
						   ROWNUM                AS rn2 
					FROM   TABLE(asf_split(NVL(v_urls, ''), '|||')) ) 
		WHERE  rn2 = v_index;

		IF (rec.rawtype = 'DOCUMENT') THEN 
			--calculate the ID of the ParentFolder
			IF NVL(v_ParentFolderId, 0) = 0 THEN
				v_ParentFolderId := f_DOC_getDefaultDocFolder(CaseId => v_CaseId, DocFolderType => v_docfoldertype);
			END IF;
	
		  --create document
		  v_result := f_doc_adddocfn(caseid => v_caseid, 
									  casetypeid => v_casetypeid, 
									  description => v_description, 
									  docid => v_newitemid,
									  errorcode => v_errorcode, 
									  errormessage => v_errormessage, 
									  folderid => v_parentfolderid, 
									  name => v_cur_name, 
									  url => v_cur_url,
									  doctypeid => v_DocTypeId,
									  ScanLocation => v_ScanLocation);

		  IF(v_result <> 0) THEN
			v_errormessage := 'There was an error with document ' ||v_cur_name || chr(10) || v_errormessage;
			rollback;
			:RecordIds := '';
			GOTO cleanup;
		  ELSE 
			:RecordIds := :RecordIds || v_newitemid  || '|||';
		  END IF;

		ELSIF (rec.rawtype = 'FOLDER') THEN 
		  --create folder
		  v_result := f_doc_addfolderfn2(caseid => v_caseid, 
										 casetypeid => v_casetypeid, 
										 recordid => v_newitemid, 
										 errormessage => v_errormessage, 
										 errorcode => v_errorcode, 
										 parentfolderid => v_parentfolderid, 
										 name => v_cur_name);
		  IF(v_result <> 0) THEN
			v_errormessage := 'There was an error with a folder ' ||v_cur_name || chr(10) || v_errormessage;
			rollback;
			:RecordIds := '';
			GOTO cleanup;
		  ELSE 
			:RecordIds := :RecordIds || v_newitemid || '|||';
		  END IF;
		ELSE 
		  v_errorcode := 12;
		  v_errormessage := 'Raw Type ' || rec.rawtype ||' is not recognized!';
		  rollback;
		  :RecordIds := '';
		  GOTO cleanup;
		END IF;

		v_index := v_index+1;
	END LOOP;
<<cleanup>>
if length(:RecordIds) > 0 then
  :Recordids := substr(:RecordIds, 1, length(:RecordIds)-3);
end if;
:ErrorMessage := v_ErrorMessage;
:ErrorCode    := v_errorcode;
END;