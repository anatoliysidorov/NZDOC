declare
  v_CaseId Integer;
  v_CaseName nvarchar2(255);
  v_CaseTypeId Integer;
  v_CaseType nvarchar2(255);
  v_ProcedureId Integer;
  v_ProcedureCode nvarchar2(255);
  v_AdhocProcCode nvarchar2(255);
  v_AdhocProcId Integer;
  v_AdhocTaskTypeCode nvarchar2(255);
  v_AdhocTaskTypeId Integer;
  v_sourceid Integer;
  v_TaskId Integer;
  v_AdHocName nvarchar2(255);
  v_TaskName nvarchar2(255);
  v_TaskExtId Integer;
  v_validationresult number;
  v_validationstatus number;
  v_result number;
  v_CustomData nclob;
  v_customvalidator nvarchar2(255);
  v_customvalresultprocessor nvarchar2(255);
  v_Description nclob;
  v_draft number;
  v_preventDocFolderCreate number;
  v_ErrorCode Number;
  v_ErrorMessage nvarchar2(255);
  v_OwnerWorkBasketId Integer;
  v_workbasket_name nvarchar2(255);
  v_owner nvarchar2(255);
  v_Summary nclob;
  v_CaseFrom nvarchar2(255);
  v_Priority Integer;
  v_ResolveBy date;
  v_SuccessResponse nclob;
  v_SourceCaseId Integer;
  v_SourceTaskId Integer;
  v_TargetCaseId Integer;
  v_TargetTaskId Integer;
  v_DebugSession nvarchar2(255);
begin

  v_CaseTypeId := :CASESYSTYPE_ID;
  v_CaseType := :CASESYSTYPE_CODE;
  v_ProcedureId := :PROCEDURE_ID;
  v_ProcedureCode := :PROCEDURE_CODE;
  v_CustomData := :CUSTOMDATA;
  if v_CustomData is null then
    v_CustomData := '<CustomData><Attributes></Attributes></CustomData>';
  end if;
  v_Priority := :PRIORITY_ID;
  v_Summary := :SUMMARY;
  v_CaseFrom := NVL(:CaseFrom, 'main'); --options are either 'main' or 'portal'
  v_ResolveBy := :ResolveBy;
  v_Description := :DESCRIPTION;
  v_draft := nvl(:Draft,0);
  v_OwnerWorkBasketId := :OWNER_WORKBASKET_ID;
  v_AdhocProcCode := null;
  v_AdhocProcId := null;
  v_SourceCaseId := :SourceCaseId;
  v_SourceTaskId := :SourceTaskId;
  v_TargetCaseId := null;
  v_TargetTaskId := null;
  v_AdhocTaskTypeCode := null;
  v_AdhocTaskTypeId := null;
  v_AdHocName := null;
  :CaseName := null;
  :Case_Id := null;
  :ErrorCode := null;
  :ErrorMessage := null;
  :SuccessResponse := null;
  :Task_Id := null;
  v_preventDocFolderCreate := NVL(:preventDocFolderCreate, 0);
  if v_SourceCaseId is null and v_SourceTaskId is not null then
    begin
      select col_casetask into v_SourceCaseId from tbl_task where col_id = v_SourceTaskId;
      exception
      when NO_DATA_FOUND then
      v_SourceCaseId := null;
    end;
  end if;
  if v_SourceCaseId is null then
    :ErrorCode := 132;
    :ErrorMessage := 'Source case is undefined';
    :SuccessResponse := :ErrorMessage;
    return;
  end if;
  v_result := f_DCM_createCaseWithOptionsFn(AdHocName => null, AdHocProcCode => null, AdhocProcId => null, AdhocTaskTypeCode => null, AdhocTaskTypeId => null, CASESYSTYPE_CODE => v_CaseType ,
                                            CASESYSTYPE_ID =>  v_CaseTypeId , CUSTOMDATA => v_CustomData, CaseFrom => v_CaseFrom, CaseName => v_CaseName, Case_Id => v_CaseId, DESCRIPTION => v_Description,
                                            DocumentsNames => :DocumentsNames, DocumentsURLs => :DocumentsURLs, Draft => v_draft, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                            OWNER_WORKBASKET_ID => v_OwnerWorkBasketId, PRIORITY_ID => v_Priority, PROCEDURE_CODE => v_ProcedureCode, PROCEDURE_ID => v_ProcedureId , ResolveBy => v_ResolveBy,
                                            SUMMARY => v_Summary, SuccessResponse => v_SuccessResponse, TargetCaseId => null, TargetTaskId => null, Task_Id => v_TaskId,
                                            preventDocFolderCreate => v_preventDocFolderCreate);
  insert into tbl_caselink(col_caselinkparentcase, col_caselinkparenttask, col_caselinkchildcase, col_caselinkchildtask, col_caselinkdict_linktype)
  values (v_SourceCaseId, v_SourceTaskId, v_CaseId, (select min(col_id) from tbl_task where col_casetask = v_CaseId and lower(col_name) <> 'root'), (select col_id from tbl_dict_linktype where col_code = 'SUBCASE'));
  :Case_Id := v_CaseId;
  :CaseName := v_CaseName;
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  :SuccessResponse := v_SuccessResponse;
  if nvl(v_ErrorCode,0) not in (0,200) then
    rollback;
    return;
  end if;
end;