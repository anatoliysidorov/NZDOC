 SELECT
           /*--BASIC DATA*/
           t.col_id AS ID,
           t.col_id AS COL_ID,
           t.col_taskid AS TaskId,
           t.col_name AS Name,
           t.col_icon AS Icon,
           t.col_leaf AS Leaf,
           t.col_depth AS DEPTH,
           t.col_required AS REQUIRED,
           t.col_taskorder AS TaskOrder,
           t.col_parentid AS ParentId,
           t.col_description AS Description,
           t.col_createdby AS CreatedBy,
           t.col_createddate AS CreatedDate,
           t.col_modifiedby AS ModifiedBy,
           t.col_modifieddate AS ModifiedDate,
           t.col_resolutiondescription AS ResolutionDescription,
           t.col_casetask AS CaseId,
           t.col_draft AS Draft,
           t.col_isadhoc AS IsAdhoc,
           /*--INTEGRATION*/
           t.col_ExtSysId AS ExtSysId,
           t.COL_INT_INTEGTARGETTASK AS IntegTarget_Id,
           t.col_dateclosed as task_dateclosed,
           it.col_name AS IntegTarget_Name,
           it.col_code AS IntegTarget_Code,
           /*--CASE*/
           (select col_summary from tbl_case where col_id = t.col_casetask) as Summary,
           (select col_description from tbl_caseext where col_caseextcase = (select col_id from tbl_case where col_id = t.col_casetask)) as Case_Description,
           (select col_caseid from tbl_case where col_id = t.col_casetask) as CaseId_Name,
           (select col_draft from tbl_case where col_id = t.col_casetask) as Case_Draft,
           (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask) as Case_WORKITEM,
           (select col_createdby from tbl_case where col_id = t.col_casetask) as Case_CreatedBy,
           /*--CASE PRIORITY*/
           (select col_id from tbl_stp_priority where col_id = (select col_stp_prioritycase from tbl_case where col_id = t.col_casetask)) as Priority_Id,
           (select col_name from tbl_stp_priority where col_id = (select col_stp_prioritycase from tbl_case where col_id = t.col_casetask)) as Priority_Name,
           (select col_value from tbl_stp_priority where col_id = (select col_stp_prioritycase from tbl_case where col_id = t.col_casetask)) as Priority_Value,
           /*--TASK TYPE*/
           tst.col_name AS TaskSysType_Name,
           tst.col_code AS TaskSysType_Code,
           tst.col_id AS TaskSysType,
           /*--PARENT TASK*/
           (select col_name from tbl_task where col_id = t.col_parentid) as ParentTask_Name,
           (select col_taskid from tbl_task where col_id = t.col_parentid) as ParentTask_TaskId,
           (select col_name from tbl_dict_tasksystype where col_id = (select col_taskdict_tasksystype from tbl_task where col_id = t.col_parentid)) as ParentTask_Type_Name,
           (select col_code from tbl_dict_tasksystype where col_id = (select col_taskdict_tasksystype from tbl_task where col_id = t.col_parentid)) as ParentTask_Type_Code,
           /*--CASE TYPE*/
           (select col_name from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType_Name,
           (select col_code from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType_Code,
           (select col_id from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType,
           (select col_iconcode from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType_IconCode,
           (select col_colorcode from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType_ColorCode,
           /*--EXECUTION METHOD*/
           em.col_name AS ExecutionMethod_Name,
           em.col_code AS ExecutionMethod_Code,
           /*--TASK STATE*/
           t.col_taskdict_taskstate as TaskState_id,
           f_dcm_invokestatenameproc(t.col_id) as TaskState_Name,
           (select col_activity from tbl_dict_taskstate where col_id = t.col_taskdict_taskstate) as TaskState_Code,
           (select col_isdefaultoncreate from tbl_dict_taskstate where col_id = t.col_taskdict_taskstate) as TaskState_IsDefaultOnCreate,
           (select col_isstart from tbl_dict_taskstate where col_id = t.col_taskdict_taskstate) as TaskState_IsStart,
           (select col_canassign from tbl_dict_taskstate where col_id = t.col_taskdict_taskstate) as TaskState_CanAssign,
           (select col_isdefaultoncreate2 from tbl_dict_taskstate where col_id = t.col_taskdict_taskstate) as TaskState_IsInProcess,
           (select col_isfinish from tbl_dict_taskstate where col_id = t.col_taskdict_taskstate) as TaskState_IsFinish,
           (select col_isresolve from tbl_dict_taskstate where col_id = t.col_taskdict_taskstate) as TaskState_IsResolve,
           (select col_isassign from tbl_dict_taskstate where col_id = t.col_taskdict_taskstate) as TaskState_IsAssign,
           /*--SYSTEM TYPE AND PROCEDURE*/
           t.COL_TASKPROCEDURE AS Procedure_id,
           (select col_name from tbl_procedure where col_id = t.col_taskprocedure) as Procedure_Name,
           /*--TASK STATE CONFIG (Milestones)*/
           sc.col_id AS StateConfig_id,
           sc.col_name AS StateConfig_Name,
           sc.col_code AS StateConfig_code,
           sc.COL_ISDEFAULT AS StateConfig_IsDefault,
           /*--CASE STATE*/
           (select col_id from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_id,
           (select col_name from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_Name,
           (select col_code from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_Code,
           (select col_isstart from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_ISSTART,
           (select col_isresolve from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_ISRESOLVE,
           (select col_isfinish from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_ISFINISH,
           (select col_isassign from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_ISASSIGN,
           (select col_isstart from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_ISFIX,
           (select col_isdefaultoncreate2 from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_ISINPROCESS,
           (select col_isdefaultoncreate from tbl_dict_casestate where col_id = (select col_casedict_casestate from tbl_case where col_id = t.col_casetask)) as CaseState_ISDEFAULTONCREATE,
           (select col_name from tbl_dict_state where col_id = (select col_casedict_state from tbl_case where col_id = t.col_casetask)) as MS_StateName,
           /*--OWNERSHIP*/
           wb.id AS Workbasket_id,
           wb.calcname AS Workbasket_name,
           wb.calcname AS Owner_CaseWorker_Name,
           wb.workbaskettype_name AS Workbasket_type_name,
           wb.workbaskettype_code AS Workbasket_type_code,
           /*--for CASE*/
           (select id from vw_ppl_workbasketsimple where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_Id,
           (select calcname from vw_ppl_workbasketsimple where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_Name,
           (select calcname from vw_ppl_workbasketsimple where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseOwner_CaseWorker_Name,
           (select workbaskettype_name from vw_ppl_workbasketsimple where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_type_name,
           (select workbaskettype_code from vw_ppl_workbasketsimple where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_type_code,
           /*--RESOLUTION*/
           t.col_taskstp_resolutioncode AS ResolutionCode_Id,
           rt.col_name AS ResolutionCode_Name,
           rt.col_code AS ResolutionCode_Code,
           rt.col_iconcode AS ResolutionCode_Icon,
           rt.col_theme AS ResolutionCode_Theme,
           /*--SLA EVENT DATA BELOW*/
           --Goal SLA
           'GOAL' as GoalSlaEventTypeCode,
           'Goal' as GoalSlaEventTypeName,
           cast(t.col_goalslaeventdate as timestamp) as GoalSlaDateTime,
           --DeadLine (DLine) SLA
           'DEADLINE' as DLineSlaEventTypeCode,
           'Deadline' as DLineSlaEventTypeName,
           cast(t.col_dlineslaeventdate as timestamp) as DLineSlaDateTime,
           ----
           /*--CALCULATED*/
           tst.col_iconCode AS CALC_ICON
FROM       tbl_task t
LEFT JOIN  tbl_dict_tasksystype tst         ON t.col_taskdict_tasksystype = tst.col_id
LEFT JOIN  TBL_DICT_STATECONFIG sc          ON tst.COL_STATECONFIGTASKSYSTYPE = sc.col_id
LEFT JOIN  vw_ppl_workbasketsimple wb       ON wb.id = t.col_taskppl_workbasket
LEFT JOIN  tbl_stp_resolutioncode rt        ON t.col_taskstp_resolutioncode = rt.col_id
LEFT JOIN  tbl_dict_executionmethod em      ON em.col_id = t.col_taskdict_executionmethod
LEFT JOIN  tbl_int_integtarget it           ON it.col_id = t.COL_INT_INTEGTARGETTASK