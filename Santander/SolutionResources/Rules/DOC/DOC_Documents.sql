SELECT doc_doc.col_id AS id,
       doc_doc.col_parentId AS CalcParentId,
       doc_doc.col_isFolder AS IsFolder,
       doc_doc.col_name AS Name,
       doc_doc.col_isdeleted AS isDeleted,
       doc_doc.col_FolderOrder AS FolderOrder,
       doc_doc.col_URL AS URL,
       doc_doc.col_Description AS Description,
       doc_doc.col_CustomData AS CustomData,
       doc_doc.col_Doctype AS Doctype,
       dict_dt.col_name AS DoctypeName,
       doc_doc.col_createdby AS CreatedBy,
       doc_doc.col_createddate AS CreatedDate,
       doc_doc.col_modifiedby AS ModifiedBy,
       doc_doc.col_modifieddate AS ModifiedDate,
       doc_doc.col_IsGlobalResource AS IsGlobalResource,
       doc_doc.col_VersionIndex AS VersionIndex,
       doc_doc.col_doc_documentsystemtype AS DocSysTypeId,
       dict_st.col_code AS DocSysTypeCode,
       dict_st.col_name AS DocSysTypeName,
       doc_doc.col_doc_documentcontainer AS ContainerId,
       doc_doc.col_isprimary AS IsPrimary,
       -- linked IDs
       doc_DocCaseType.col_doccsetypetype AS CaseTypeId,
       doc_DocCase.col_doccasecase AS CaseId,
       doc_DocTask.col_doctasktask AS TaskId,
       doc_DocExtPrt.col_docextprtextprt AS ExtpartyId,
       doc_DocTeam.col_docteamteam AS TeamId,
       doc_DocCW.col_doccwcw AS CaseworkerId,
       -- container data
       cont.col_containercontainertype AS ContainerTypeId,
       dict_ct.col_code AS ContainerTypeCode,
       dict_ct.col_name AS ContainerTypeName,
       EXTRACTVALUE (cont.col_customdata, '/CONTENT/FROM') AS ContainerFrom,
       EXTRACTVALUE (cont.col_customdata, '/CONTENT/TO') AS ContainerTo,
       -- workitem data
       doc_doc.col_doc_documentpi_workitem AS WorkItemId,
       wi.col_pi_workitemppl_workbasket AS WorkbasketId
  FROM tbl_doc_document doc_doc
       --tables of links--
       LEFT JOIN tbl_doc_docCaseType doc_DocCaseType
          ON doc_doc.col_id = doc_DocCaseType.col_DocCseTypeDoc
       LEFT JOIN tbl_doc_docCase doc_DocCase
          ON doc_doc.col_id = doc_DocCase.col_DocCaseDocument
       LEFT JOIN tbl_doc_docTask doc_DocTask
          ON doc_doc.col_id = doc_DocTask.col_DocTaskDocument
       LEFT JOIN tbl_doc_docExtPrt doc_DocExtPrt
          ON doc_doc.col_id = doc_DocExtPrt.col_DocExtPrtDoc
       LEFT JOIN tbl_doc_docTeam doc_DocTeam
          ON doc_doc.col_id = doc_DocTeam.col_DocTeamDoc
       LEFT JOIN tbl_doc_DocCW doc_DocCW
          ON doc_doc.col_id = doc_DocCW.col_DocCWDoc
       LEFT JOIN tbl_dict_DocumentType dict_dt
          ON dict_dt.col_id = doc_doc.col_doctype
       LEFT JOIN tbl_Container cont
          ON cont.col_id = doc_doc.col_doc_documentcontainer
       LEFT JOIN tbl_dict_ContainerType dict_ct
          ON dict_ct.col_id = cont.col_containercontainertype
       LEFT JOIN tbl_dict_SystemType dict_st
          ON dict_st.col_id = doc_doc.col_doc_documentsystemtype
       LEFT JOIN tbl_PI_Workitem wi
          ON wi.col_id = doc_doc.col_doc_documentpi_workitem