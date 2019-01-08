declare
  v_Task_Id Integer;
  v_TaskId nvarchar2(255);
  v_ParentId Integer;
  v_TaskTypeId nvarchar2(255);
  v_TaskName nvarchar2(255);
  v_Description nvarchar2(255);
  v_ResolutionDescription nvarchar2(255);
  v_CreatedStart date;
  v_CreatedEnd date;
  v_Draft number;
  v_CaseId Integer;
  v_CaseTypeId nvarchar2(255);
  v_Summary nvarchar2(255);
  v_CaseTitle nvarchar2(255);
  v_CaseDescription nvarchar2(255);
  v_WorkbasketId nvarchar2(255);
  v_CaseWorkbasketId nvarchar2(255);
  v_TaskStateIsFinish number;
  v_DIR nvarchar2(255);
  v_SORT nvarchar2(255);
  v_START number;
  v_LIMIT number;
  v_query varchar2(32767);
  v_query2 varchar2(32767);
  v_whereqry varchar2(32767);
  v_sortqry varchar2(32767);
  v_countquery varchar2(32767);
  v_result number;
  v_ITEMS sys_refcursor;
  v_TotalCount number;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_TaskStateIds varchar2(4000);
begin
  v_Task_Id := :Task_Id;
  v_TaskId := :TaskId;
  v_ParentId := :ParentId;
  v_TaskTypeId := :TASKTYPE_ID;
  v_TaskName := :Name;
  v_Description := :Description;
  v_ResolutionDescription := :ResolutionDescription;
  v_CreatedStart := :Created_Start;
  v_CreatedEnd := :Created_End;
  v_Draft := :Draft;
  v_CaseId := :Case_Id;
  v_CaseTypeId := :CASETYPE_ID;
  v_Summary := :Summary;
  v_CaseTitle := :CaseId_Name;
  v_CaseDescription := :Case_Description;
  v_WorkbasketId := :WorkbasketId;
  v_CaseWorkbasketId := :CaseWorkbasketId;
  v_TaskStateIsFinish := :TASKSTATE_ISFINISH;
  v_TaskStateIds:= :TASKSTATEIDS;
  v_DIR := :DIR;
  if v_DIR is null then
    v_DIR := 'ASC';
  end if;
  v_LIMIT := :LIMIT;
  v_SORT := :SORT;
  if v_SORT is null then
    v_SORT := 'Id';
  end if;
  v_START := :FIRST;
  if v_START is null then
    v_START := 0;
  end if;
  if nvl(v_LIMIT,0) = 0 then
    v_LIMIT := 1;
  end if;
  v_result := f_DCM_SearchMyPersonalTasksFn(CASETYPE_ID => v_CaseTypeId, CaseId_Name => v_CaseTitle, CaseWorkbasketId => v_CaseWorkbasketId, Case_Description => v_CaseDescription, Case_Id => v_CaseId,
                                            Created_End => v_CreatedEnd, Created_Start => v_CreatedStart, DIR => v_DIR, Description => v_Description, Draft => v_Draft,
                                            ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, FIRST => v_START, ITEMS => v_ITEMS, LIMIT => v_LIMIT,
                                            Name => v_TaskName, ParentId => v_ParentId, ResolutionDescription => v_ResolutionDescription, SORT => v_SORT, Summary => v_Summary, TASKSTATE_ISFINISH => v_TaskStateIsFinish, TaskStateIds=> v_TaskStateIds,
                                            TASKTYPE_ID => v_TaskTypeId, Task_Id => v_Task_Id, TaskId => v_TaskId, TotalCount => v_TotalCount, WorkbasketId => v_WorkbasketId);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  :TotalCount := v_TotalCount;
  :ITEMS := v_ITEMS;
end;