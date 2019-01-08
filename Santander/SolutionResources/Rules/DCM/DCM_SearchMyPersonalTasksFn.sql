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
  v_TaskStateIds := :TaskStateIds;
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
  
  v_Summary := REPLACE(v_Summary, '''', '''''');
  v_TaskName := REPLACE(v_TaskName, '''', '''''');
  v_Description := REPLACE(v_Description, '''', '''''');
  v_ResolutionDescription := REPLACE(v_ResolutionDescription, '''', '''''');
  v_CaseTitle := REPLACE(v_CaseTitle, '''', '''''');
  v_CaseDescription := REPLACE(v_CaseDescription, '''', '''''');

  v_query := '(with s2 as (select wb.col_id as workbasketid from tbl_ppl_workbasket wb ';
  v_countquery := 'with s2 as (select wb.col_id as workbasketid from tbl_ppl_workbasket wb ';
  v_query := v_query || 'inner join tbl_map_workbasketcaseworker mwbcw on wb.col_id = mwbcw.col_map_wb_cw_workbasket ';
  v_countquery := v_countquery || 'inner join tbl_map_workbasketcaseworker mwbcw on wb.col_id = mwbcw.col_map_wb_cw_workbasket ';
  v_query := v_query || 'inner join vw_ppl_activecaseworkersusers cwu on mwbcw.col_map_wb_cw_caseworker = cwu.id ';
  v_countquery := v_countquery || 'inner join vw_ppl_activecaseworkersusers cwu on mwbcw.col_map_wb_cw_caseworker = cwu.id ';
  v_query := v_query || 'inner join tbl_dict_workbaskettype wbt on wb.col_workbasketworkbaskettype = wbt.col_id ';
  v_countquery := v_countquery || 'inner join tbl_dict_workbaskettype wbt on wb.col_workbasketworkbaskettype = wbt.col_id ';
  v_query := v_query || 'where cwu.accode = sys_context(''CLIENTCONTEXT'', ''AccessSubject'') ';
  v_countquery := v_countquery || 'where cwu.accode = sys_context(''CLIENTCONTEXT'', ''AccessSubject'') ';
  v_query := v_query || 'union ';
  v_countquery := v_countquery || 'union ';
  v_query := v_query || 'select wb.col_id as WorkbasketId from tbl_ppl_workbasket wb ';
  v_countquery := v_countquery || 'select wb.col_id as WorkbasketId from tbl_ppl_workbasket wb ';
  v_query := v_query || 'inner join vw_ppl_activecaseworkersusers cwu on wb.col_caseworkerworkbasket = cwu.id ';
  v_countquery := v_countquery || 'inner join vw_ppl_activecaseworkersusers cwu on wb.col_caseworkerworkbasket = cwu.id ';
  v_query := v_query || 'where  wb.col_isdefault = 1 ';
  v_countquery := v_countquery || 'where  wb.col_isdefault = 1 ';
  v_query := v_query || 'and cwu.accode = sys_context(''CLIENTCONTEXT'', ''AccessSubject'')) ';
  v_countquery := v_countquery || 'and cwu.accode = sys_context(''CLIENTCONTEXT'', ''AccessSubject'')) ';
  v_query := v_query || 'select ID from (select v.ID, rownum rn from ';
  v_query := v_query || '(select t.col_id as ID from tbl_task t ';
  v_countquery := v_countquery || 'select t.col_id as ID from ';
  v_countquery := v_countquery || '(select t.col_id, t.col_parentid, t.col_name, t.col_description, t.col_resolutiondescription, t.col_createddate, t.col_draft, t.col_taskppl_workbasket, ';
  v_countquery := v_countquery || 't.col_casetask, t.col_tw_workitemtask, t.col_taskdict_tasksystype, t.col_taskid ';
  v_countquery := v_countquery || 'from tbl_task t inner join (select workbasketid from s2) w on t.col_taskppl_workbasket = w.workbasketid) t ';
  v_query := v_query || 'inner join (select workbasketid from s2) w on t.col_taskppl_workbasket = w.workbasketid ';
  v_countquery := v_countquery || 'inner join (select workbasketid from s2) w on t.col_taskppl_workbasket = w.workbasketid ';
  v_query := v_query || 'inner join tbl_case c on t.col_casetask = c.col_id ';
  v_countquery := v_countquery || 'inner join tbl_case c on t.col_casetask = c.col_id ';
  v_query := v_query || 'inner join tbl_caseext ce on c.col_id = ce.col_caseextcase ';
  v_countquery := v_countquery || 'inner join tbl_caseext ce on c.col_id = ce.col_caseextcase ';
  v_query := v_query || 'inner join tbl_tw_workitem tw on t.col_tw_workitemtask = tw.col_id ';
  v_countquery := v_countquery || 'inner join tbl_tw_workitem tw on t.col_tw_workitemtask = tw.col_id ';
  v_query := v_query || 'left join tbl_dict_taskstate dts on tw.col_tw_workitemdict_taskstate = dts.col_id ';
  v_countquery := v_countquery || 'left join tbl_dict_taskstate dts on tw.col_tw_workitemdict_taskstate = dts.col_id ';
  v_query := v_query || 'inner join tbl_dict_tasksystype tst on t.col_taskdict_tasksystype = tst.col_id ';
  v_countquery := v_countquery || 'inner join tbl_dict_tasksystype tst on t.col_taskdict_tasksystype = tst.col_id ';
  v_query := v_query || 'inner join tbl_dict_casesystype cst on c.col_casedict_casesystype = cst.col_id ';
  v_countquery := v_countquery || 'inner join tbl_dict_casesystype cst on c.col_casedict_casesystype = cst.col_id ';
  v_query := v_query || 'left join vw_ppl_simpleworkbasket wb2 on wb2.id = c.col_caseppl_workbasket ';
  v_countquery := v_countquery || 'left join vw_ppl_simpleworkbasket wb2 on wb2.id = c.col_caseppl_workbasket ';
  v_whereqry := null;

  --BY TASK
  if v_Task_Id is not null then
    v_whereqry := ' where (t.col_id = ' || to_char(v_Task_Id) || ')';
  end if;
  if v_TaskId is not null and v_whereqry is null then
    v_whereqry := ' where (lower(t.col_taskid) like lower(''%' || v_TaskId || '%''))';
  elsif v_TaskId is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (lower(t.col_taskid) like lower(''%' || v_TaskId || '%''))';
  end if;
  if v_ParentId is not null and v_whereqry is null then
    v_whereqry := ' where (t.col_parentid = ' || to_char(v_parentid) || ')';
  elsif v_ParentId is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (t.col_parentid = ' || to_char(v_parentid) || ')';
  end if;
  if v_TaskTypeId is not null and v_whereqry is null then
    v_whereqry := ' where (tst.co_id in (select to_number(column_value) from table(asf_split(' || '''' || v_TaskTypeId || '''' || ', '',''))))';
  elsif v_TaskTypeId is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (tst.col_id in (select to_number(column_value) from table(asf_split(' || '''' || v_TaskTypeId || '''' || ', '',''))))';
  end if;
  if v_TaskName is not null and v_whereqry is null then
    v_whereqry := ' where (lower(t.col_name) like lower(''%' || v_TaskName || '%''))';
  elsif v_TaskName is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (lower(t.col_name) like lower(''%' || v_TaskName || '%''))';
  end if;
  if v_Description is not null and v_whereqry is null then
    v_whereqry := ' where (lower(t.col_description) like lower(''%' || v_Description || '%''))';
  elsif v_Description is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (lower(t.col_description) like lower(''%' || v_Description || '%''))';
  end if;
  if v_ResolutionDescription is not null and v_whereqry is null then
    v_whereqry := ' where (lower(t.col_resolutiondescription) like lower(''%' || v_ResolutionDescription || '%''))';
  elsif v_ResolutionDescription is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (lower(t.col_resolutiondescription) like lower(''%' || v_ResolutionDescription || '%''))';
  end if;
  if v_CreatedStart is not null and v_whereqry is null then
    v_whereqry := ' where (trunc(t.col_createddate) >= trunc(to_date(''' || to_char(v_CreatedStart) || ''')))';
  elsif v_CreatedStart is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (trunc(t.col_createddate) >= trunc(to_date(''' || to_char(v_CreatedStart) || ''')))';
  end if;
  if v_CreatedEnd is not null and v_whereqry is null then
    v_whereqry := ' where (trunc(t.col_createddate) <= trunc(to_date(''' || to_char(v_CreatedEnd) || ''')))';
  elsif v_CreatedEnd is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (trunc(t.col_createddate) <= trunc(to_date(''' || to_char(v_CreatedEnd) || ''')))';
  end if;
  if v_Draft is not null and v_whereqry is null then
    v_whereqry := ' where (nvl(t.col_draft,0) = ' || to_char(v_Draft) || ')';
  elsif v_Draft is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (nvl(t.col_draft,0) = ' || to_char(v_Draft) || ')';
  end if;
  -- BY CASE
  if v_CaseId is not null and v_whereqry is null then
    v_whereqry := ' where (c.col_id = ' || to_char(v_CaseId) || ')';
  elsif v_CaseId is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (c.col_id = ' || to_char(v_CaseId) || ')';
  end if;
  if v_CaseTypeId is not null and v_whereqry is null then
    v_whereqry :=  ' where (cst.col_id in (select to_number(column_value) from table(asf_split(' || '''' || v_CaseTypeId || '''' || ', '',''))))';
  elsif v_CaseTypeId is not null and v_whereqry is not null then
    v_whereqry :=  v_whereqry || ' and (cst.col_id in (select to_number(column_value) from table(asf_split(' || '''' || v_CaseTypeId || '''' || ', '',''))))';
  end if;
  if v_Summary is not null and v_whereqry is null then
    v_whereqry := ' where (lower(c.col_summary) like lower(''%' || v_Summary || '%''))';
  elsif v_Summary is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (lower(c.col_summary) like lower(''%' || v_Summary || '%''))';
  end if;
  if v_CaseTitle is not null and v_whereqry is null then
    v_whereqry :=  ' where (lower(c.col_caseid) like lower(''%' || v_CaseTitle || '%''))';
  elsif v_CaseTitle is not null and v_whereqry is not null then
    v_whereqry :=  v_whereqry || ' and (lower(c.col_caseid) like lower(''%' || v_CaseTitle || '%''))';
  end if;
  if v_CaseDescription is not null and v_whereqry is null then
    v_whereqry :=  ' where (lower(ce.col_description) like lower(''%' || v_CaseDescription || '%''))';
  elsif v_CaseDescription is not null and v_whereqry is not null then
    v_whereqry :=  v_whereqry || ' and (lower(ce.col_description) like lower(''%' || v_CaseDescription || '%''))';
  end if;
  if v_WorkbasketId is not null and v_whereqry is null then
    v_whereqry := ' where t.col_taskppl_workbasket in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_WorkbasketId || '''' || ','','')))';
  elsif v_WorkbasketId is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and t.col_taskppl_workbasket in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_WorkbasketId || '''' || ','','')))';
  end if;
  if v_CaseWorkbasketId is not null and v_whereqry is null then
    v_whereqry := ' where c.col_caseppl_workbasket in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_CaseWorkbasketId || '''' || ','','')))';
  elsif v_CaseWorkbasketId is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and c.col_caseppl_workbasket in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_CaseWorkbasketId || '''' || ','','')))';
  end if;
  if v_TaskStateIsFinish is not null and v_whereqry is null then
    v_whereqry := ' where (nvl(dts.col_isfinish,0) = ' || to_char(v_TaskStateIsFinish) || ')';
  elsif v_TaskStateIsFinish is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' and (nvl(dts.col_isfinish,0) = ' || to_char(v_TaskStateIsFinish) || ')';
  end if;
     
  --BY TaskState
  if v_TaskStateIds is not null and v_whereqry is null then
    v_whereqry :=  ' where (dts.col_id in (select to_number(column_value) from table(asf_split(' || '''' || v_TaskStateIds || '''' || ', '',''))))';
  elsif v_TaskStateIds is not null and v_whereqry is not null then
    v_whereqry :=  v_whereqry || ' and (dts.col_id in (select to_number(column_value) from table(asf_split(' || '''' || v_TaskStateIds || '''' || ', '',''))))';
  end if;  
  
  -- root Tasks are excluded
  if v_whereqry is null then
    v_whereqry := v_whereqry || ' where (lower(t.col_taskid) <> ''root'')';
  else
    v_whereqry := v_whereqry || ' and (lower(t.col_taskid) <> ''root'')';
  end if;
  
  v_query := v_query || v_whereqry;
  v_countquery := v_countquery || v_whereqry;
  v_countquery := 'select count(*) from (' || v_countquery || ')';
  v_query := v_query || ') v ';
  v_query := v_query || 'where rownum < ' || to_char(v_START + v_LIMIT + 1);
  v_query := v_query || ') where rn >= ' || to_char(v_START + 1) || ') v2 ';
  v_query2 := v_query;
  v_query := 'select v1.ID, v1.COL_ID, v1.TaskId, v1.Name, v1.Icon, v1.Leaf, v1.DEPTH, v1.REQUIRED, v1.TaskOrder, v1.ParentId, v1.Description, v1.CreatedBy, v1.CreatedDate, v1.ModifiedBy, v1.ModifiedDate, ';
  v_query := v_query || 'v1.ResolutionDescription, v1.CaseId, v1.Draft, v1.ExtSysId, v1.IntegTarget_Id, v1.IntegTarget_Name, v1.Summary, v1.Case_Description, v1.CaseId_Name, v1.Case_Draft, v1.Case_WORKITEM, ';
  v_query := v_query || 'v1.Priority_Id, v1.Priority_Name, v1.Priority_Value, v1.TaskSysType_Name, v1.TaskSysType_Code, v1.TaskSysType, v1.ParentId as ParentTask_Id, v1.ParentTask_Name, v1.ParentTask_TaskId, ';
  v_query := v_query || 'v1.ParentTask_Type_Name, v1.ParentTask_Type_Code, v1.CaseSysType_Name, v1.CaseSysType_Code, v1.CaseSysType, v1.CaseSysType_IconCode, v1.CaseSysType_ColorCode, ';
  v_query := v_query || 'v1.ExecutionMethod_Name, v1.ExecutionMethod_Code, v1.TaskState_Id, v1.TaskState_Name, v1.TaskState_Code, v1.TaskState_IsStart, v1.TaskState_CanAssign, v1.TaskState_IsFinish, ';
  v_query := v_query || 'v1.TaskState_IsResolve, v1.CaseState_Id, v1.CaseState_Name, v1.CaseState_Code, v1.Workbasket_Id, v1.Workbasket_Name, v1.Owner_Caseworker_Name, v1.Workbasket_Type_Name, ';
  v_query := v_query || 'v1.Workbasket_Type_Code, v1.CaseWorkbasket_Id, v1.CaseWorkbasket_Name, v1.CaseOwner_Caseworker_Name, v1.CaseWorkbasket_Type_Name, v1.CaseWorkbasket_Type_Code, v1.ResolutionCode_Id, ';
  v_query := v_query || 'v1.ResolutionCode_Name, v1.ResolutionCode_Code, v1.ResolutionCode_Icon, v1.ResolutionCode_Theme, v1.NextSlaDateTime, v1.NextSlaEventTypeName, v1.NextSlaEventLevelName, ';
  v_query := v_query || 'v1.PrevSlaDateTime, v1.PrevSlaEventTypeName, v1.PrevSlaEventLevelName, v1.CALC_ICON, ';
  v_query := v_query || 'v1.GoalSlaEventTypeId, v1.GoalSlaEventTypeCode, v1.GoalSlaEventTypeName, v1.GoalSlaDateTime, ';
  v_query := v_query || 'F_util_getdrtnfrmnow(v1.GoalSlaDateTime) AS GoalSlaDuration, ';
  v_query := v_query || 'v1.DLineSlaEventTypeId, v1.DLineSlaEventTypeCode, v1.DLineSlaEventTypeName, v1.DLineSlaDateTime, ';
  v_query := v_query || 'F_util_getdrtnfrmnow(v1.DLineSlaDateTime) AS DLineSlaDuration, ';
  v_query := v_query || 'sys_context(''CLIENTCONTEXT'', ''AccessSubject'') as AcCode, ';
  v_query := v_query || 'case when (1 in (select Allowed from table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => ''CASE_TYPE'',p_PermissionCode => ''VIEW'')) where CaseTypeId = v1.casesystype)) then 1 ';
  v_query := v_query || 'else 0 end as PERM_CASETYPE_VIEW, ';
  if v_Task_Id is null then
    v_query := v_query || 'null ';
  else
    v_query := v_query || 'F_dcm_gettaskcustomdata(v1.ID) ';
  end if;
  v_query := v_query || ' as CustomData, ';
  v_query := v_query || 'F_util_getdrtnfrmnow(v1.PrevSlaDateTime) as SLA_PrevDuration, F_util_getdrtnfrmnow(v1.NextSlaDateTime) as SLA_NextDuration, ';
  v_query := v_query || 'F_getnamefromaccesssubject(v1.createdby) as createdby_name, F_util_getdrtnfrmnow(v1.createddate) as createdduration, F_getnamefromaccesssubject(v1.modifiedby) as modifiedby_name, ';
  v_query := v_query || 'F_util_getdrtnfrmnow(v1.modifieddate) as modifiedduration ';
  v_query := v_query || 'from ';
  v_query := v_query || '(select t.col_id AS ID, t.col_id AS COL_ID, t.col_taskid AS TaskId, t.col_name AS Name, t.col_icon AS Icon, t.col_leaf AS Leaf, t.col_depth AS DEPTH, t.col_required AS REQUIRED, ';
  v_query := v_query || 't.col_taskorder AS TaskOrder, t.col_parentid AS ParentId, t.col_description AS Description, t.col_createdby AS CreatedBy, t.col_createddate AS CreatedDate, ';
  v_query := v_query || 't.col_modifiedby AS ModifiedBy, t.col_modifieddate AS ModifiedDate, t.col_resolutiondescription AS ResolutionDescription, t.col_casetask AS CaseId, ';
  v_query := v_query || 't.col_draft AS Draft, t.col_ExtSysId AS ExtSysId, t.COL_INT_INTEGTARGETTASK AS IntegTarget_Id, it.col_name AS IntegTarget_Name, c.col_summary AS Summary, ';
  v_query := v_query || 'ce.col_description AS Case_Description, c.col_caseid AS CaseId_Name, c.col_draft AS Case_Draft, c.col_cw_workitemcase AS Case_WORKITEM, prty.col_id AS Priority_Id, ';
  v_query := v_query || 'prty.col_name AS Priority_Name, prty.col_value AS Priority_Value, tst.col_name AS TaskSysType_Name, tst.col_code AS TaskSysType_Code, tst.col_id AS TaskSysType, ';
  v_query := v_query || 'tpt.col_name AS ParentTask_Name, tpt.col_taskid AS ParentTask_TaskId, tst_parent.col_name AS ParentTask_Type_Name, ';
  v_query := v_query || 'tst_parent.col_code AS ParentTask_Type_Code, cst.col_name AS CaseSysType_Name, cst.col_code AS CaseSysType_Code, cst.col_id AS CaseSysType, cst.COL_ICONCODE AS CaseSysType_IconCode, ';
  v_query := v_query || 'cst.COL_COLORCODE AS CaseSysType_ColorCode, em.col_name AS ExecutionMethod_Name, em.col_code AS ExecutionMethod_Code, dts.col_id AS TaskState_id, ';
  v_query := v_query || 'F_dcm_invokestatenameproc(t.col_id) AS TaskState_Name, dts.col_activity AS TaskState_code, dts.col_isstart AS TaskState_IsStart, dts.col_canassign AS TaskState_CanAssign, ';
  v_query := v_query || 'dts.col_isfinish AS TaskState_IsFinish, dts.col_isresolve AS TaskState_IsResolve, dcs.col_id AS CaseState_id, dcs.col_name AS CaseState_Name, dcs.col_code AS CaseState_Code, ';
  v_query := v_query || 'wb.id AS Workbasket_id, wb.calcname AS Workbasket_name, wb.calcname AS Owner_CaseWorker_Name, wb.workbaskettype_name AS Workbasket_type_name, ';
  v_query := v_query || 'wb.workbaskettype_code AS Workbasket_type_code, wb2.id AS CaseWorkbasket_id, wb2.calcname AS CaseWorkbasket_name, wb2.calcname AS CaseOwner_CaseWorker_Name, ';
  v_query := v_query || 'wb2.workbaskettype_name AS CaseWorkbasket_type_name, wb2.workbaskettype_code AS CaseWorkbasket_type_code, t.col_taskstp_resolutioncode AS ResolutionCode_Id, ';
  v_query := v_query || 'rt.col_name AS ResolutionCode_Name, rt.col_code AS ResolutionCode_Code, rt.col_iconcode AS ResolutionCode_Icon, rt.col_theme AS ResolutionCode_Theme, ';
--Goal SLA
  v_query := v_query || 'gsetp.col_id as GoalSlaEventTypeId, gsetp.col_code as GoalSlaEventTypeCode, gsetp.col_name as GoalSlaEventTypeName, ';
  v_query := v_query || '(cast(gde.col_datevalue + ';
  v_query := v_query || '(case when gse.col_intervalds is not null then to_dsinterval(gse.col_intervalds) else to_dsinterval(''0 0'' || '':'' || ''0'' || '':'' || ''0'') end) * (gse.col_attemptcount + 1) + ';
  v_query := v_query || '(case when gse.col_intervalym is not null then to_yminterval(gse.col_intervalym) else to_yminterval(''0-0'') end) * (gse.col_attemptcount + 1) as timestamp)) as GoalSlaDateTime, ';
--DeadLine (DLine) SLA
  v_query := v_query || 'dsetp.col_id as DLineSlaEventTypeId, dsetp.col_code as DLineSlaEventTypeCode, dsetp.col_name as DLineSlaEventTypeName, ';
  v_query := v_query || '(cast(dde.col_datevalue + ';
  v_query := v_query || '(case when dse.col_intervalds is not null then to_dsinterval(dse.col_intervalds) else to_dsinterval(''0 0'' || '':'' || ''0'' || '':'' || ''0'') end) * (dse.col_attemptcount + 1) + ';
  v_query := v_query || '(case when dse.col_intervalym is not null then to_yminterval(dse.col_intervalym) else to_yminterval(''0-0'') end) * (dse.col_attemptcount + 1) as timestamp)) as DLineSlaDateTime, ';
----
  v_query := v_query || 'tse.nextsladatetime AS NextSlaDateTime, tse.nextslaeventtypename AS NextSlaEventTypename, tse.nextslaeventlevelname AS NextSlaEventLevelName, ';
  v_query := v_query || 'tse.prevsladatetime AS PrevSlaDateTime, tse.prevslaeventtypename AS PrevSlaEventTypename, tse.prevslaeventlevelname AS PrevSlaEventLevelName, tst.col_iconCode AS CALC_ICON ';
  v_query := v_query || 'from tbl_task t ';
  v_query := v_query || 'left join tbl_case c on t.col_casetask = c.col_id ';
  v_query := v_query || 'inner join tbl_caseext ce on c.col_id = ce.col_caseextcase ';
  v_query := v_query || 'left join tbl_tw_workitem tw on t.col_tw_workitemtask = tw.col_id ';
  v_query := v_query || 'left join tbl_dict_taskstate dts on tw.col_tw_workitemdict_taskstate = dts.col_id ';
  v_query := v_query || 'left join tbl_dict_tasksystype tst on t.col_taskdict_tasksystype = tst.col_id ';
  v_query := v_query || 'left join tbl_dict_casesystype cst on c.col_casedict_casesystype = cst.col_id ';
  v_query := v_query || 'left join tbl_task tpt on t.col_parentid = tpt.col_id ';
  v_query := v_query || 'left join tbl_dict_tasksystype tst_parent on tpt.col_taskdict_tasksystype = tst_parent.col_id ';
  v_query := v_query || 'left join vw_ppl_simpleworkbasket wb on wb.id = t.col_taskppl_workbasket ';
  v_query := v_query || 'left join tbl_stp_resolutioncode rt on t.col_taskstp_resolutioncode = rt.col_id ';
  v_query := v_query || 'left join tbl_dict_executionmethod em on em.col_id = t.col_taskdict_executionmethod ';
  v_query := v_query || 'left join tbl_dict_casestate dcs on dcs.col_id = c.col_cw_workitemcase ';
  v_query := v_query || 'left join tbl_int_integtarget it on it.col_id = t.col_int_integtargettask ';
  v_query := v_query || 'left join tbl_stp_priority prty on c.col_stp_prioritycase = prty.col_id ';
  v_query := v_query || 'left join vw_dcm_taskslaevent6 tse on tse.nexttaskid = t.col_id and tse.prevtaskid = t.col_id ';
  v_query := v_query || 'left join vw_ppl_simpleworkbasket wb2 on wb2.id = c.col_caseppl_workbasket ';
--Goal SLA
  v_query := v_query || 'LEFT JOIN tbl_dict_slaeventtype gsetp ON gsetp.col_code = ''GOAL'' ';
  v_query := v_query || 'LEFT JOIN tbl_slaevent gse ON gse.col_slaeventtask = t.col_id AND gse.col_slaeventdict_slaeventtype = gsetp.col_id ';
  v_query := v_query || 'LEFT JOIN tbl_dateevent gde ON t.col_id = gde.col_dateeventtask and gse.col_slaevent_dateeventtype = gde.col_dateevent_dateeventtype ';
--DeadLine (DLine) SLA
  v_query := v_query || 'LEFT JOIN tbl_dict_slaeventtype dsetp ON dsetp.col_code = ''DEADLINE'' ';
  v_query := v_query || 'LEFT JOIN tbl_slaevent dse ON dse.col_slaeventtask = t.col_id AND dse.col_slaeventdict_slaeventtype = dsetp.col_id ';
  v_query := v_query || 'LEFT JOIN tbl_dateevent dde ON t.col_id = dde.col_dateeventtask and dse.col_slaevent_dateeventtype = dde.col_dateevent_dateeventtype) v1 ';
  -----------------------------------------------------------------------------------------------------------------------------------------------
  v_query := v_query || ' inner join ' || v_query2 || ' on v1.ID = v2.ID ';
  v_query := v_query || ' order by v1.' || v_SORT || ' ' || v_DIR;
  BEGIN
    EXECUTE IMMEDIATE v_countquery
      INTO :TotalCount;
  EXCEPTION
    WHEN OTHERS THEN
        :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error in count query' || ': ' || SQLERRM, 1, 200);
  END;
  BEGIN
    OPEN :ITEMS FOR v_query;
  EXCEPTION
    WHEN OTHERS THEN :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error on search query' || ': ' || SQLERRM, 1, 200);
  END;
end;