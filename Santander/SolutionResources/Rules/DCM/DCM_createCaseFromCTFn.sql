declare	
  v_RecordIdExt Integer;
  v_CaseId Integer;
  v_CaseTypeId Integer;
  v_CaseTypeCode nvarchar2(255);
  v_ProcedureId Integer;
  v_ProcedureCode nvarchar2(255);
  v_col_CaseId nvarchar2(255);
  v_Priority Integer;
  v_Owner nvarchar2(255);
  v_Summary nvarchar2(255);
  v_OwnerWorkBasketId Integer;
  v_ResolveBy date;
  v_Description nclob;
  v_Result Integer;
  v_customdataprocessor nvarchar2(255);
  v_CustomData nclob;
  v_workbasket_name nvarchar2(255);
  v_ErrorCode Number;
  v_ErrorMessage nvarchar2(255);
  v_draft number;
  v_preventDocFolderCreate number;
  v_CaseFrom nvarchar2(255);
  v_Domain nvarchar2(255);
  ----------------------------------------
  v_DocumentsName NVARCHAR2(255);
  v_DocumentsURL NVARCHAR2(255);
  V_SV_URL NVARCHAR2(255);
  V_SV_FILENAME NVARCHAR2(255);
  v_parentfolder_id number;
  v_DebugSession nvarchar2(255);
  ----------------------------------------
  v_calc_caseid            INTEGER;
  v_calc_CaseTypeId    INTEGER;
  v_calc_taskid            INTEGER;
  v_CreateConfigCode  nvarchar2(255);
  v_CreateConfigId      INTEGER;
  v_CreateConfigName nvarchar2(255);
  v_CreateModelId       INTEGER;
  v_EditConfigCode      nvarchar2(255);
  v_EditConfigId          INTEGER;
  v_EditConfigName     nvarchar2(255);
  v_EditModelId           INTEGER;

  CURSOR urls( sv_urls IN NCLOB)
  IS
    SELECT * FROM TABLE(Asf_split(sv_urls, '|||'));
  CURSOR file_names( sv_names IN NCLOB)
  IS
    SELECT * FROM TABLE(Asf_split(sv_names, '|||'));

  begin
    --COMMON ATTRIBUTES
    v_CaseTypeId := :CASESYSTYPE_ID;
    v_CaseTypeCode := :CASESYSTYPE_CODE;
    v_ProcedureId := :PROCEDURE_ID;
    v_ProcedureCode := :PROCEDURE_CODE;
    v_CaseId := null;
    v_Priority := :PRIORITY_ID;
    v_Summary := :SUMMARY;
    v_OwnerWorkBasketId := :OWNER_WORKBASKET_ID;
    v_ResolveBy := :ResolveBy;
    v_Description := :DESCRIPTION;
    v_draft := :Draft;
  v_preventDocFolderCreate := NVL(:preventDocFolderCreate, 0);
    v_CustomData := :CUSTOMDATA;
  v_CaseFrom := NVL(:CaseFrom, 'main'); --options are either 'main' or 'portal'
    if v_CustomData is null then
      v_CustomData := '<CustomData><Attributes></Attributes></CustomData>';
    end if;
    v_ErrorCode := 0;
    v_ErrorMessage := '';
    :ErrorCode := 0;
    :ErrorMessage := '';
    v_Domain := f_UTIL_getDomainFn();

    --FIND USERACCESSSUBJECT
    begin
      select cwu.accode
        into   v_owner
        from   tbl_ppl_workbasket wb
               inner join vw_ppl_activecaseworker cw
                       on wb.col_caseworkerworkbasket = cw.col_id
               inner join vw_ppl_activecaseworkersusers cwu
                       on cw.col_id = cwu.id
        where  wb.col_id = v_ownerworkbasketid;
      exception
        when NO_DATA_FOUND then
          v_owner := null;
    end;
    if v_CaseTypeCode is not null then
      begin
        select col_id
          into v_CaseTypeId
          from tbl_dict_casesystype
          where col_code = v_CaseTypeCode;
        exception
          when NO_DATA_FOUND then
            v_CaseTypeId := null;
      end;
    end if;
    v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseTypeId, ProcedureId => null);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseFromCTFn begin', Message => 'Case is about to be created', Rule => 'DCM_createCaseFromCTFn', TaskId => null);
  
    --CREATE COMMON CASE
    v_Result := f_DCM_createCaseCommon(CaseId => v_col_CaseId,
                                                          CaseSysTypeId => v_CaseTypeId,
                                                          Description => v_Description,
                                                          Draft => v_draft,
                                                          ErrorCode => v_ErrorCode,
                                                          ErrorMessage => v_ErrorMessage,
                                                          Owner => v_Owner,
                                                          PriorityCase => v_Priority,
                                                          ProcedureId => v_ProcedureId,
                                                          recordid => v_CaseId,
                                                          ResolveBy => v_ResolveBy,
                                                          Summary => v_Summary,
                                                          TOKEN_DOMAIN => v_Domain,
                                                          TOKEN_USERACCESSSUBJECT => sys_context('CLIENTCONTEXT', 'AccessSubject'),
                                                          OwnerWorkBasketId=> v_OwnerWorkBasketId);
    v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseTypeId, ProcedureId => null);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseFromCTFn base case created in DCM_createCaseCommon',
                                     Message => 'Case ' || to_char(v_CaseId) || ' is created', Rule => 'DCM_createCaseFromCTFn', TaskId => null);

    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
    if nvl(v_ErrorCode,0) not in (0,200) then
      return -1;
    end if;
    v_result := f_DCM_copyCaseToCache(CaseId => v_CaseId);
                              
    --set custom data XML
    UPDATE TBL_CASEEXT SET col_customdata =  XMLTYPE(v_CustomData) WHERE COL_CASEEXTCASE = v_CaseId;   
                                 
    --CALL CUSTOM PROCESSOR IF ONE EXISTS
    BEGIN 
      SELECT col_customdataprocessor  INTO   v_customdataprocessor 
      FROM   TBL_DICT_CASESYSTYPE 
      WHERE  COL_ID = v_casetypeid; 
    EXCEPTION 
      WHEN no_data_found THEN 
        v_customdataprocessor := NULL; 
    END; 

    v_RecordIdExt := null;

    if v_customdataprocessor is not null then
      v_RecordIdExt := f_dcm_invokeCaseCusDataProc(CaseId => v_CaseId, Input => v_CustomData, ProcessorName => v_customdataprocessor);
      v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseTypeId, ProcedureId => null);    
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseFromCTFn custom data is created in ' || v_customdataprocessor,
                                      Message => 'Case ' || to_char(v_CaseId) || ' custom data is created', Rule => 'DCM_createCaseFromCTFn', TaskId => null);         
    end if;

  --ADD DOCUMENTS
    IF v_preventDocFolderCreate = 0 THEN
      if :DocumentsURLs IS NOT NULL AND :DocumentsNames IS NOT NULL THEN
        V_Parentfolder_Id := f_DOC_createDefaultDocFolder(CaseId => v_CaseId, DocFolderType => v_CaseFrom);

        OPEN urls(:DocumentsURLs);
        OPEN file_names(:DocumentsNames);
        LOOP
          FETCH urls INTO v_sv_url;
          FETCH file_names INTO v_sv_filename;
          EXIT
          WHEN urls%NOTFOUND;
          BEGIN
            v_Result      := f_doc_adddocfn(Name => v_sv_filename, 
                                             Description => null, 
                                             Url => v_sv_url,
                                             ScanLocation => null,
                                             DocId => v_result,
                                             DocTypeId => null,
                                             FolderId => V_Parentfolder_Id,
                                             CaseId => v_caseid,
                                             CaseTypeId => null,
                                             ErrorCode => v_ErrorCode,
                                             ErrorMessage => v_ErrorMessage );
            EXCEPTION
            WHEN OTHERS THEN
              :ErrorCode      := v_ErrorCode;
             IF(v_ErrorMessage = '')THEN
                v_ErrorMessage := 'During insert of the following records there were errors: ';
              END IF;
              :ErrorMessage := v_ErrorMessage;
          END;
          :ErrorCode := v_ErrorCode;
          :ErrorMessage := v_ErrorMessage;
          if nvl(v_ErrorCode,0) not in (0,200) then
            return -1;
          end if;
        END LOOP;
    CLOSE urls;
    CLOSE file_names;
      end if;
    END IF;

    --CHECK WHETHER CASE IS MDM CASE
    ---------------------------------------------------------------------------------------------------
    v_result         := f_MDM_getCaseOrCTinfoFn(calc_CaseId       => v_calc_caseid,
                                              calc_CaseTypeId   => v_calc_CaseTypeId,
                                              calc_TaskId       => v_calc_taskid,
                                              CaseID            => v_caseid,
                                              CaseTypeID        => v_CaseTypeId,
                                              create_ConfigCode => v_CreateConfigCode,
                                              create_ConfigId   => v_CreateConfigId,
                                              create_ConfigName => v_CreateConfigName,
                                              create_ModelId    => v_CreateModelId,
                                              edit_ConfigCode   => v_EditConfigCode,
                                              edit_ConfigId     => v_EditConfigId,
                                              edit_ConfigName   => v_EditConfigName,
                                              edit_ModelId      => v_EditModelId,
                                              TaskId            => NULL);
    ---------------------------------------------------------------------------------------------------
    if nvl(v_CreateConfigId, 0) = 0 then
      v_Result := f_dcm_invalidatecase(CaseId => v_CaseId);
      v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseTypeId, ProcedureId => null);
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseFromCTFn before DCM_caseQueueProc5',
                                     Message => 'Case ' || to_char(v_CaseId) || ' before Queue processing', Rule => 'DCM_createCaseFromCTFn', TaskId => null);
      v_Result := f_dcm_casequeueproc7();
      v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseTypeId, ProcedureId => null);
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseFromCTFn after DCM_caseQueueProc5',
                                     Message => 'Case ' || to_char(v_CaseId) || ' after Queue processing', Rule => 'DCM_createCaseFromCTFn', TaskId => null);
    end if;
    --SET OUTPUT
    :Case_Id := v_CaseId;
    :CaseName := v_col_CaseId;
    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
    if nvl(v_ErrorCode,0) not in (0,200) then
      return -1;
    end if;
    BEGIN
      select wb.col_name into v_workbasket_name
        FROM tbl_case c
        inner join tbl_ppl_workbasket wb on wb.col_id = c.COL_CASEPPL_WORKBASKET
        where c.col_id = v_CaseId;
        EXCEPTION WHEN NO_DATA_FOUND THEN v_workbasket_name := null;
    END;
    if v_draft = 1 then 
      :SuccessResponse := 'Case saved as draft. It will appear in your inbox until you finish working on it.';
    ELSE
      IF v_workbasket_name IS NOT NULL THEN
        :SuccessResponse := 'Case with '|| v_col_CaseId||' has been created and assigned to '||v_Workbasket_name;
      ELSE
       :SuccessResponse := 'Case with '|| v_col_CaseId||' has been created';
      END IF;
    END IF;
    v_result := f_DCM_updateCaseFromCache(CaseId => v_CaseId);
    v_result := f_DCM_clearCache(CaseId => v_CaseId);


    v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseTypeId, ProcedureId => null);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseFromCTFn end',
                                     Message => 'Case ' || to_char(v_CaseId) || ' is created', Rule => 'DCM_createCaseFromCTFn', TaskId => null);

  end;