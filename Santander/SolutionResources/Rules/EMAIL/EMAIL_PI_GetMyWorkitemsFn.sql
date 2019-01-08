DECLARE
  v_workbasketId     NUMBER;
  v_searchCode       NVARCHAR2(255);
  v_totalCount       NUMBER;
  v_selectClause     VARCHAR2(32767);
  v_selectClause2    VARCHAR2(32767);
  v_fromClause       VARCHAR2(32767);
  v_countClause      VARCHAR2(32767);
  v_sortClause       VARCHAR2(32767);
  v_sortSelectClause VARCHAR2(32767);
  v_pageWhereClause  VARCHAR2(32767);
  v_countQuery       VARCHAR2(32767);
  v_mainQuery        VARCHAR2(32767);
  v_LIMIT            NUMBER;
  v_START            NUMBER;
  v_sort             NVARCHAR2(255);
  v_dir              NVARCHAR2(255);
  v_id               NUMBER;
  v_workitemId       NUMBER;
  v_name             NVARCHAR2(255);
  v_title            NVARCHAR2(255);
  v_sourceType       NUMBER;
  v_createdStart     DATE;
  v_createdEnd       DATE;
  v_stateConfigId    NUMBER;
  v_stateCode        NVARCHAR2(255);
  v_stateId          NUMBER;
  v_from             NVARCHAR2(255);
  v_customer         NUMBER;
  v_owner            NUMBER;

