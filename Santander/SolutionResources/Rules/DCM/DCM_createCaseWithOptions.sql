DECLARE
  v_CaseId                   INTEGER;
  v_CaseName                 NVARCHAR2(255);
  v_CaseTypeId               INTEGER;
  v_CaseType                 NVARCHAR2(255);
  v_ProcedureId              INTEGER;
  v_ProcedureCode            NVARCHAR2(255);
  v_AdhocProcCode            NVARCHAR2(255);
  v_AdhocProcId              INTEGER;
  v_AdhocTaskTypeCode        NVARCHAR2(255);
  v_AdhocTaskTypeId          INTEGER;
  v_sourceid                 INTEGER;
  v_TaskId                   INTEGER;
  v_AdHocName                NVARCHAR2(255);
  v_TaskName                 NVARCHAR2(255);
  v_TaskExtId                INTEGER;
  v_validationresult         NUMBER;
  v_validationstatus         NUMBER;
  v_result                   NUMBER;
  v_CustomData               NCLOB;
  v_customvalidator          NVARCHAR2(255);
  v_customvalresultprocessor NVARCHAR2(255);
  v_Description              NCLOB;
  v_draft                    NUMBER;
  v_preventDocFolderCreate   NUMBER;
  v_ErrorCode                NUMBER;
  v_ErrorMessage             NCLOB;
  v_OwnerWorkBasketId        INTEGER;
  v_workbasket_name          NVARCHAR2(255);
  v_owner                    NVARCHAR2(255);
  v_Summary                  NCLOB;
  v_CaseFrom                 NVARCHAR2(255);
  v_Priority                 INTEGER;
  v_ResolveBy                DATE;
  v_SuccessResponse          NCLOB;
  v_TargetCaseId             INTEGER;
  v_TargetTaskId             INTEGER;
  v_DebugSession             NVARCHAR2(255);
  v_piWorkitemId             NUMBER;
  v_ParentCaseId             INTEGER;
  v_LinkTypeId               INTEGER;
  v_CASEWORKER_ID            NUMBER;
  v_partytypeid              NUMBER;  
  v_purposeName              NVARCHAR2(255);
  v_InData CLOB;
  v_outData CLOB;
    
