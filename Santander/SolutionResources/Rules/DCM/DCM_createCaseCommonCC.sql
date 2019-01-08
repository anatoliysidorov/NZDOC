declare
    v_Recordid Integer;
    v_Recordid2 Integer;
    v_CaseId Integer;
    v_col_CaseId nvarchar2(255);
    v_PriorityCase Integer;
    v_ProcedureId Integer;
    v_Owner nvarchar2(255);
    v_TaskOwner nvarchar2(255);
    v_Summary nvarchar2(255);
    v_ActivityCode nvarchar2(255);
    v_WorkflowCode nvarchar2(255);
    v_OwnerWorkBasketId Integer;
	
    v_ResolveBy date;

    v_Result Integer;
    v_ErrorCode Number;
    v_ErrorMessage nvarchar2(255);
    v_affectedRows number;
    v_CaseSysTypeId Integer;
    v_Description nclob;
    v_tmsg nvarchar2(255);
    v_tec number;
    v_draft number;
    v_DebugSession nvarchar2(255);
    v_stateconfigid Integer;

begin
  --COMMON ATTRIBUTES
  v_col_CaseId := null;
  v_Owner := :Owner;
  v_PriorityCase := :PriorityCase;
  v_Summary := :Summary;
  v_ResolveBy := :ResolveBy;
  v_CaseSysTypeId := :CaseSysTypeId;
  v_ProcedureId := :ProcedureId;
  v_Description := :Description;
  v_OwnerWorkBasketId := :OwnerWorkBasketId;
  v_draft := :Draft;
  :ErrorCode := 0;
  :ErrorMessage := null;
	
  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseSysTypeId, ProcedureId => v_ProcedureId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseCommon begin', Message => 'Case is about to be created', Rule => 'DCM_createCaseCommon', TaskId => null);
  --CREATE CASE
  v_CaseId := f_DCM_createCaseCCFn (affectedRows => v_affectedRows, CaseSysTypeId => v_CaseSysTypeId, Description => v_Description, Draft => v_draft, Owner => v_Owner, PriorityCase => v_PriorityCase, ProcedureId => v_ProcedureId,
                                  recordId => v_RecordId, ResolveBy => v_ResolveBy, Summary => v_Summary, TOKEN_USERACCESSSUBJECT => :TOKEN_USERACCESSSUBJECT, OwnerWorkBasketId=> v_OwnerWorkBasketId);

  --GET IDENTIFIERS FOR CREATED CASE
  v_CaseId := v_Recordid;
  :recordid := v_Recordid;

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseSysTypeId, ProcedureId => v_ProcedureId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseCommon after f_DCM_createCaseFn', Message => 'Case ' || to_char(v_CaseId) || ' is created', Rule => 'DCM_createCaseCommon', TaskId => null);
  
  --CREATE WORK ITEM FOR CASE
  v_Result := f_CSW_createWorkitemCC(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, Owner => v_Owner, ProcedureId => v_ProcedureId);

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case workitem created', Message => 'Case ' || to_char(v_CaseId) || ' workitem created', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE HISTORY RECORD FOR NEW CASE
  v_Result := f_DCM_createCaseHistoryCC(CaseId => v_CaseId, MessageCode => 'CaseCreatedInState', IsSystem => 0);

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case history created', Message => 'Case ' || to_char(v_CaseId) || ' history created', Rule => 'DCM_createCaseCommon', TaskId => null);

  --GENERATE CASE ID FOR BUSINESS REFERENCE
  v_Result := f_DCM_generateCaseCCId(CaseId => v_CaseId, CaseTitle => v_col_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
  :CaseId := v_col_CaseId;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case title generated', Message => 'Case ' || to_char(v_CaseId) || ' title ' || v_col_CaseId || ' generated', Rule => 'DCM_createCaseCommon', TaskId => null);

  --COPY CASE STATE INITIATION RECORDS TO MAP_CASESTATEINITIATION TABLE FOR CREATED CASE
  v_Result := f_DCM_copyCaseStateInitCC (CaseId => v_CaseId);

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case state initiation records copied', Message => 'Case ' || to_char(v_CaseId) || ' case state initiation records copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --COPY CASE EVENTS
  v_Result := f_DCM_copyCaseEventCC(CaseId => v_CaseId);

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case events copied', Message => 'Case ' || to_char(v_CaseId) || ' events copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --COPY CASE EVENT PARAMETERS
  v_Result := f_DCM_copyCaseRuleParamCC(CaseId => v_CaseId);

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case rule parameters copied', Message => 'Case ' || to_char(v_CaseId) || ' rule parameters copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE TASKS FOR CASE FROM PROCEDURE (TASK HIERARCHY CONFIGURATION)
  v_TaskOwner := null;
  v_Result := f_DCM_CopyTaskCC (affectedRows => v_affectedRows, CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner, prefix => 'TASK-',
                              ProcedureId => v_ProcedureId, recordId => v_RecordId2, TOKEN_USERACCESSSUBJECT => :TOKEN_USERACCESSSUBJECT);
 :ErrorCode := v_ErrorCode;
 :ErrorMessage := v_ErrorMessage;
  if nvl(v_ErrorCode,0) not in (0,200) then
   return -1;
  end if;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case tasks from task templates copied', Message => 'Case ' || to_char(v_CaseId) || ' tasks copied from task templates', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE WORK ITEM FOR EACH CREATED ABOVE TASK
  --v_ActivityCode := f_dcm_getTaskNewState();
  v_WorkflowCode := :TOKEN_DOMAIN || '_' || f_DCM_getTaskWorkflowCodeFn();
  
  begin
    for task_rec in (
    select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId)
    loop
      begin
        select col_stateconfigtasksystype into v_stateconfigid from tbl_dict_tasksystype where col_id = (select col_taskccdict_tasksystype from tbl_taskcc where col_id = task_rec.col_id);
        exception
        when NO_DATA_FOUND then
        v_stateconfigid := null;
      end;
      if v_stateconfigid is null then
        begin
          select col_id into v_stateconfigid from tbl_dict_stateconfig where col_isdefault = 1 and lower(col_type) = 'task';
          exception
          when NO_DATA_FOUND then
            v_stateconfigid := null;
          when TOO_MANY_ROWS then
            v_stateconfigid := null;
        end;
      end if;
      v_ACtivityCode := f_dcm_getTaskNewState2(StateConfigId => v_stateconfigid);
      v_Result := f_TSKW_createWorkitemCC (AccessSubjectCode => TOKEN_USERACCESSSUBJECT, ActivityCode => v_ActivityCode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                          Owner => v_Owner, TaskId => task_rec.col_id, TOKEN_USERACCESSSUBJECT => :TOKEN_USERACCESSSUBJECT, WorkflowCode => v_WorkflowCode);
      v_Result := f_DCM_addTaskDateEventCCList(TaskId => task_rec.col_id, state => v_ActivityCode);
      v_Result := f_DCM_createTaskHistoryCC (IsSystem => 0, MessageCode => 'TaskCreatedInState', TaskId => task_rec.col_id);

      -- CREATE A TASK EXT RECORD FOR EACH TASK
      INSERT INTO tbl_taskextcc (COL_taskextcctaskcc)
        VALUES (task_rec.col_id);
		
    end loop;
  end;

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseSysTypeId, ProcedureId => v_ProcedureId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseCommon task list created', Message => 'Task list created in case ' || to_char(v_CaseId), Rule => 'DCM_createCaseCommon', TaskId => null);

  --COPY SLA EVENTS AND SLA ACTIONS
  v_result := f_DCM_copySlaEventCC(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  if nvl(v_ErrorCode,0) not in (0,200) then
    return -1;
  end if;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case SLA events copied', Message => 'Case ' || to_char(v_CaseId) || ' SLA events copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --COPY PARTICIPANTS TO CASE PARTIES FOR THE CASE
  v_result := f_DCM_CopyParticipantCC(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  if nvl(v_ErrorCode,0) not in (0,200) then
    return -1;
  end if;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case participants copied', Message => 'Case ' || to_char(v_CaseId) || ' participants copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE TASK STATE INITIATION ITEMS
  v_result := f_DCM_CopyTaskStateInitCC(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  if nvl(v_ErrorCode,0) not in (0,200) then
    return -1;
  end if;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case tasks state initiation records copied', Message => 'Case ' || to_char(v_CaseId) || ' tasks initiation records copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE TASK DEPENDENCY ITEMS
  v_result := f_DCM_CopyTaskDependencyCC(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  if nvl(v_ErrorCode,0) not in (0,200) then
    return -1;
  end if;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case task dependencies copied', Message => 'Case ' || to_char(v_CaseId) || ' task dependencies copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE TASK EVENT ITEMS
  v_result := f_DCM_CopyTaskEventCC(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  if nvl(v_ErrorCode,0) not in (0,200) then
    return -1;
  end if;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case task events copied', Message => 'Case ' || to_char(v_CaseId) || ' task events copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE AUTO RULE PARAMETERS
  v_result := f_DCM_CopyRuleParamCC(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  if nvl(v_ErrorCode,0) not in (0,200) then
    return -1;
  end if;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case task rule parameters copied', Message => 'Case ' || to_char(v_CaseId) || ' task rule parameters copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE CASE DATE EVENTS 'DATE_CASE_CREATED' AND 'DATE_CASE_MODIFIED'
  v_Result := f_DCM_addCaseDateEventCCList(CaseId => v_CaseId);

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case date events copied', Message => 'Case ' || to_char(v_CaseId) || ' date events copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseSysTypeId, ProcedureId => v_ProcedureId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseCommon case related data created', Message => 'Case related data created in case ' || to_char(v_CaseId), Rule => 'DCM_createCaseCommon', TaskId => null);

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseSysTypeId, ProcedureId => v_ProcedureId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseCommon end', Message => 'Case ' || to_char(v_CaseId) || ' is created', Rule => 'DCM_createCaseCommon', TaskId => null);

end;