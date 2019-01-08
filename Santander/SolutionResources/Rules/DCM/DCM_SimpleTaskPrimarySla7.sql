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
           (select col_id from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_Id,
           (select f_dcm_invokestatenameproc(col_id) from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_Name,
           (select col_activity from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_Code,
           (select col_isdefaultoncreate from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsDefaultOnCreate,
           (select col_isstart from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsStart,
           (select col_canassign from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_CanAssign,
           (select col_isdefaultoncreate2 from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsInProcess,
           (select col_isfinish from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsFinish,
           (select col_isresolve from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsResolve,
           (select col_isassign from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsAssign,
			/*--SYSTEM TYPE AND PROCEDURE*/
           t.COL_TASKPROCEDURE AS Procedure_id,
           (select col_name from tbl_procedure where col_id = (select col_taskprocedure from tbl_task where col_id = t.col_id)) as Procedure_name,
           /*--TASK STATE CONFIG (Milestones)*/
           sc.col_id AS StateConfig_id,
           sc.col_name AS StateConfig_Name,
           sc.col_code AS StateConfig_code,
           sc.COL_ISDEFAULT AS StateConfig_IsDefault,
           /*--CASE STATE*/
           (select col_id from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_id,
           (select col_name from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_Name,
           (select col_code from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_Code,
           (select col_isstart from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISSTART,
           (select col_isresolve from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISRESOLVE,
           (select col_isfinish from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISFINISH,
           (select col_isassign from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISASSIGN,
           (select col_isstart from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISFIX,
           (select col_isdefaultoncreate2 from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISINPROCESS,
           (select col_isdefaultoncreate from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISDEFAULTONCREATE,
           (select col_name from tbl_dict_state where col_id = (select col_casedict_state from tbl_case where col_id = t.col_casetask)) as MS_StateName,
           /*--OWNERSHIP*/
           wb.id AS Workbasket_id,
           wb.calcname AS Workbasket_name,
           wb.calcname AS Owner_CaseWorker_Name,
           wb.workbaskettype_name AS Workbasket_type_name,
           wb.workbaskettype_code AS Workbasket_type_code,
           /*--for CASE*/
           (select id from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_Id,
           (select calcname from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_Name,
           (select calcname from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseOwner_CaseWorker_Name,
           (select workbaskettype_name from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_type_name,
           (select workbaskettype_code from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_type_code,
           /*--RESOLUTION*/
           t.col_taskstp_resolutioncode AS ResolutionCode_Id,
           rt.col_name AS ResolutionCode_Name,
           rt.col_code AS ResolutionCode_Code,
           rt.col_iconcode AS ResolutionCode_Icon,
           rt.col_theme AS ResolutionCode_Theme,
           /*--SLA EVENT DATA BELOW*/
           --Goal SLA
           --gsetp.col_id as GoalSlaEventTypeId,
           'GOAL' as GoalSlaEventTypeCode,
           'Goal' as GoalSlaEventTypeName,
           (cast((select max(de2.col_datevalue) from tbl_dateevent de2 where de2.col_dateeventtask = t.col_id AND de2.col_dateevent_dateeventtype = gse.col_slaevent_dateeventtype) +
             (case when gse.col_intervalds is not null then to_dsinterval(gse.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) +
             (case when gse.col_intervalym is not null then to_yminterval(gse.col_intervalym) else to_yminterval('0-0') end) as timestamp)) as GoalSlaDateTime,
           --DeadLine (DLine) SLA
           --dsetp.col_id as DLineSlaEventTypeId,
           'DEADLINE' as DLineSlaEventTypeCode,
           'Deadline' as DLineSlaEventTypeName,
           (cast((select max(de2.col_datevalue) from tbl_dateevent de2 where de2.col_dateeventtask = t.col_id AND de2.col_dateevent_dateeventtype = dse.col_slaevent_dateeventtype) +
             (case when dse.col_intervalds is not null then to_dsinterval(dse.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) +
             (case when dse.col_intervalym is not null then to_yminterval(dse.col_intervalym) else to_yminterval('0-0') end) as timestamp)) as DLineSlaDateTime,
           ----
           tse.nextsladatetime AS NextSlaDateTime,
           tse.nextslaeventtypename AS NextSlaEventTypename,
           tse.nextslaeventlevelname AS NextSlaEventLevelName,
           tse.prevsladatetime AS PrevSlaDateTime,
           tse.prevslaeventtypename AS PrevSlaEventTypename,
           tse.prevslaeventlevelname AS PrevSlaEventLevelName,
           /*--CALCULATED*/
           tst.col_iconCode AS CALC_ICON
FROM       tbl_task t
LEFT JOIN  tbl_dict_tasksystype tst         ON t.col_taskdict_tasksystype = tst.col_id
LEFT JOIN  TBL_DICT_STATECONFIG sc          ON tst.COL_STATECONFIGTASKSYSTYPE = sc.col_id
LEFT JOIN  vw_ppl_simpleworkbasket wb       ON wb.id = t.col_taskppl_workbasket
LEFT JOIN  tbl_stp_resolutioncode rt        ON t.col_taskstp_resolutioncode = rt.col_id
LEFT JOIN  tbl_dict_executionmethod em      ON em.col_id = t.col_taskdict_executionmethod
LEFT JOIN  tbl_int_integtarget it           ON it.col_id = t.COL_INT_INTEGTARGETTASK
LEFT JOIN  vw_dcm_taskslaprimaryevent6 tse  ON tse.nexttaskid = t.col_id AND tse.prevtaskid = t.col_id
--Goal SLA
LEFT JOIN tbl_dict_slaeventtype gsetp ON gsetp.col_code = 'GOAL'
LEFT JOIN tbl_slaevent gse ON gse.col_slaeventtask = t.col_id AND gse.col_slaeventdict_slaeventtype = gsetp.col_id
  AND (case when tse.nextsladatetime is not null then tse.nextslaeventid when tse.prevsladatetime is not null then tse.prevslaeventid else null end) = gse.col_id
--DeadLine (DLine) SLA
LEFT JOIN tbl_dict_slaeventtype dsetp ON dsetp.col_code = 'DEADLINE'
LEFT JOIN tbl_slaevent dse ON dse.col_slaeventtask = t.col_id AND dse.col_slaeventdict_slaeventtype = dsetp.col_id
  AND (case when tse.nextsladatetime is not null then tse.nextslaeventid when tse.prevsladatetime is not null then tse.prevslaeventid else null end) = dse.col_id