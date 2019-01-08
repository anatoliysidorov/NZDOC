SELECT
        wi.col_id                                               AS Id,
        wi.col_code                                             AS Code,
        wi.col_name                                             AS Name,
        wi.col_title                                            AS Title,
        wi.col_createddate                                      AS CreatedDate,
        f_UTIL_getDrtnFrmNow(wi.col_createddate)                AS CreatedDuration,
        extractValue(c.col_customdata, '/CONTENT/FROM')         AS SourceFrom,
        extractValue(c.col_customdata, '/CONTENT/TO')           AS SourceTo,
        extractValue(c.col_customdata, '/CONTENT/HEADER_From')  AS SourceNameFrom,
        ep.COL_ID                                               AS EP_ID,
        ep.COL_NAME                                             AS EP_NAME,
        ct.col_name                                             AS SourceType,
        ct.col_id                                               AS SourceTypeId,
        st.col_id 				                                AS State_id,
        st.col_name 				                            AS State_Name,
        st.col_code                                             AS State_Code,
        CASE WHEN :ExternalPartyId IS NULL
             THEN wi_ext.col_ParentWI
        END                                                     AS CALCPARENTID,
        wi_ext.COL_EMAILTYPE                                    AS EMAILTYPE,
        wi_ext.COL_EMAIL_WORKITEM_EXTCASE                            AS CaseId,
        st.col_iconcode 			                            AS State_Icon/*,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'VIEW', WorkbasketId => wi.col_pi_workitemppl_workbasket) as ViewAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'DOWNLOAD', WorkbasketId => wi.col_pi_workitemppl_workbasket) as DownloadAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'PRINT', WorkbasketId => wi.col_pi_workitemppl_workbasket) as PrintAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'ASSIGN_TO_ME', WorkbasketId => wi.col_pi_workitemppl_workbasket) as AssignToMeAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'RE_ASSIGN', WorkbasketId => wi.col_pi_workitemppl_workbasket) as ReAssignAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'MODIFY_DATA', WorkbasketId => wi.col_pi_workitemppl_workbasket) as ModifyDataAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'ASSIGN_BACK', WorkbasketId => wi.col_pi_workitemppl_workbasket) as AssignBackAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'CREATE_CASE', WorkbasketId => wi.col_pi_workitemppl_workbasket) as CreateCaseAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'ATTACH_TO_CASE', WorkbasketId => wi.col_pi_workitemppl_workbasket) as AttachToCaseAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'DUPLICATE', WorkbasketId => wi.col_pi_workitemppl_workbasket) as DuplicateAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'TRASH', WorkbasketId => wi.col_pi_workitemppl_workbasket) as TrashAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'UNTRASH', WorkbasketId => wi.col_pi_workitemppl_workbasket) as NotTrashAction,
        f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => 'PERMANENT_DELETE', WorkbasketId => wi.col_pi_workitemppl_workbasket) as PermanentDeleteAction*/
FROM tbl_pi_workitem wi
        INNER JOIN tbl_DICT_State st ON st.col_id = wi.col_pi_workitemdict_state
        LEFT JOIN TBL_EMAIL_WORKITEM_EXT wi_ext ON wi.col_id = wi_ext.COL_EMAIL_WI_PI_WORKITEM
        LEFT JOIN tbl_doc_document pdoc on pdoc.col_isprimary = 1 AND pdoc.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id
        LEFT JOIN tbl_container c on pdoc.COL_DOC_DOCUMENTCONTAINER = c.col_id
        LEFT JOIN TBL_EXTERNALPARTY ep ON TRIM(UPPER(extractValue(c.col_customdata, '/CONTENT/FROM'))) = TRIM(UPPER(ep.COL_EMAIL))
        LEFT JOIN tbl_dict_containertype ct on c.COL_CONTAINERCONTAINERTYPE = ct.COL_ID
WHERE (nvl(wi.col_IsDeleted,0) = 0)
  AND (
        (:CaseId IS NULL OR wi_ext.COL_EMAIL_WORKITEM_EXTCASE = :CaseId)
    AND (:ExternalPartyId IS NULL OR ep.COL_ID = :ExternalPartyId)
    AND (:CaseId IS NOT NULL OR :ExternalPartyId IS NOT NULL)
  )
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>