BEGIN
  v_workbasketId := :workbasketId;
  v_searchCode   := :searchCode;
  v_stateCode    := :stateCode;
  v_dir          := :DIR;
  v_sort         := :SORT;
  v_LIMIT        := :LIMIT;
  v_START        := :FIRST;

  -- search fields
  v_id           := :Id;
  v_name         := :NAME;
  v_title        := :Title;
  v_sourceType   := :sourceType;
  v_createdStart := :createdStart;
  v_createdEnd   := :createdEnd;
  v_workitemId   := :WorkitemId;
  v_from         := :EmailFrom;
  v_customer     := :Customer;
  v_owner        := :Owner;

  IF (v_searchCode IS NULL) THEN
    v_searchCode := 'ALL';
  END IF;
  IF nvl(v_LIMIT, 0) = 0 THEN
    v_LIMIT := 1;
  END IF;
  IF v_START IS NULL THEN
    v_START := 0;
  END IF;

  IF (v_dir IS NULL) THEN
    v_dir := 'ASC';
  END IF;
  IF (v_sort IS NULL) THEN
    v_sort := 'ID';
  END IF;

  BEGIN
    SELECT sc.col_Id
      INTO v_stateConfigId
      FROM tbl_DICT_StateConfig sc
     INNER JOIN tbl_DICT_StateConfigType sct
        ON sct.col_Id = sc.col_StateConfStateConfType
       AND sct.col_Code = 'DOCUMENT'
     WHERE sc.col_IsCurrent = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_stateConfigId := NULL;
  END;

  BEGIN
    SELECT st.col_id
      INTO v_stateId
      FROM TBL_DICT_STATE st
     WHERE col_code = v_stateCode
       AND col_statestateconfig = v_stateConfigId;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_stateId := NULL;
  END;

  v_selectclause := 'SELECT
          wi.col_id as Id,
          wi.col_code as Code,
          wi.col_name as Name,
          wi.col_title as Title,
          wi.col_createddate AS CreatedDate,
          f_UTIL_getDrtnFrmNow(wi.col_createddate) AS CreatedDuration,
          extractValue(c.col_customdata, ''/CONTENT/FROM'') as SourceFrom,
          extractValue(c.col_customdata, ''/CONTENT/HEADER_From'') as SourceNameFrom,
          extractValue(c.col_customdata, ''/CONTENT/TO'') as SourceTo,
          wi_ext.COL_EMAILTYPE      AS EMAILTYPE,
          ep.COL_ID as EP_ID,
          ep.COL_NAME as EP_NAME,
          wbs.calcname as Workbasket_name,
          ct.col_name as SourceType,
          ct.col_id as SourceTypeId,
          st.col_id 				AS State_id,
          st.col_name 				AS State_Name,
          st.col_code 				AS State_Code,
          st.col_iconcode 			AS State_Icon,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''VIEW'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as ViewAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''DOWNLOAD'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as DownloadAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''PRINT'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as PrintAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''ASSIGN_TO_ME'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as AssignToMeAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''RE_ASSIGN'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as ReAssignAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''MODIFY_DATA'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as ModifyDataAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''ASSIGN_BACK'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as AssignBackAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''CREATE_CASE'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as CreateCaseAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''ATTACH_TO_CASE'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as AttachToCaseAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''DUPLICATE'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as DuplicateAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''TRASH'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as TrashAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''UNTRASH'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as NotTrashAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => wi.col_isdeleted, PermissionCode => ''PERMANENT_DELETE'', WorkbasketId => wi.col_pi_workitemppl_workbasket) as PermanentDeleteAction';

  v_selectclause2 := 'SELECT
          wi.col_id as Id,
          wi.col_code as Code,
          wi.col_name as Name,
          wi.col_title as Title,
          wi.col_createddate AS CreatedDate,
          f_UTIL_getDrtnFrmNow(wi.col_createddate) AS CreatedDuration,
          extractValue(c.col_customdata, ''/CONTENT/FROM'') as SourceFrom,
          extractValue(c.col_customdata, ''/CONTENT/HEADER_From'') as SourceNameFrom,
          extractValue(c.col_customdata, ''/CONTENT/TO'') as SourceTo,
          wi_ext.COL_EMAILTYPE      AS EMAILTYPE,
          ep.COL_ID as EP_ID,
          ep.COL_NAME as EP_NAME,
          wbs.calcname as Workbasket_name,
          ct.col_name as SourceType,
          ct.col_id as SourceTypeId,
          st.col_id 				AS State_id,
          st.col_name 				AS State_Name,
          st.col_code 				AS State_Code,
          st.col_iconcode 			AS State_Icon';

  IF v_workitemId IS NOT NULL THEN
    v_selectclause := 'SELECT
          Id as Id,
          Code as Code,
          Name as Name,
          Title as Title,
          CreatedDate AS CreatedDate,
          CreatedDuration AS CreatedDuration,
          SourceFrom AS SourceFrom,
          SourceNameFrom AS SourceNameFrom,
          SourceTo AS SourceTo,
          EMAILTYPE AS EMAILTYPE,
          EP_ID as EP_ID,
          EP_NAME as EP_NAME,
          Workbasket_name AS Workbasket_name,
          SourceType as SourceType,
          SourceTypeId as SourceTypeId,
          State_Id AS State_id,
          State_Name AS State_Name,
          State_Code AS State_Code,
          State_Icon AS State_Icon,
          CASE
              WHEN ((
                    SELECT COUNT(*) c FROM (
                        SELECT wiExt.COL_ID FROM TBL_EMAIL_WORKITEM_EXT wiExt WHERE wiExt.col_ParentWI = ' || v_workitemId || '
                        UNION ALL
                        SELECT wiExt.COL_ID FROM TBL_EMAIL_WORKITEM_EXT wiExt WHERE wiExt.COL_EMAIL_WI_PI_WORKITEM = ' || v_workitemId || ' AND wiExt.col_ParentWI IS NOT NULL
                    )
              ) < 1)
              THEN 1
              ELSE 0
          END AS DetachAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''VIEW'', WorkbasketId => WIWorkbasket) as ViewAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''DOWNLOAD'', WorkbasketId => WIWorkbasket) as DownloadAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''PRINT'', WorkbasketId => WIWorkbasket) as PrintAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''ASSIGN_TO_ME'', WorkbasketId => WIWorkbasket) as AssignToMeAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''RE_ASSIGN'', WorkbasketId => WIWorkbasket) as ReAssignAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''MODIFY_DATA'', WorkbasketId => WIWorkbasket) as ModifyDataAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''ASSIGN_BACK'', WorkbasketId => WIWorkbasket) as AssignBackAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''CREATE_CASE'', WorkbasketId => WIWorkbasket) as CreateCaseAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''ATTACH_TO_CASE'', WorkbasketId => WIWorkbasket) as AttachToCaseAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''DUPLICATE'', WorkbasketId => WIWorkbasket) as DuplicateAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''TRASH'', WorkbasketId => WIWorkbasket) as TrashAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''UNTRASH'', WorkbasketId => WIWorkbasket) as NotTrashAction,
          f_DCM_getPIWorkitemAccessFn (IsDeleted => WIIsDeleted, PermissionCode => ''PERMANENT_DELETE'', WorkbasketId => WIWorkbasket) as PermanentDeleteAction';

    v_selectclause := v_selectclause || ',
          PrimDocId AS PrimDocId,
          PrimDocCalcParentId	AS PrimDocCalcParentId,
          PrimDocName	AS PrimDocName,
          Url AS Url,
          PdfUrl AS PdfUrl,
          HtmlUrl AS HtmlUrl,
          PrimDocDescription AS PrimDocDescription,
          PrimDocDocTypeId AS PrimDocDocTypeId,
          PrimDocDocType AS PrimDocDocType,
          PrimDocIsDeleted AS PrimDocIsDeleted,
          IsGlobalResource AS IsGlobalResource,
          PrimDocCustomData AS PrimDocCustomData,
          PrimDocCreatedBy_Name AS PrimDocCreatedBy_Name,
          PrimDocCreatedDuration AS PrimDocCreatedDuration,
          ModifiedBy_Name AS ModifiedBy_Name,
          ModifiedDuration AS ModifiedDuration,
          Workbasket_id AS Workbasket_id,
          Workbasket_type_name AS Workbasket_type_name,
          Workbasket_type_code AS Workbasket_type_code,
          PrevWorkbasket_id AS PrevWorkbasket_id,
          PrevWorkbasket_name AS PrevWorkbasket_name,
          PrevWorkbasket_type_name AS PrevWorkbasket_type_name,
          PrevWorkbasket_type_code AS PrevWorkbasket_type_code';
  v_fromclause := ' FROM (SELECT wi.col_id AS Id, wi.col_code AS Code, wi.col_name AS Name, wi.col_title as Title, wi.col_createddate as CreatedDate,
      wi.col_isdeleted as WIIsDeleted, wi.col_pi_workitemppl_workbasket as WIWorkbasket,
      f_UTIL_getDrtnFrmNow(wi.col_createddate) AS CreatedDuration,
      extractValue(c.col_customdata, ''/CONTENT/FROM'') as SourceFrom,
      extractValue(c.col_customdata, ''/CONTENT/HEADER_From'') as SourceNameFrom,
      extractValue(c.col_customdata, ''/CONTENT/TO'') as SourceTo,
      wi_ext.COL_EMAILTYPE      AS EMAILTYPE,
      ep.COL_ID as EP_ID,
      ep.COL_NAME as EP_NAME,
      wbs.calcname as Workbasket_name, ct.col_name as SourceType, ct.col_id as SourceTypeId,
      st.col_id AS State_id, st.col_name AS State_Name, st.col_code AS State_Code, st.col_iconcode AS State_Icon,
      pdoc.col_id AS PrimDocId, pdoc.col_parentId AS PrimDocCalcParentId, pdoc.col_name AS PrimDocName,
      pdoc.col_url AS Url, pdoc.col_pdfurl AS PdfUrl, phtml.col_url AS HtmlUrl, pdoc.col_description AS PrimDocDescription,
      dt.col_id AS PrimDocDocTypeId, dt.col_name AS PrimDocDocType, pdoc.col_isdeleted AS PrimDocIsDeleted, NVL(pdoc.col_IsGlobalResource, 0) AS IsGlobalResource,
      dbms_xmlgen.CONVERT(pdoc.col_CustomData.getClobVal()) AS PrimDocCustomData,
      f_getNameFromAccessSubject (pdoc.col_createdBy) AS PrimDocCreatedBy_Name,
      f_UTIL_getDrtnFrmNow (pdoc.col_createdDate) AS PrimDocCreatedDuration,
      f_getNameFromAccessSubject (pdoc.col_modifiedBy) AS ModifiedBy_Name,
      f_UTIL_getDrtnFrmNow (pdoc.col_modifiedDate) AS ModifiedDuration,
      wbs.id                        AS Workbasket_id,
      wbs.workbaskettype_name       AS Workbasket_type_name,
      wbs.workbaskettype_code       AS Workbasket_type_code,
      pwbs.id                       AS PrevWorkbasket_id,
      pwbs.calcname                 AS PrevWorkbasket_name,
      pwbs.workbaskettype_name      AS PrevWorkbasket_type_name,
      pwbs.workbaskettype_code      AS PrevWorkbasket_type_code
      FROM tbl_pi_workitem wi
			INNER JOIN vw_ppl_simpleworkbasketext wbs ON wi.COL_PI_WORKITEMPPL_WORKBASKET = wbs.col_id
			INNER JOIN tbl_DICT_State st ON st.col_id = wi.col_pi_workitemdict_state AND st.col_StateStateConfig = ' || to_char(v_stateConfigId) || '
			INNER JOIN vw_ppl_simpleworkbasketext pwbs ON pwbs.id = wi.col_pi_workitemprevworkbasket
			LEFT JOIN tbl_doc_document pdoc ON pdoc.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id AND pdoc.col_isprimary = 1
			LEFT JOIN tbl_container c ON pdoc.COL_DOC_DOCUMENTCONTAINER = c.col_id
			LEFT JOIN TBL_EXTERNALPARTY ep ON TRIM(UPPER(extractValue(c.col_customdata, ''/CONTENT/FROM''))) = TRIM(UPPER(ep.COL_EMAIL))
			LEFT JOIN tbl_dict_containertype ct ON c.COL_CONTAINERCONTAINERTYPE = ct.COL_ID
			LEFT JOIN tbl_DICT_DocumentType dt ON dt.col_id = pdoc.col_DocType
			LEFT JOIN tbl_dict_systemtype thtml ON thtml.col_code = ''EMAIL_HTML''
			LEFT JOIN tbl_doc_document phtml ON phtml.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id AND phtml.col_doc_documentsystemtype = thtml.col_id
			LEFT JOIN TBL_EMAIL_WORKITEM_EXT wi_ext ON wi.col_id = wi_ext.COL_EMAIL_WI_PI_WORKITEM
			WHERE wi.col_id =  ' || TO_CHAR(v_workitemId) || '
      UNION ALL
      SELECT wi.col_id AS Id, wi.col_code AS Code, wi.col_name AS Name, wi.col_title as Title, wi.col_createddate as CreatedDate,
      wi.col_isdeleted as WIIsDeleted, wi.col_pi_workitemppl_workbasket as WIWorkbasket,
      f_UTIL_getDrtnFrmNow(wi.col_createddate) AS CreatedDuration,
      extractValue(c.col_customdata, ''/CONTENT/FROM'') as SourceFrom,
      extractValue(c.col_customdata, ''/CONTENT/HEADER_From'') as SourceNameFrom,
      extractValue(c.col_customdata, ''/CONTENT/TO'') as SourceTo,
      wi_ext.COL_EMAILTYPE      AS EMAILTYPE,
      ep.COL_ID as EP_ID,
      ep.COL_NAME as EP_NAME,
      wbs.calcname as Workbasket_name, ct.col_name as SourceType, ct.col_id as SourceTypeId,
      st.col_id AS State_id, st.col_name AS State_Name, st.col_code AS State_Code, st.col_iconcode AS State_Icon,
      pdoc.col_id AS PrimDocId, pdoc.col_parentId AS PrimDocCalcParentId, pdoc.col_name AS PrimDocName,
      pdoc.col_url AS Url, pdoc.col_pdfurl AS PdfUrl, phtml.col_url AS HtmlUrl, pdoc.col_description AS PrimDocDescription,
      dt.col_id AS PrimDocDocTypeId, dt.col_name AS PrimDocDocType, pdoc.col_isdeleted AS PrimDocIsDeleted, NVL(pdoc.col_IsGlobalResource, 0) AS IsGlobalResource,
      dbms_xmlgen.CONVERT(pdoc.col_CustomData.getClobVal()) AS PrimDocCustomData,
      f_getNameFromAccessSubject (pdoc.col_createdBy) AS PrimDocCreatedBy_Name,
      f_UTIL_getDrtnFrmNow (pdoc.col_createdDate) AS PrimDocCreatedDuration,
      f_getNameFromAccessSubject (pdoc.col_modifiedBy) AS ModifiedBy_Name,
      f_UTIL_getDrtnFrmNow (pdoc.col_modifiedDate) AS ModifiedDuration,
      wbs.id                        AS Workbasket_id,
      wbs.workbaskettype_name       AS Workbasket_type_name,
      wbs.workbaskettype_code       AS Workbasket_type_code,
      null                          AS PrevWorkbasket_id,
      null                          AS PrevWorkbasket_name,
      null                          AS PrevWorkbasket_type_name,
      null                          AS PrevWorkbasket_type_code
      FROM tbl_pi_workitem wi
			INNER JOIN vw_ppl_simpleworkbasketext wbs ON wi.COL_PI_WORKITEMPPL_WORKBASKET = wbs.col_id
			INNER JOIN tbl_DICT_State st ON st.col_id = wi.col_pi_workitemdict_state AND st.col_StateStateConfig = ' || to_char(v_stateConfigId) || '
			LEFT JOIN tbl_doc_document pdoc ON pdoc.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id AND pdoc.col_isprimary = 1
			LEFT JOIN tbl_container c ON pdoc.COL_DOC_DOCUMENTCONTAINER = c.col_id
			LEFT JOIN TBL_EXTERNALPARTY ep ON TRIM(UPPER(extractValue(c.col_customdata, ''/CONTENT/FROM''))) = TRIM(UPPER(ep.COL_EMAIL))
			LEFT JOIN tbl_dict_containertype ct ON c.COL_CONTAINERCONTAINERTYPE = ct.COL_ID
			LEFT JOIN tbl_DICT_DocumentType dt ON dt.col_id = pdoc.col_DocType
			LEFT JOIN tbl_dict_systemtype thtml ON thtml.col_code = ''EMAIL_HTML''
			LEFT JOIN tbl_doc_document phtml ON phtml.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id AND phtml.col_doc_documentsystemtype = thtml.col_id
			LEFT JOIN TBL_EMAIL_WORKITEM_EXT wi_ext ON wi.col_id = wi_ext.COL_EMAIL_WI_PI_WORKITEM
			WHERE wi.col_id =  ' || TO_CHAR(v_workitemId) || ' AND wi.col_pi_workitemprevworkbasket is null )';

  ELSIF v_workbasketId IS NOT NULL THEN
    v_fromclause := ' FROM tbl_pi_workitem wi
    INNER JOIN vw_ppl_simpleworkbasketext wbs on wi.COL_PI_WORKITEMPPL_WORKBASKET = wbs.col_id
    INNER JOIN tbl_DICT_State st ON st.col_id = wi.col_pi_workitemdict_state AND st.col_StateStateConfig = ' ||
                    to_char(v_stateConfigId) || ' AND st.col_id = ' || to_char(v_stateId) || '
    LEFT JOIN tbl_doc_document pdoc on pdoc.col_isprimary = 1 AND pdoc.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id
    LEFT JOIN tbl_container c on pdoc.COL_DOC_DOCUMENTCONTAINER = c.col_id
    LEFT JOIN TBL_EXTERNALPARTY ep ON TRIM(UPPER(extractValue(c.col_customdata, ''/CONTENT/FROM''))) = TRIM(UPPER(ep.COL_EMAIL))
    LEFT JOIN tbl_dict_containertype ct on c.COL_CONTAINERCONTAINERTYPE = ct.COL_ID
    LEFT JOIN TBL_EMAIL_WORKITEM_EXT wi_ext ON wi.col_id = wi_ext.COL_EMAIL_WI_PI_WORKITEM
    WHERE (nvl(wi.col_IsDeleted,0) = 0)
      AND col_pi_workitemppl_workbasket =  ' || TO_CHAR(v_workbasketId);

  ELSIF v_searchCode = 'ALL' THEN
    v_fromclause := ' FROM tbl_pi_workitem wi
    INNER JOIN vw_PPL_SimpleWorkbasketExt wbs on wi.COL_PI_WORKITEMPPL_WORKBASKET = wbs.id
    INNER JOIN tbl_DICT_State st ON st.col_id = ' || to_char(v_stateId) ||
                    ' and st.col_id = wi.col_pi_workitemdict_state
    LEFT JOIN vw_ppl_activecaseworkersusers cwu0 ON cwu0.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND wbs.CASEWORKER_ID = cwu0.id
    LEFT JOIN TBL_EMAIL_WORKITEM_EXT wi_ext ON wi.col_id = wi_ext.COL_EMAIL_WI_PI_WORKITEM
    LEFT JOIN
    (SELECT mwbcw1.col_map_wb_cw_workbasket as workbasket, cwu1.id as Id, cwu1.accode as accode
    FROM tbl_map_workbasketcaseworker mwbcw1
    INNER JOIN vw_ppl_activecaseworkersusers cwu1 ON cwu1.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu1.id = mwbcw1.col_map_wb_cw_caseworker
    UNION
    SELECT mwbbr3.col_map_wb_br_workbasket as workbasket, cwu3.Id as Id, cwu3.accode as accode
    FROM tbl_map_workbasketbusnessrole mwbbr3
    INNER JOIN tbl_caseworkerbusinessrole cwbr3 ON cwbr3.col_tbl_ppl_businessrole = mwbbr3.col_map_wb_wr_businessrole
    INNER JOIN vw_ppl_activecaseworkersusers cwu3 ON cwu3.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu3.id = cwbr3.col_br_ppl_caseworker
    UNION
    SELECT wbs.id as workbasket, cwu3.Id as Id, cwu3.accode as accode
    from vw_PPL_SimpleWorkbasketExt wbs
    INNER JOIN tbl_map_workbasketbusnessrole mwbbr3 ON mwbbr3.col_map_wb_wr_businessrole = wbs.BusinessRole_Id
    INNER JOIN tbl_caseworkerbusinessrole cwbr3 ON cwbr3.col_tbl_ppl_businessrole = wbs.BusinessRole_Id
    INNER JOIN vw_ppl_activecaseworkersusers cwu3 ON cwu3.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu3.id = cwbr3.col_br_ppl_caseworker
    UNION
    SELECT mwbtm4.col_map_wb_tm_workbasket as workbasket, cwu4.id as Id, cwu4.accode as accode
    FROM tbl_map_workbasketteam mwbtm4
    INNER JOIN tbl_caseworkerteam cwtm4 ON cwtm4.col_tbl_ppl_team = mwbtm4.col_map_wb_tm_team
    INNER JOIN vw_ppl_activecaseworkersusers cwu4 ON cwu4.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu4.id = cwtm4.col_tm_ppl_caseworker
    UNION
    SELECT wbs.id as workbasket, cwu4.id as Id, cwu4.accode as accode
    from vw_PPL_SimpleWorkbasketExt wbs
    INNER JOIN tbl_map_workbasketteam mwbtm4 ON mwbtm4.col_map_wb_tm_team = wbs.Team_Id
    INNER JOIN tbl_caseworkerteam cwtm4 ON cwtm4.COL_TBL_PPL_TEAM = wbs.Team_Id
    INNER JOIN vw_ppl_activecaseworkersusers cwu4 ON cwu4.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu4.id = cwtm4.col_tm_ppl_caseworker
    UNION
    SELECT mwsk5.col_map_ws_workbasket as workbasket, cwu5.id as Id, cwu5.accode as accode
    FROM tbl_map_workbasketskill mwsk5
    INNER JOIN tbl_caseworkerskill cwsk5 on cwsk5.col_tbl_ppl_skill = mwsk5.col_map_ws_skill
    INNER JOIN vw_ppl_activecaseworkersusers cwu5 ON cwu5.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker
    UNION
    SELECT wbs.id as workbasket, cwu5.id as Id, cwu5.accode as accode
    from vw_PPL_SimpleWorkbasketExt wbs
    INNER JOIN tbl_map_workbasketskill mwsk5 ON mwsk5.col_map_ws_skill = wbs.Skill_Id
    INNER JOIN tbl_caseworkerskill cwsk5 on cwsk5.col_tbl_ppl_skill = wbs.Skill_Id
    INNER JOIN vw_ppl_activecaseworkersusers cwu5 ON cwu5.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker
    ) s1 ON s1.workbasket = wbs.id
    LEFT JOIN tbl_doc_document pdoc on pdoc.col_isprimary = 1 AND pdoc.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id
    LEFT JOIN tbl_container c on pdoc.COL_DOC_DOCUMENTCONTAINER = c.col_id
    LEFT JOIN TBL_EXTERNALPARTY ep ON TRIM(UPPER(extractValue(c.col_customdata, ''/CONTENT/FROM''))) = TRIM(UPPER(ep.COL_EMAIL))
    LEFT JOIN tbl_dict_containertype ct on c.COL_CONTAINERCONTAINERTYPE = ct.COL_ID
    WHERE (nvl(wi.col_IsDeleted,0) = 0)
      AND Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') IN (cwu0.accode, s1.accode)';

  ELSIF v_searchCode = 'TRASH' THEN
    v_fromclause := ' FROM tbl_pi_workitem wi
    INNER JOIN vw_PPL_SimpleWorkbasketExt wbs on wi.COL_PI_WORKITEMPPL_WORKBASKET = wbs.id
    INNER JOIN tbl_DICT_State st ON st.col_id = ' || to_char(v_stateId) ||
                    ' and st.col_id = wi.col_pi_workitemdict_state
    LEFT JOIN vw_ppl_activecaseworkersusers cwu0 ON cwu0.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND wbs.CASEWORKER_ID = cwu0.id
    LEFT JOIN TBL_EMAIL_WORKITEM_EXT wi_ext ON wi.col_id = wi_ext.COL_EMAIL_WI_PI_WORKITEM
    LEFT JOIN
    (SELECT mwbcw1.col_map_wb_cw_workbasket as workbasket, cwu1.id as Id, cwu1.accode as accode
    FROM tbl_map_workbasketcaseworker mwbcw1
    INNER JOIN vw_ppl_activecaseworkersusers cwu1 ON cwu1.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu1.id = mwbcw1.col_map_wb_cw_caseworker
    UNION
    SELECT mwbbr3.col_map_wb_br_workbasket as workbasket, cwu3.Id as Id, cwu3.accode as accode
    FROM tbl_map_workbasketbusnessrole mwbbr3
    INNER JOIN tbl_caseworkerbusinessrole cwbr3 ON cwbr3.col_tbl_ppl_businessrole = mwbbr3.col_map_wb_wr_businessrole
    INNER JOIN vw_ppl_activecaseworkersusers cwu3 ON cwu3.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu3.id = cwbr3.col_br_ppl_caseworker
    UNION
    SELECT wbs.id as workbasket, cwu3.Id as Id, cwu3.accode as accode
    from vw_PPL_SimpleWorkbasketExt wbs
    INNER JOIN tbl_map_workbasketbusnessrole mwbbr3 ON mwbbr3.col_map_wb_wr_businessrole = wbs.BusinessRole_Id
    INNER JOIN tbl_caseworkerbusinessrole cwbr3 ON cwbr3.col_tbl_ppl_businessrole = wbs.BusinessRole_Id
    INNER JOIN vw_ppl_activecaseworkersusers cwu3 ON cwu3.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu3.id = cwbr3.col_br_ppl_caseworker
    UNION
    SELECT mwbtm4.col_map_wb_tm_workbasket as workbasket, cwu4.id as Id, cwu4.accode as accode
    FROM tbl_map_workbasketteam mwbtm4
    INNER JOIN tbl_caseworkerteam cwtm4 ON cwtm4.col_tbl_ppl_team = mwbtm4.col_map_wb_tm_team
    INNER JOIN vw_ppl_activecaseworkersusers cwu4 ON cwu4.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu4.id = cwtm4.col_tm_ppl_caseworker
    UNION
    SELECT wbs.id as workbasket, cwu4.id as Id, cwu4.accode as accode
    from vw_PPL_SimpleWorkbasketExt wbs
    INNER JOIN tbl_map_workbasketteam mwbtm4 ON mwbtm4.col_map_wb_tm_team = wbs.Team_Id
    INNER JOIN tbl_caseworkerteam cwtm4 ON cwtm4.COL_TBL_PPL_TEAM = wbs.Team_Id
    INNER JOIN vw_ppl_activecaseworkersusers cwu4 ON cwu4.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu4.id = cwtm4.col_tm_ppl_caseworker
    UNION
    SELECT mwsk5.col_map_ws_workbasket as workbasket, cwu5.id as Id, cwu5.accode as accode
    FROM tbl_map_workbasketskill mwsk5
    INNER JOIN tbl_caseworkerskill cwsk5 on cwsk5.col_tbl_ppl_skill = mwsk5.col_map_ws_skill
    INNER JOIN vw_ppl_activecaseworkersusers cwu5 ON cwu5.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker
    UNION
    SELECT wbs.id as workbasket, cwu5.id as Id, cwu5.accode as accode
    from vw_PPL_SimpleWorkbasketExt wbs
    INNER JOIN tbl_map_workbasketskill mwsk5 ON mwsk5.col_map_ws_skill = wbs.Skill_Id
    INNER JOIN tbl_caseworkerskill cwsk5 on cwsk5.col_tbl_ppl_skill = wbs.Skill_Id
    INNER JOIN vw_ppl_activecaseworkersusers cwu5 ON cwu5.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker
    ) s1 ON s1.workbasket = wbs.id
    LEFT JOIN tbl_doc_document pdoc on pdoc.col_isprimary = 1 AND pdoc.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id
    LEFT JOIN tbl_container c on pdoc.COL_DOC_DOCUMENTCONTAINER = c.col_id
    LEFT JOIN TBL_EXTERNALPARTY ep ON TRIM(UPPER(extractValue(c.col_customdata, ''/CONTENT/FROM''))) = TRIM(UPPER(ep.COL_EMAIL))
    LEFT JOIN tbl_dict_containertype ct on c.COL_CONTAINERCONTAINERTYPE = ct.COL_ID
    WHERE (nvl(wi.col_IsDeleted,0) = 1)
      AND Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') IN (cwu0.accode, s1.accode)';

  ELSIF v_searchCode = 'ALL_SHARED' THEN
    v_fromclause := ' FROM tbl_pi_workitem wi
    INNER JOIN vw_PPL_SimpleWorkbasketExt wbs on wi.COL_PI_WORKITEMPPL_WORKBASKET = wbs.id
    INNER JOIN tbl_DICT_State st ON st.col_id = ' || to_char(v_stateId) ||
                    ' and st.col_id = wi.col_pi_workitemdict_state
    LEFT JOIN TBL_EMAIL_WORKITEM_EXT wi_ext ON wi.col_id = wi_ext.COL_EMAIL_WI_PI_WORKITEM
    LEFT JOIN
    (SELECT mwbcw1.col_map_wb_cw_workbasket as workbasket, cwu1.id as Id, cwu1.accode as accode
    FROM tbl_map_workbasketcaseworker mwbcw1
    INNER JOIN vw_ppl_activecaseworkersusers cwu1 ON cwu1.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu1.id = mwbcw1.col_map_wb_cw_caseworker
    UNION
    SELECT mwbbr3.col_map_wb_br_workbasket as workbasket, cwu3.Id as Id, cwu3.accode as accode
    FROM tbl_map_workbasketbusnessrole mwbbr3
    INNER JOIN tbl_caseworkerbusinessrole cwbr3 ON cwbr3.col_tbl_ppl_businessrole = mwbbr3.col_map_wb_wr_businessrole
    INNER JOIN vw_ppl_activecaseworkersusers cwu3 ON cwu3.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu3.id = cwbr3.col_br_ppl_caseworker
    UNION
    SELECT wbs.id as workbasket, cwu3.Id as Id, cwu3.accode as accode
    from vw_PPL_SimpleWorkbasketExt wbs
    INNER JOIN tbl_map_workbasketbusnessrole mwbbr3 ON mwbbr3.col_map_wb_wr_businessrole = wbs.BusinessRole_Id
    INNER JOIN tbl_caseworkerbusinessrole cwbr3 ON cwbr3.col_tbl_ppl_businessrole = wbs.BusinessRole_Id
    INNER JOIN vw_ppl_activecaseworkersusers cwu3 ON cwu3.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu3.id = cwbr3.col_br_ppl_caseworker
    UNION
    SELECT mwbtm4.col_map_wb_tm_workbasket as workbasket, cwu4.id as Id, cwu4.accode as accode
    FROM tbl_map_workbasketteam mwbtm4
    INNER JOIN tbl_caseworkerteam cwtm4 ON cwtm4.col_tbl_ppl_team = mwbtm4.col_map_wb_tm_team
    INNER JOIN vw_ppl_activecaseworkersusers cwu4 ON cwu4.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu4.id = cwtm4.col_tm_ppl_caseworker
    UNION
    SELECT wbs.id as workbasket, cwu4.id as Id, cwu4.accode as accode
    from vw_PPL_SimpleWorkbasketExt wbs
    INNER JOIN tbl_map_workbasketteam mwbtm4 ON mwbtm4.col_map_wb_tm_team = wbs.Team_Id
    INNER JOIN tbl_caseworkerteam cwtm4 ON cwtm4.COL_TBL_PPL_TEAM = wbs.Team_Id
    INNER JOIN vw_ppl_activecaseworkersusers cwu4 ON cwu4.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu4.id = cwtm4.col_tm_ppl_caseworker
    UNION
    SELECT mwsk5.col_map_ws_workbasket as workbasket, cwu5.id as Id, cwu5.accode as accode
    FROM tbl_map_workbasketskill mwsk5
    INNER JOIN tbl_caseworkerskill cwsk5 on cwsk5.col_tbl_ppl_skill = mwsk5.col_map_ws_skill
    INNER JOIN vw_ppl_activecaseworkersusers cwu5 ON cwu5.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker
    UNION
    SELECT wbs.id as workbasket, cwu5.id as Id, cwu5.accode as accode
    from vw_PPL_SimpleWorkbasketExt wbs
    INNER JOIN tbl_map_workbasketskill mwsk5 ON mwsk5.col_map_ws_skill = wbs.Skill_Id
    INNER JOIN tbl_caseworkerskill cwsk5 on cwsk5.col_tbl_ppl_skill = wbs.Skill_Id
    INNER JOIN vw_ppl_activecaseworkersusers cwu5 ON cwu5.accode = Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker
    ) s1 ON s1.workbasket = wbs.id
    LEFT JOIN tbl_doc_document pdoc on pdoc.col_isprimary = 1 AND pdoc.COL_DOC_DOCUMENTPI_WORKITEM = wi.col_id
    LEFT JOIN tbl_container c on pdoc.COL_DOC_DOCUMENTCONTAINER = c.col_id
    LEFT JOIN TBL_EXTERNALPARTY ep ON TRIM(UPPER(extractValue(c.col_customdata, ''/CONTENT/FROM''))) = TRIM(UPPER(ep.COL_EMAIL))
    LEFT JOIN tbl_dict_containertype ct on c.COL_CONTAINERCONTAINERTYPE = ct.COL_ID
    WHERE (nvl(wi.col_IsDeleted,0) = 0)
      AND Sys_context(''CLIENTCONTEXT'', ''AccessSubject'') IN (s1.accode)';

  END IF;

  -- TotalCount
  v_countclause := 'SELECT count(*) ' || v_fromclause;

  -- filters
  IF (v_id IS NOT NULL) THEN
    v_pageWhereClause := v_pageWhereClause || ' AND wi.col_id = ' || to_char(v_id);
    v_countclause     := v_countclause || ' AND wi.col_id = ' || to_char(v_id);
  END IF;
  IF (v_name IS NOT NULL) THEN
    v_pageWhereClause := v_pageWhereClause || ' AND lower(wi.col_name) LIKE lower(''%' || v_name || '%'')';
    v_countclause     := v_countclause || ' AND lower(wi.col_name) LIKE lower(''%' || v_name || '%'')';
  END IF;
  IF (v_title IS NOT NULL) THEN
    v_pageWhereClause := v_pageWhereClause || ' AND lower(wi.col_title) LIKE lower(''%' || v_title || '%'')';
    v_countclause     := v_countclause || ' AND lower(wi.col_title) LIKE lower(''%' || v_title || '%'')';
  END IF;
  IF (v_sourceType IS NOT NULL) THEN
    v_pageWhereClause := v_pageWhereClause || ' AND ct.col_id = ' || to_char(v_sourceType);
    v_countclause     := v_countclause || ' AND ct.col_id = ' || to_char(v_sourceType);
  END IF;
  IF (v_createdStart IS NOT NULL) THEN
    v_pageWhereClause := v_pageWhereClause || ' AND trunc(wi.col_createddate) >= trunc(to_date(''' || to_char(v_createdStart) || '''))';
    v_countclause     := v_countclause || ' AND trunc(wi.col_createddate) >= trunc(to_date(''' || to_char(v_createdStart) || '''))';
  END IF;
  IF (v_createdEnd IS NOT NULL) THEN
    v_pageWhereClause := v_pageWhereClause || ' AND trunc(wi.col_createddate) <= trunc(to_date(''' || to_char(v_createdEnd) || '''))';
    v_countclause     := v_countclause || ' AND trunc(wi.col_createddate) <= trunc(to_date(''' || to_char(v_createdEnd) || '''))';
  END IF;
  IF (v_owner IS NOT NULL) THEN
    v_pageWhereClause := v_pageWhereClause || ' AND wi.COL_PI_WORKITEMPPL_WORKBASKET = ' || to_char(v_owner);
    v_countclause     := v_countclause || ' AND wi.COL_PI_WORKITEMPPL_WORKBASKET = ' || to_char(v_owner);
  END IF;
  IF (v_from IS NOT NULL) THEN
     v_pageWhereClause := v_pageWhereClause || ' AND extractValue(c.col_customdata, ''/CONTENT/FROM'') LIKE lower(''%' || v_from || '%'')';
     v_countclause     := v_countclause || ' AND extractValue(c.col_customdata, ''/CONTENT/FROM'') LIKE lower(''%' || v_from || '%'')';
  END IF;
  IF (v_customer IS NOT NULL) THEN
    v_pageWhereClause := v_pageWhereClause || ' AND ep.COL_ID = ' || to_char(v_customer);
    v_countclause     := v_countclause || ' AND ep.COL_ID = ' || to_char(v_customer);
  END IF;


  -- paging and sorting
  v_sortselectclause := '(SELECT ID FROM (SELECT ID,' || v_sort || ', rownum rn FROM (';
  IF (upper(v_sort) = 'ID') THEN
    v_sortselectclause := '(SELECT ID FROM (SELECT ID, rownum rn FROM (';
  END IF;

  if v_workitemid is null then
    v_fromclause := v_fromclause || ' AND wi.col_id in' || v_sortselectclause || v_selectclause2 || v_fromclause || v_pageWhereClause || ' ORDER BY ' ||
                    v_sort || ' ' || v_dir || ') v where rownum < ' || TO_CHAR(v_START + v_LIMIT + 1) || ') v2 where rn >= ' || TO_CHAR(v_START + 1) || ')';
  end if;

  --EXECUTE QUERY AND COUNT QUERY
  v_countquery := v_countclause;

  if v_workitemid is null then
    v_mainquery := v_selectclause || v_fromclause || ' ORDER BY ' || v_sort || ' ' || v_dir;
  else
    v_mainquery := v_selectclause || v_fromclause;
  end if;

  --DBMS_OUTPUT.NEW_LINE();
  --DBMS_OUTPUT.PUT_LINE(v_mainquery);
  --DBMS_OUTPUT.PUT_LINE(v_countquery);
  BEGIN
    EXECUTE IMMEDIATE v_countquery
      INTO :TotalCount;
  EXCEPTION
    WHEN OTHERS THEN
      :ErrorCode    := SQLCODE;
      :ErrorMessage := SUBSTR('Error in count query' || ': ' || SQLERRM, 1, 200);
  END;
  BEGIN
    OPEN :ITEMS FOR v_mainquery;
  EXCEPTION
    WHEN OTHERS THEN
      :ErrorCode    := SQLCODE;
      :ErrorMessage := SUBSTR('Error on search query' || ': ' || SQLERRM, 1, 200);
  END;

END;