BEGIN

  v_CaseTypeId    := :CASESYSTYPE_ID;
  v_CaseType      := :CASESYSTYPE_CODE;
  v_ProcedureId   := :PROCEDURE_ID;
  v_ProcedureCode := :PROCEDURE_CODE;
  v_CustomData    := :CUSTOMDATA;
  IF v_CustomData IS NULL THEN
    v_CustomData := '<CustomData><Attributes></Attributes></CustomData>';
  END IF;
  v_Priority               := :PRIORITY_ID;
  v_Summary                := :SUMMARY;
  v_CaseFrom               := NVL(:CaseFrom, 'main'); --options are either 'main' or 'portal'
  v_ResolveBy              := :ResolveBy;
  v_Description            := :DESCRIPTION;
  v_draft                  := nvl(:Draft, 0);
  v_OwnerWorkBasketId      := :OWNER_WORKBASKET_ID;
  v_AdhocProcCode          := :AdhocProcCode;
  v_AdhocProcId            := :AdhocProcId;
  v_TargetCaseId           := :TargetCaseId;
  v_TargetTaskId           := :TargetTaskId;
  v_AdhocTaskTypeCode      := :AdhocTaskTypeCode;
  v_AdhocTaskTypeId        := :AdhocTaskTypeId;
  v_AdHocName              := :AdHocName;
  v_piWorkitemId           := :PIWORKITEM_ID;
  v_ParentCaseId       := :PARENT_CASE_ID;
  v_LinkTypeId         := :LINK_TYPE_ID;
  :CaseName                := NULL;
  :Case_Id                 := NULL;
  :ErrorCode               := NULL;
  :ErrorMessage            := NULL;
  :SuccessResponse         := NULL;
  :Task_Id                 := NULL;
  v_preventDocFolderCreate := NVL(:preventDocFolderCreate, 0);
  v_CASEWORKER_ID          := NULL; 
  v_partytypeid            := NULL;
  v_purposeName            := NULL;
  v_inData                 := NULL;
  v_outData                := NULL;

  IF nvl(v_CaseTypeId, 0) = 0 AND v_CaseType IS NULL AND v_AdhocProcCode IS NULL AND nvl(v_AdhocProcId, 0) = 0 AND nvl(v_TargetCaseId, 0) = 0 AND
     nvl(v_TargetTaskId, 0) = 0 AND v_AdhocTaskTypeCode IS NULL AND nvl(v_AdhocTaskTypeId, 0) = 0 THEN
    :ErrorCode       := 112;
    :ErrorMessage    := 'Insufficient information for case/procedure/task creation';
    :SuccessResponse := :ErrorMessage;
    RETURN;
  END IF;

  IF nvl(v_CaseTypeId, 0) = 0 AND v_CaseType IS NULL AND v_AdhocProcCode IS NULL AND nvl(v_AdhocProcId, 0) = 0 AND nvl(v_TargetCaseId, 0) = 0 AND
     nvl(v_TargetTaskId, 0) = 0 AND (v_AdhocTaskTypeCode IS NOT NULL OR nvl(v_AdhocTaskTypeId, 0) > 0) THEN
    :ErrorCode       := 113;
    :ErrorMessage    := 'To create adhoc task you must specify target case or task';
    :SuccessResponse := :ErrorMessage;
    RETURN;
  END IF;

  --FIND USERACCESSSUBJECT
  BEGIN
    SELECT cwu.accode, wb.COL_CASEWORKERWORKBASKET, NVL(wb.COL_NAME, 'user')
      INTO v_owner, v_CASEWORKER_ID, v_purposeName
      FROM tbl_ppl_workbasket wb
     INNER JOIN vw_ppl_activecaseworker cw
        ON wb.col_caseworkerworkbasket = cw.col_id
     INNER JOIN vw_ppl_activecaseworkersusers cwu
        ON cw.col_id = cwu.id
     WHERE wb.col_id = v_ownerworkbasketid;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_owner := NULL;
      v_CASEWORKER_ID :=NULL;
      v_purposeName   := NULL;
  END;

  IF v_CaseType IS NOT NULL THEN
    BEGIN
      SELECT col_id INTO v_result FROM tbl_dict_casesystype WHERE lower(col_code) = lower(v_CaseType);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_result := NULL;
    END;
  END IF;
  IF v_result IS NOT NULL THEN
    v_CaseTypeId := v_result;
  END IF;
  
  --Check if CaseType is disabled
  IF v_CaseTypeId > 0 THEN
    BEGIN
      SELECT col_isdeleted INTO v_result FROM tbl_dict_casesystype WHERE col_id = v_CaseTypeId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_result := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_result := NULL;
    END;
    IF nvl(v_result, 0) > 0 THEN
      :ErrorCode       := 114;
      :ErrorMessage    := 'Case type is disabled. You can not create case of specified case type';
      :SuccessResponse := :ErrorMessage;
      RETURN;
    END IF;
  END IF;
  --Check if user has permission to create case of specified case type
  IF v_CaseTypeId > 0 THEN
    BEGIN
      SELECT Id INTO v_result FROM TABLE(f_dcm_getCaseTypeAOList()) WHERE CaseTypeId = v_CaseTypeId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_result := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_result := NULL;
    END;
    IF nvl(v_result, 0) > 0 THEN
      v_result := f_dcm_iscasetypecreatealwms(AccessObjectId => v_result);
    END IF;
    IF nvl(v_result, 0) = 0 THEN
      :ErrorCode       := 115;
      :ErrorMessage    := 'You do not have permission to create case of specified case type';
      :SuccessResponse := :ErrorMessage;
      RETURN;
    END IF;
  END IF;
  IF nvl(v_CaseTypeId, 0) > 0 THEN
    v_result := f_dcm_getProcForCaseType(CaseSysTypeId => v_CaseTypeId, ProcedureCode => v_ProcedureCode, ProcedureId => v_ProcedureId);
  END IF;
  IF v_AdhocProcCode IS NOT NULL THEN
    BEGIN
      SELECT col_id INTO v_AdhocProcId FROM tbl_procedure WHERE lower(col_code) = lower(v_AdhocProcCode);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_AdhocProcId := NULL;
    END;
  END IF;
  IF v_AdhocProcId IS NULL AND :AdhocProcId IS NOT NULL THEN
    v_AdhocProcId := :AdhocProcId;
  END IF;
  IF nvl(v_TargetCaseId, 0) = 0 AND nvl(v_TargetTaskId, 0) > 0 THEN
    BEGIN
      SELECT col_casetask INTO v_TargetCaseId FROM tbl_task WHERE col_id = v_TargetTaskId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_TargetCaseId   := NULL;
        :ErrorCode       := 102;
        :ErrorMessage    := 'Target Task Id not found';
        :SuccessResponse := :ErrorMessage;
        RETURN;
    END;
  END IF;
  v_result := f_DCM_createCaseWithOptionsFn(InData                 => v_InData,
                                            OutData                => v_outData,
                                            AdHocName              => v_AdHocName,
                                            AdHocProcCode          => v_AdhocProcCode,
                                            AdhocProcId            => v_AdhocProcId,
                                            AdhocTaskTypeCode      => v_AdhocTaskTypeCode,
                                            AdhocTaskTypeId        => v_AdhocTaskTypeId,
                                            CASESYSTYPE_CODE       => v_CaseType,
                                            CASESYSTYPE_ID         => v_CaseTypeId,
                                            CUSTOMDATA             => v_CustomData,
                                            CaseFrom               => v_CaseFrom,
                                            CaseName               => v_CaseName,
                                            Case_Id                => v_CaseId,
                                            DESCRIPTION            => v_Description,
                                            DocumentsNames         => :DocumentsNames,
                                            DocumentsURLs          => :DocumentsURLs,
                                            Draft                  => v_draft,
                                            ErrorCode              => v_ErrorCode,
                                            ErrorMessage           => v_ErrorMessage,
                                            OWNER_WORKBASKET_ID    => v_OwnerWorkBasketId,
                                            PRIORITY_ID            => v_Priority,
                                            PROCEDURE_CODE         => v_ProcedureCode,
                                            PROCEDURE_ID           => v_ProcedureId,
                                            ResolveBy              => v_ResolveBy,
                                            SUMMARY                => v_Summary,
                                            SuccessResponse        => v_SuccessResponse,
                                            TargetCaseId           => v_TargetCaseId,
                                            TargetTaskId           => v_TargetTaskId,
                                            Task_Id                => v_TaskId,
                                            preventDocFolderCreate => v_preventDocFolderCreate,
                                            PIWorkitemId           => v_piWorkitemId,
                                            PARENT_CASE_ID       => v_ParentCaseId,
                                            LINK_TYPE_ID       => v_LinkTypeId);
  :Case_Id         := v_CaseId;
  :CaseName        := v_CaseName;
  :ErrorCode       := v_ErrorCode;
  :ErrorMessage    := v_ErrorMessage;
  :SuccessResponse := v_SuccessResponse;
  
  IF nvl(v_ErrorCode, 0) NOT IN (0, 200) THEN
    ROLLBACK;
    RETURN;
  END IF;
  
  --create case party record
  /*IF NVL(v_ErrorCode, 0) IN (0, 200) THEN
    IF (NVL(v_CaseId,0)<>0) AND (NVL(v_CASEWORKER_ID,0)<>0) THEN
      -- get PartyType_Id
      v_partytypeid := f_UTIL_getIdByCode(Code => 'CASEWORKER', TableName => 'tbl_dict_participantunittype');

  INSERT INTO tbl_caseparty 
    (col_allowdelete, 
     col_casepartycase, 
     col_casepartydict_unittype, 
     col_casepartyppl_caseworker, 
     col_casepartyexternalparty, 
     col_casepartyppl_businessrole, 
     col_casepartyppl_skill, 
     col_casepartyppl_team, 
     col_name) 
  VALUES      (0, 
     v_caseid, 
     v_partytypeid, 
     v_caseworker_id, 
     0, 
     0, 
     0, 
     0, 
     v_purposename);     
    END IF;
  END IF;--eof create case party record */ 
  
END;