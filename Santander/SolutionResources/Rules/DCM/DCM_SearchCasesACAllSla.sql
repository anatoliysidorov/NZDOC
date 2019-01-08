declare
  v_CREATED_END date;
  v_CREATED_START date;
  v_CalcEmail nvarchar2(255);
  v_CalcExtSysId nvarchar2(255);
  v_CalcName nvarchar2(255);
  v_CaseId nvarchar2(255);
  v_CaseSysTypeIds nvarchar2(255);
  v_CaseSysType_Code nvarchar2(255);
  v_Case_Id Integer;
  v_CaseworkerIds nvarchar2(255);
  v_DESCRIPTION nvarchar2(255);
  v_DIR nvarchar2(255);
  v_ExternalPartyIds nvarchar2(255);
  v_LIMIT number;
  v_PriorityIds nvarchar2(255);
  v_ResolutionCodeIds nvarchar2(255);
  v_SORT nvarchar2(255);
  v_START number;
  v_Task_Id Integer;
  v_TeamIds nvarchar2(255);
  v_WorkbasketIds nvarchar2(255);
  v_summary nvarchar2(255);
  v_workbasket_name nvarchar2(255);
  v_query varchar2(32767);
  v_whereqry varchar2(32767);
  v_sortqry varchar2(32767);
  v_countquery varchar2(32767);
  v_result number;
  v_ITEMS sys_refcursor;
  v_TotalCount number;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_CaseStateIds varchar2(32767);
begin
  v_CREATED_END := :CREATED_END;
  v_CREATED_START := :CREATED_START;
  v_CalcEmail := :CalcEmail;
  v_CalcExtSysId := :CalcExtSysId;
  v_CalcName := :CalcName;
  v_CaseId := :CaseId;
  v_CaseSysTypeIds := :CaseSysTypeIds;
  v_CaseSysType_Code := :CaseSysType_Code;
  v_Case_Id := :Case_Id;
  v_CaseworkerIds := :CaseworkerIds;
  v_DESCRIPTION := :DESCRIPTION;
  v_DIR := :DIR;
  if v_DIR is null then
    v_DIR := 'ASC';
  end if;
  v_ExternalPartyIds := :ExternalPartyIds;
  v_LIMIT := :LIMIT;
  v_PriorityIds := :PriorityIds;
  v_ResolutionCodeIds := :ResolutionCodeIds;
  v_SORT := :SORT;
  if v_SORT is null then
    v_SORT := 'Id';
  end if;
  v_START := :FIRST;
  v_Task_Id := :Task_Id;
  v_TeamIds := :TeamIds;
  v_WorkbasketIds := :WorkbasketIds;
  v_summary := :summary;
  v_workbasket_name := :workbasket_name;
  v_CaseStateIds := :CaseStateIds;
  v_result := f_DCM_SearchCasesACAllSlaFn(CalcEmail => v_CalcEmail, CalcExtSysId => v_CalcExtSysId, CalcName => v_CalcName, Case_Id => v_Case_Id, CaseId => v_CaseId, CaseSysType_Code => v_CaseSysType_Code, CaseSysTypeIds => v_CaseSysTypeIds,
                                       CaseworkerIds => v_CaseworkerIds, CREATED_END => v_CREATED_END, CREATED_START => v_CREATED_START, DESCRIPTION => v_DESCRIPTION, DIR => v_DIR, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                       ExternalPartyIds => v_ExternalPartyIds, FIRST => v_START, ITEMS => v_ITEMS, LIMIT => v_LIMIT, PriorityIds => v_PriorityIds, ResolutionCodeIds => v_ResolutionCodeIds, SORT => v_SORT, summary => v_summary,
                                       Task_Id => v_Task_Id, TeamIds => v_TeamIds, TotalCount => v_TotalCount, workbasket_name => v_workbasket_name, WorkbasketIds => v_WorkbasketIds, CaseStateIds => v_CaseStateIds);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  :TotalCount := v_TotalCount;
  :ITEMS := v_ITEMS;
end;