DECLARE
    --custom
    v_id NUMBER;
    v_col_Name NVARCHAR2(255);
    v_col_ParentId NUMBER;
    v_col_isDeleted NUMBER;
    v_col_IsFolder NUMBER;
    v_col_IsGlobalResource NUMBER;
    v_col_URL NVARCHAR2(255);
    v_file_ext NVARCHAR2(25);
    v_col_Description NCLOB;
    v_col_Doctype NUMBER;

    v_parentIsDeleted NUMBER;
    v_folderOrder NUMBER;
    v_objectId NUMBER;
    v_objectType NVARCHAR2(255);
    v_CustomParentId number;

    --links
    v_Case_Id NUMBER;
    v_Task_Id NUMBER;
    v_ExtParty_Id NUMBER;

    --default
    v_errorcode NUMBER;
    v_errormessage NVARCHAR2(255);
    v_affectedRows NUMBER;
    v_trgtParent NUMBER;
    v_isId INT;
    v_folderName NVARCHAR2(255);

    -- add for WI
    v_workitemId number;
    v_containerId number;
    v_currentYear nvarchar2(4);
    v_WorkitemCode nvarchar2(255);
    v_WorkitemName nvarchar2(255);
    v_WI_Parent Integer;
    v_CurrentActivity nvarchar2(255);
    v_NextActivity nvarchar2(255);
    v_ContainerCode nvarchar2(255);
    v_ContainerType Integer;
    v_DataXML XMLType;
    v_StateId Integer;
    v_res number;
    v_html_URL nvarchar2(255);
