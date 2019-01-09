declare
    --SEARCH PARAMETERS
    v_CREATED_END DATE;
    v_CREATED_START DATE;
    v_CalcEmail NVARCHAR2(255);
    v_CalcExtSysId NVARCHAR2(255);
    v_CalcName NVARCHAR2(255);
    v_CaseId NVARCHAR2(255);
    v_CaseSysTypeIds NVARCHAR2(255);
    v_CaseSysType_Code NVARCHAR2(255);
    v_Case_Id INTEGER;
    v_CaseworkerIds NVARCHAR2(255);
    v_DESCRIPTION NVARCHAR2(255);
    v_ExternalPartyIds NVARCHAR2(255);
    v_PriorityIds NVARCHAR2(255);
    v_ResolutionCodeIds NVARCHAR2(255);
    v_Task_Id INTEGER;
    v_TeamIds NVARCHAR2(255);
    v_WorkbasketIds NVARCHAR2(255);
    v_summary NVARCHAR2(255);
    v_workbasket_name NVARCHAR2(255);
    v_CaseStateIds varchar2(32767);
    v_MilestoneIds varchar2(32767);
	
	-- Fields from CDM_Briefings
	v_RiskIds varchar2(255);
	v_UrgencyIds varchar2(255);
    v_BriefingTypeIds varchar2(255);
    v_BriefingProductIds varchar2(255);
	
    --PAGING AND SORTING
    v_LIMIT INTEGER;
    v_DIR NVARCHAR2(10);
    v_SORT NVARCHAR2(60);
    v_START INTEGER;
	
    --OUTPUT
    v_result INTEGER;
    v_ITEMS sys_refcursor;
    v_TotalCount INTEGER;
    v_ErrorCode INTEGER;
    v_ErrorMessage NVARCHAR2(255);
begin
    --SEARCH INPUT
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
    v_ExternalPartyIds := :ExternalPartyIds;
    v_PriorityIds := :PriorityIds;
    v_ResolutionCodeIds := :ResolutionCodeIds;
    v_Task_Id := :Task_Id;
    v_TeamIds := :TeamIds;
    v_WorkbasketIds := :WorkbasketIds;
    v_summary := :summary;
    v_workbasket_name := :workbasket_name;
    v_CaseStateIds := :CaseStateIds;
    v_MilestoneIds := :MilestoneIds;
	
	-- Fields from CDM_Briefings  
	v_RiskIds := :RiskIds;
	v_UrgencyIds := :UrgencyIds;
    v_BriefingTypeIds := :BriefingTypeIds;
    v_BriefingProductIds := :BriefingProductIds;

	
    --PAGING AND SORTING INPUT
    v_SORT := NVL(:SORT,'ID');
    v_DIR := NVL(:DIR,'ASC');
    v_LIMIT := NVL(:LIMIT,100);
    v_START := NVL(:FIRST,0);
	
	--EXECUTE SEARCH
    v_result := f_CUST_SearchCasesACAllFn(CalcEmail => v_CalcEmail,
                                         CalcExtSysId => v_CalcExtSysId,
                                         CalcName => v_CalcName,
                                         Case_Id => v_Case_Id,
                                         CaseId => v_CaseId,
                                         CaseSysType_Code => v_CaseSysType_Code,
                                         CaseSysTypeIds => v_CaseSysTypeIds,
                                         CaseworkerIds => v_CaseworkerIds,
                                         CREATED_END => v_CREATED_END,
                                         CREATED_START => v_CREATED_START,
                                         DESCRIPTION => v_DESCRIPTION,
                                         DIR => v_DIR,
                                         ErrorCode => v_ErrorCode,
                                         ErrorMessage => v_ErrorMessage,
                                         ExternalPartyIds => v_ExternalPartyIds,
                                         FIRST => v_START,
                                         ITEMS => v_ITEMS,
                                         LIMIT => v_LIMIT,
                                         PriorityIds => v_PriorityIds,
                                         ResolutionCodeIds => v_ResolutionCodeIds,
                                         SORT => v_SORT,
                                         summary => v_summary,
                                         Task_Id => v_Task_Id,
                                         TeamIds => v_TeamIds,
                                         TotalCount => v_TotalCount,
                                         workbasket_name => v_workbasket_name,
                                         WorkbasketIds => v_WorkbasketIds,
                                         CaseStateIds => v_CaseStateIds,
                                         MilestoneIds => v_MilestoneIds,
										 RiskIds => v_RiskIds,
										 UrgencyIds => v_UrgencyIds,
                                         BriefingTypeIds => v_BriefingTypeIds,
                                         BriefingProductIds => v_BriefingProductIds);
    
	--RETURN
    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
    :TotalCount := v_TotalCount;
    :ITEMS := v_ITEMS;
end;