BEGIN
  -- not used Parameters
      -- :TemplateCode       - Code of the template used to generate the document
      -- :ContentLength      - File size in bytes of the resulted document
      -- :ContentType        - Content type of the resulted file as defined in AppBase ASF.Framework.Util.MimeHelper.GetContentTypeForExtension method.
      -- :FileExtension      - File extension of the resulted document
      -- :OrigianlFileName   - File name of the resulted document
      -- :Pages              - Number of pages of the resulted document, this parameter is only used for PDF or MS Word resulted documents.
      -- :Source             - Always passed "System" value.
      -- :DataXML            - This parameter has value only for Email and XSLT templates. It is empty for others.

  --custom
  v_col_Name := :Name;
  v_col_isDeleted := 0;
  v_folderOrder := null;
  v_col_IsFolder := 0;
  v_col_IsGlobalResource := 0;
  v_col_ParentId := NVL(:FOLDERID, -1);
  v_col_URL := :URL;
  v_html_URL := :HTMLURL;
  v_col_Description := :Description;
  v_col_Doctype := :DocType;
  v_objectType := upper(:ObjectType);
  v_objectId := :ObjectId;

  --default
  v_affectedRows := 0;
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  v_folderName := nvl(:FolderName, 'Correspondence');

  --use ObjectType and ObjectId if exists
    if v_objectType is not null and nvl(v_objectId, 0) > 0 then
      if(v_objectType = 'ROOT_CASE') then
        v_Case_Id := v_objectId;
      elsif (v_objectType = 'ROOT_TASK') then
        v_Task_Id := v_objectId;
      elsif (v_objectType = 'ROOT_EXTERNALPARTY') then
        v_ExtParty_Id := v_objectId;
      end if;
    else
      v_errorCode := 106;
      v_errorMessage := 'ObjectType and ObjectId parameters are required';
      GOTO cleanup;
    end if;

  -- validation on Id is Exist
    -- CASE_ID
    IF NVL(v_Case_Id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_Case_Id,
                             tablename    => 'TBL_CASE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;

    -- TASK_ID
    IF NVL(v_Task_Id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_Task_Id,
                             tablename    => 'TBL_TASK');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;

    -- EXTPARTY_ID
    IF NVL(v_ExtParty_Id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_ExtParty_Id,
                             tablename    => 'TBL_EXTERNALPARTY');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;

  -- URL validation
  IF v_col_URL IS NULL THEN
    v_errorCode    := 101;
    v_errorMessage := 'Please upload document before save';
    GOTO cleanup;
  END IF;

  -- Get file extension from url and concatenate to Name if needed
  v_file_ext := SUBSTR(v_col_URL,INSTR(v_col_URL,'.',-1,1),length(v_col_URL));
  if(v_col_Name not like '%' || v_file_ext) then
      v_col_Name := v_col_Name || v_file_ext;
  end if;

  IF v_col_ParentId IS NOT NULL AND v_col_ParentId != -1 THEN
    SELECT col_isDeleted INTO v_parentIsDeleted FROM tbl_doc_Document WHERE col_id = v_col_ParentId;

    IF NVL(v_parentIsDeleted, 0) = 1 THEN
      v_errorCode    := 103;
      v_errorMessage := 'Parent of this document is disabled';
      GOTO cleanup;
    END IF;
  END IF;

    IF :DataXML is null THEN
        v_errorCode    := 103;
        v_errorMessage := 'Content can not be empty';
        GOTO cleanup;
    END IF;

    v_DataXML := XMLType(:DataXML);

    v_WorkitemCode := 'PIWI_' || to_char(sysdate, 'MMDDYYYY_HHMMSS');
    v_currentYear := to_char(sysdate, 'YYYY');
    v_ContainerCode := 'CONTAINER_' || to_char(sysdate, 'MMDDYYYY_HHMMSS');

    Begin
        Select
            cont.col_id
        Into
            v_ContainerType
        From tbl_dict_containertype cont
        Where cont.COL_CODE = 'EMAIL';
    Exception
        When OTHERS Then
            v_ContainerType := 1;
    End;

    Begin
        Select
            nvl(s.col_id, 0),
            s.col_activity,
            targetState.col_activity
        Into
            v_StateId,
            v_CurrentActivity,
            v_NextActivity
        From tbl_dict_state s
            inner join tbl_dict_stateconfig sc on sc.col_id = s.COL_STATESTATECONFIG
            inner join tbl_dict_casestate cs on cs.col_id = s.COL_STATECASESTATE
            inner join tbl_dict_transition t on t.COL_SOURCETRANSITIONSTATE = s.col_id
            inner join tbl_dict_state targetState on targetState.col_id = t.COL_TARGETTRANSITIONSTATE
            left join tbl_dict_stateconfigtype sct on sct.col_id = sc.COL_STATECONFSTATECONFTYPE
        Where sct.col_code = 'DOCUMENT'
            and sc.col_iscurrent = 1
            and cs.col_isstart = 1;
    Exception
        When OTHERS Then
          v_errorCode    := 104;
          v_errorMessage := 'State Id or Current Activity is absent';
          GOTO cleanup;
    End;

    v_WorkitemName := v_DataXML.extract('/CONTENT/SUBJECT/text()').getStringval();


  --set assumed success message for documents and folders
  :SuccessResponse := 'Created ' || v_col_Name || ' document';

  BEGIN
      if NVL(v_col_ParentId, 0) < 1 then
        -- Check for existed v_folderName folder
        -- v_CustomParentId  := null;
        BEGIN
          IF v_Case_Id IS NOT NULL AND v_Task_Id IS NULL THEN

              select col_id into v_CustomParentId from (
                  select d.col_id from tbl_doc_document d
                    inner join tbl_doc_doccase c on c.col_DocCaseDocument = d.col_id
                  where d.col_isfolder = 1 and nvl(d.col_isdeleted, 0) <> 1 and upper(d.col_name) = upper(v_folderName) and c.col_DocCaseCase = v_Case_Id
                  order by d.col_parentid asc, d.col_folderorder asc
              )
              where rownum = 1;
          END IF;

          IF v_Task_Id IS NOT NULL THEN
            select col_id into v_CustomParentId from (
                select d.col_id from tbl_doc_document d
                  inner join tbl_doc_docTask t on t.col_DocTaskDocument = d.col_id
                where d.col_isfolder = 1 and nvl(d.col_isdeleted, 0) <> 1 and upper(d.col_name) = upper(v_folderName) and t.col_DocTaskTask = v_Task_Id
                order by d.col_parentid asc, d.col_folderorder asc
            )
            where rownum = 1;
          END IF;

          IF v_ExtParty_Id IS NOT NULL THEN
            select col_id into v_CustomParentId from (
                select d.col_id from tbl_doc_document d
                  inner join tbl_doc_docExtPrt p on p.col_docextprtdoc = d.col_id
                where d.col_isfolder = 1 and nvl(d.col_isdeleted, 0) <> 1 and upper(d.col_name) = upper(v_folderName) and p.col_docextprtextprt = v_ExtParty_Id
                order by d.col_parentid asc, d.col_folderorder asc
            )
            where rownum = 1;
          END IF;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN v_CustomParentId  := null;
        END;

        --Insert new Folder
        IF v_CustomParentId IS NULL THEN
          Insert into tbl_doc_document (COL_FOLDERORDER,COL_ISGLOBALRESOURCE,COL_NAME,COL_PARENTID,COL_ISDELETED,COL_ISFOLDER,COL_DOCTYPE)
          values (1,0,v_folderName,-1,0,1,0) RETURNING col_id into v_CustomParentId;

          -- Create link between Entity and Folder
          IF v_Case_Id IS NOT NULL AND v_Task_Id IS NULL THEN
            INSERT INTO tbl_doc_docCase (col_DocCaseDocument, col_DocCaseCase) VALUES (v_CustomParentId, v_Case_Id);
          END IF;

          IF v_Task_Id IS NOT NULL THEN
            INSERT INTO tbl_doc_docTask (col_DocTaskDocument, col_DocTaskTask) VALUES (v_CustomParentId, v_Task_Id);
          END IF;

          IF v_ExtParty_Id IS NOT NULL THEN
            INSERT INTO tbl_doc_docExtPrt (col_docextprtdoc, col_docextprtextprt) VALUES (v_CustomParentId, v_ExtParty_Id);
          END IF;

        END IF;
      else
        v_CustomParentId := v_col_ParentId;
      end if;

        v_WI_Parent := :WORKITEMID;
        Select nvl(COL_PARENTWI, v_WI_Parent) Into v_WI_Parent From TBL_EMAIL_WORKITEM_EXT Where COL_EMAIL_WI_PI_WORKITEM = v_WI_Parent;

        insert into tbl_pi_workitem (
            col_code,
            col_name,
            col_currmsactivity,
            col_pi_workitemdict_state,
            col_pi_workitemppl_workbasket
        )
        values (
            v_WorkitemCode,
            v_WorkitemName,
            v_CurrentActivity,
            v_StateId,
            f_DCM_getMyPersonalWorkbasket()
        ) returning col_id into v_workitemId;

        update tbl_pi_workitem set
            col_title = 'DOC-' || v_currentYear || '-' || v_workitemId
        where col_id = v_workitemId;

        insert into tbl_container (
            col_code,
            col_name,
            col_containercontainertype,
            col_customdata
        )
        values (
            v_ContainerCode,
            v_WorkitemName,
            v_ContainerType,
            v_DataXML
        ) returning col_id into v_containerId;

        INSERT INTO tbl_doc_Document (
            col_Name,
            col_folderorder,
            col_isDeleted,
            col_IsFolder,
            col_ParentId,
            col_Description,
            col_Doctype,
            COL_PDFURL,
            col_IsGlobalResource,
            COL_DOC_DOCUMENTCONTAINER,
            COL_DOC_DOCUMENTPI_WORKITEM,
            col_isprimary,
            COL_URL,
            COL_DOC_DOCUMENTSYSTEMTYPE)
        VALUES (
            v_col_Name,
            v_folderOrder,
            v_col_isDeleted,
            v_col_IsFolder,
            v_CustomParentId,
            v_col_Description,
            v_col_Doctype,
            v_col_URL,
            v_col_IsGlobalResource,
            v_containerId,
            v_workitemId,
            1,
            v_html_URL,
            (Select col_id From tbl_dict_systemtype Where col_code = 'EMAIL_HTML'))
        RETURNING col_id INTO v_id;

        IF v_Case_Id IS NOT NULL AND v_Task_Id IS NULL THEN
            INSERT INTO tbl_doc_docCase (col_DocCaseDocument, col_DocCaseCase) VALUES (v_id, v_Case_Id);
        END IF;

        IF v_Task_Id IS NOT NULL THEN
            INSERT INTO tbl_doc_docTask (col_DocTaskDocument, col_DocTaskTask) VALUES (v_id, v_Task_Id);
        END IF;

        IF v_ExtParty_Id IS NOT NULL THEN
            INSERT INTO tbl_doc_docExtPrt (col_docextprtdoc, col_docextprtextprt) VALUES (v_id, v_ExtParty_Id);
        END IF;

        INSERT INTO TBL_EMAIL_WORKITEM_EXT (
            COL_EMAIL_WI_PI_WORKITEM,
            COL_EMAIL_WORKITEM_EXTCASE,
            col_parentwi,
            col_emailtype,
            col_replaywi
        ) VALUES (
            v_workitemId,
            v_Case_Id,
            v_WI_Parent,
            'REPLY',
            :WORKITEMID
        );

        v_res := f_PI_WorkitemRouteManualFn(
                ErrorCode    => v_errorcode,
                ErrorMessage => v_errormessage,
                Target       => v_NextActivity,
                WorkitemId   => v_workitemId);

        Begin
            Select
                s.col_activity
            Into
                v_NextActivity
            From tbl_dict_state s
                inner join tbl_dict_stateconfig sc on sc.col_id = s.COL_STATESTATECONFIG
                inner join tbl_dict_casestate cs on cs.col_id = s.COL_STATECASESTATE
                left join tbl_dict_stateconfigtype sct on sct.col_id = sc.COL_STATECONFSTATECONFTYPE
            Where sct.col_code = 'DOCUMENT'
                and sc.col_iscurrent = 1
                and cs.COL_ISFINISH = 1;
        Exception
            When OTHERS Then
              v_errorCode    := 104;
              v_errorMessage := 'State Id or Current Activity is absent';
              GOTO cleanup;
        End;

        v_res := f_PI_WorkitemRouteManualFn(
                ErrorCode    => v_errorcode,
                ErrorMessage => v_errormessage,
                Target       => v_NextActivity,
                WorkitemId   => v_workitemId);

    :AffectedRows := SQL%ROWCOUNT;
    :RecordId     := v_id;
    :DocId        := v_id;

  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 105;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 106;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;