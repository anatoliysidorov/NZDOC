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
           --it.col_name AS IntegTarget_Name,
           (select col_name from tbl_int_integtarget where col_id = (select col_int_integtargettask from tbl_task where col_id = t.col_id)) as IntegTarget_Name,
           --it.col_code AS IntegTarget_Code,
           (select col_code from tbl_int_integtarget where col_id = (select col_int_integtargettask from tbl_task where col_id = t.col_id)) as IntegTarget_Code,
           /*--CASE*/
           --c.col_summary AS Summary,
           (select col_summary from tbl_case where col_id = t.col_casetask) as Summary,
           --ce.col_description AS Case_Description,
           (select col_description from tbl_caseext where col_caseextcase = (select col_id from tbl_case where col_id = t.col_casetask)) as Case_Description,
           --c.col_caseid AS CaseId_Name,
           (select col_caseid from tbl_case where col_id = t.col_casetask) as CaseId_Name,
           --c.col_draft AS Case_Draft,
           (select col_draft from tbl_case where col_id = t.col_casetask) as Case_Draft,
           --c.col_cw_workitemcase AS Case_WORKITEM,
           (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask) as Case_WORKITEM,
           --c.col_createdby AS Case_CreatedBy,
           (select col_createdby from tbl_case where col_id = t.col_casetask) as Case_CreatedBy,
           /*--CASE PRIORITY*/
           --prty.col_id AS Priority_Id,
           (select col_id from tbl_stp_priority where col_id = (select col_stp_prioritycase from tbl_case where col_id = t.col_casetask)) as Priority_Id,
           --prty.col_name AS Priority_Name,
           (select col_name from tbl_stp_priority where col_id = (select col_stp_prioritycase from tbl_case where col_id = t.col_casetask)) as Priority_Name,
           --prty.col_value AS Priority_Value,
           (select col_value from tbl_stp_priority where col_id = (select col_stp_prioritycase from tbl_case where col_id = t.col_casetask)) as Priority_Value,
           /*--TASK TYPE*/
           --tst.col_name AS TaskSysType_Name,
           (select col_name from tbl_dict_tasksystype where col_id = (select col_taskdict_tasksystype from tbl_task where col_id = t.col_id)) as TaskSysType_Name,
           --tst.col_code AS TaskSysType_Code,
           (select col_code from tbl_dict_tasksystype where col_id = (select col_taskdict_tasksystype from tbl_task where col_id = t.col_id)) as TaskSysType_Code,
           --tst.col_id AS TaskSysType,
           (select col_id from tbl_dict_tasksystype where col_id = (select col_taskdict_tasksystype from tbl_task where col_id = t.col_id)) as TaskSysType,
           /*--PARENT TASK*/
           --tpt.col_name AS ParentTask_Name,
           (select col_name from tbl_task where col_id = t.col_parentid) as ParentTask_Name,
           --tpt.col_taskid AS ParentTask_TaskId,
           (select col_taskid from tbl_task where col_id = t.col_parentid) as ParentTask_TaskId,
           --tst_parent.col_name AS ParentTask_Type_Name,
           (select col_name from tbl_dict_tasksystype where col_id = (select col_taskdict_tasksystype from tbl_task where col_id = t.col_parentid)) as ParentTask_Type_Name,
           --tst_parent.col_code AS ParentTask_Type_Code,
           (select col_code from tbl_dict_tasksystype where col_id = (select col_taskdict_tasksystype from tbl_task where col_id = t.col_parentid)) as ParentTask_Type_Code,
           /*--CASE TYPE*/
           --cst.col_name AS CaseSysType_Name,
           (select col_name from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType_Name,
           --cst.col_code AS CaseSysType_Code,
           (select col_code from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType_Code,
           --cst.col_id AS CaseSysType,
           (select col_id from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType,
           --cst.COL_ICONCODE AS CaseSysType_IconCode,
           (select col_iconcode from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType_IconCode,
           --cst.COL_COLORCODE AS CaseSysType_ColorCode,
           (select col_colorcode from tbl_dict_casesystype where col_id = (select col_casedict_casesystype from tbl_case where col_id = t.col_casetask)) as CaseSysType_ColorCode,
           /*--EXECUTION METHOD*/
           --em.col_name AS ExecutionMethod_Name,
           (select col_name from tbl_dict_executionmethod where col_id = (select col_taskdict_executionmethod from tbl_task where col_id = t.col_id)) as ExecutionMethod_Name,
           --em.col_code AS ExecutionMethod_Code,
           (select col_code from tbl_dict_executionmethod where col_id = (select col_taskdict_executionmethod from tbl_task where col_id = t.col_id)) as ExecutionMethod_Code,
           /*--TASK STATE*/
           --dts.col_id AS TaskState_id,
           (select col_id from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_Id,
           --f_dcm_invokestatenameproc(t.col_id) AS TaskState_Name,
           (select f_dcm_invokestatenameproc(col_id) from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_Name,
           --dts.col_activity AS TaskState_code,
           (select col_activity from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_Code,
           --dts.col_IsDefaultOnCreate AS TaskState_IsDefaultOnCreate,
           (select col_isdefaultoncreate from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsDefaultOnCreate,
           --dts.col_isstart AS TaskState_IsStart,
           (select col_isstart from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsStart,
           --dts.col_canassign AS TaskState_CanAssign,
           (select col_canassign from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_CanAssign,
           --dts.col_IsDefaultOnCreate2 AS TaskState_IsInProcess,
           (select col_isdefaultoncreate2 from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsInProcess,
           --dts.col_isfinish AS TaskState_IsFinish,
           (select col_isfinish from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsFinish,
           --dts.col_isresolve AS TaskState_IsResolve,
           (select col_isresolve from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsResolve,
           --dts.col_isassign AS TaskState_IsAssign,
           (select col_isassign from tbl_dict_taskstate where col_id = (select col_tw_workitemdict_taskstate from tbl_tw_workitem where col_id =
             (select col_tw_workitemtask from tbl_task where col_id = t.col_id))) as TaskState_IsAssign,
			/*--SYSTEM TYPE AND PROCEDURE*/
           t.COL_TASKPROCEDURE AS Procedure_id,
           --p.col_name AS Procedure_name,
           (select col_name from tbl_procedure where col_id = (select col_taskprocedure from tbl_task where col_id = t.col_id)) as Procedure_name,
           /*--TASK STATE CONFIG (Milestones)*/
           --sc.col_id AS StateConfig_id,
           (select col_id from tbl_dict_stateconfig where col_id = (select col_stateconfigtasksystype from tbl_dict_tasksystype where col_id =
             (select col_taskdict_tasksystype from tbl_task where col_id = t.col_id))) as StateConfig_Id,
           --sc.col_name AS StateConfig_Name,
           (select col_name from tbl_dict_stateconfig where col_id = (select col_stateconfigtasksystype from tbl_dict_tasksystype where col_id =
             (select col_taskdict_tasksystype from tbl_task where col_id = t.col_id))) as StateConfig_Name,
           --sc.col_code AS StateConfig_code,
           (select col_code from tbl_dict_stateconfig where col_id = (select col_stateconfigtasksystype from tbl_dict_tasksystype where col_id =
             (select col_taskdict_tasksystype from tbl_task where col_id = t.col_id))) as StateConfig_Code,
           --sc.COL_ISDEFAULT AS StateConfig_IsDefault,
           (select col_isdefault from tbl_dict_stateconfig where col_id = (select col_stateconfigtasksystype from tbl_dict_tasksystype where col_id =
             (select col_taskdict_tasksystype from tbl_task where col_id = t.col_id))) as StateConfig_IsDefault,
           /*--CASE STATE*/
           --dcs.col_id AS CaseState_id,
           (select col_id from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_id,
           --dcs.col_name AS CaseState_Name,
           (select col_name from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_Name,
           --dcs.col_code AS CaseState_Code,
           (select col_code from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_Code,
           --dcs.col_isstart AS CaseState_ISSTART,
           (select col_isstart from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISSTART,
           --dcs.col_isresolve AS CaseState_ISRESOLVE,
           (select col_isresolve from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISRESOLVE,
           --dcs.col_isfinish AS CaseState_ISFINISH,
           (select col_isfinish from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISFINISH,
           --dcs.col_isassign AS CaseState_ISASSIGN,
           (select col_isassign from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISASSIGN,
           --dcs.col_isfix AS CaseState_ISFIX,
           (select col_isstart from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISFIX,
           --dcs.col_isdefaultoncreate2 AS CaseState_ISINPROCESS,
           (select col_isdefaultoncreate2 from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISINPROCESS,
           --dcs.col_isdefaultoncreate AS CaseState_ISDEFAULTONCREATE,
           (select col_isdefaultoncreate from tbl_dict_casestate where col_id = (select col_cw_workitemdict_casestate from tbl_cw_workitem where col_id =
             (select col_cw_workitemcase from tbl_case where col_id = t.col_casetask))) AS CaseState_ISDEFAULTONCREATE,
           --dict_state.col_name AS MS_StateName,
           (select col_name from tbl_dict_state where col_id = (select col_casedict_state from tbl_case where col_id = t.col_casetask)) as MS_StateName,
           /*--OWNERSHIP*/
           --wb.id AS Workbasket_id,
           (select id from vw_ppl_simpleworkbasket where col_id = (select col_taskppl_workbasket from tbl_task where col_id = t.col_id)) as Workbasket_Id,
           --wb.calcname AS Workbasket_name,
           (select calcname from vw_ppl_simpleworkbasket where col_id = (select col_taskppl_workbasket from tbl_task where col_id = t.col_id)) as Workbasket_name,
           --wb.calcname AS Owner_CaseWorker_Name,
           (select calcname from vw_ppl_simpleworkbasket where col_id = (select col_taskppl_workbasket from tbl_task where col_id = t.col_id)) as Owner_CaseWorker_Name,
           --wb.workbaskettype_name AS Workbasket_type_name,
           (select workbaskettype_name from vw_ppl_simpleworkbasket where col_id = (select col_taskppl_workbasket from tbl_task where col_id = t.col_id)) as Workbasket_type_name,
           --wb.workbaskettype_code AS Workbasket_type_code,
           (select workbaskettype_code from vw_ppl_simpleworkbasket where col_id = (select col_taskppl_workbasket from tbl_task where col_id = t.col_id)) as Workbasket_type_code,
           /*--for CASE*/
           --wb2.id AS CaseWorkbasket_id,
           (select id from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_Id,
           --wb2.calcname AS CaseWorkbasket_name,
           (select calcname from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_Name,
           --wb2.calcname AS CaseOwner_CaseWorker_Name,
           (select calcname from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseOwner_CaseWorker_Name,
           --wb2.workbaskettype_name AS CaseWorkbasket_type_name,
           (select workbaskettype_name from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_type_name,
           --wb2.workbaskettype_code AS CaseWorkbasket_type_code,
           (select workbaskettype_code from vw_ppl_simpleworkbasket where col_id = (select col_caseppl_workbasket from tbl_case where col_id = t.col_casetask)) as CaseWorkbasket_type_code,
           /*--RESOLUTION*/
           t.col_taskstp_resolutioncode AS ResolutionCode_Id,
           --rt.col_name AS ResolutionCode_Name,
           (select col_name from tbl_stp_resolutioncode where col_id = (select col_taskstp_resolutioncode from tbl_task where col_id = t.col_id)) as ResolutionCode_Name,
           --rt.col_code AS ResolutionCode_Code,
           (select col_code from tbl_stp_resolutioncode where col_id = (select col_taskstp_resolutioncode from tbl_task where col_id = t.col_id)) as ResolutionCode_Code,
           --rt.col_iconcode AS ResolutionCode_Icon,
           (select col_iconcode from tbl_stp_resolutioncode where col_id = (select col_taskstp_resolutioncode from tbl_task where col_id = t.col_id)) as ResolutionCode_Icon,
           --rt.col_theme AS ResolutionCode_Theme,
           (select col_theme from tbl_stp_resolutioncode where col_id = (select col_taskstp_resolutioncode from tbl_task where col_id = t.col_id)) as ResolutionCode_Theme,
           /*--SLA EVENT DATA BELOW*/
           --Goal SLA
           gsetp.col_id as GoalSlaEventTypeId, gsetp.col_code as GoalSlaEventTypeCode, gsetp.col_name as GoalSlaEventTypeName,
           --(cast(f_DCM_getDateEvtValueByTask(TaskId=>t.col_id, EventTypeId=>gse.col_slaevent_dateeventtype) +
           (cast((select max(de2.col_datevalue) from tbl_dateevent de2 where de2.col_dateeventtask = t.col_id AND de2.col_dateevent_dateeventtype = gse.col_slaevent_dateeventtype) +
             (case when gse.col_intervalds is not null then to_dsinterval(gse.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) +
             (case when gse.col_intervalym is not null then to_yminterval(gse.col_intervalym) else to_yminterval('0-0') end) as timestamp)) as GoalSlaDateTime,
           --DeadLine (DLine) SLA
           dsetp.col_id as DLineSlaEventTypeId, dsetp.col_code as DLineSlaEventTypeCode, dsetp.col_name as DLineSlaEventTypeName,
           --(cast(f_DCM_getDateEvtValueByTask(TaskId=>t.col_id, EventTypeId=>dse.col_slaevent_dateeventtype) +
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
           --tst.col_iconCode AS CALC_ICON
           (select col_iconcode from tbl_dict_tasksystype where col_id = (select col_taskdict_tasksystype from tbl_task where col_id = t.col_id)) as CALC_ICON
FROM
tbl_task t
--INNER JOIN  tbl_case c                      ON t.col_casetask = c.col_id
--INNER JOIN tbl_caseext ce                   ON c.col_id = ce.col_caseextcase
--INNER JOIN  tbl_tw_workitem tw              ON t.col_tw_workitemtask = tw.col_id
--LEFT JOIN  tbl_dict_taskstate dts           ON tw.col_tw_workitemdict_taskstate = dts.col_id
--LEFT JOIN  tbl_procedure p                  ON t.col_taskprocedure = p.col_id
--LEFT JOIN  tbl_dict_tasksystype tst         ON t.col_taskdict_tasksystype = tst.col_id
--LEFT JOIN  TBL_DICT_STATECONFIG sc          ON tst.COL_STATECONFIGTASKSYSTYPE = sc.col_id
--LEFT JOIN  tbl_dict_casesystype cst         ON c.col_casedict_casesystype = cst.col_id
--LEFT JOIN  tbl_task tpt                     ON t.col_parentid = tpt.col_id
--LEFT JOIN  tbl_dict_tasksystype tst_parent  ON tpt.col_taskdict_tasksystype = tst_parent.col_id
--LEFT JOIN  vw_ppl_simpleworkbasket wb       ON wb.id = t.col_taskppl_workbasket
--LEFT JOIN  tbl_stp_resolutioncode rt        ON t.col_taskstp_resolutioncode = rt.col_id
--LEFT JOIN  tbl_dict_executionmethod em      ON em.col_id = t.col_taskdict_executionmethod
--LEFT JOIN  tbl_cw_workitem cw               ON c.col_cw_workitemcase = cw.col_id
--LEFT JOIN  tbl_dict_casestate dcs           ON cw.col_cw_workitemdict_casestate = dcs.col_id
--LEFT JOIN  tbl_int_integtarget it           ON it.col_id = t.COL_INT_INTEGTARGETTASK
--LEFT JOIN  tbl_stp_priority prty            ON c.col_stp_prioritycase = prty.col_id
LEFT JOIN  vw_dcm_taskslaprimaryevent6 tse  ON tse.nexttaskid = t.col_id AND tse.prevtaskid = t.col_id
--LEFT JOIN  vw_ppl_simpleworkbasket wb2      ON wb2.id = c.col_caseppl_workbasket
--LEFT JOIN  tbl_dict_state dict_state        ON c.col_casedict_state = dict_state.col_id
--Goal SLA
LEFT JOIN tbl_dict_slaeventtype gsetp ON gsetp.col_code = 'GOAL'
LEFT JOIN tbl_slaevent gse ON gse.col_slaeventtask = t.col_id AND gse.col_slaeventdict_slaeventtype = gsetp.col_id
  AND (case when tse.nextsladatetime is not null then tse.nextslaeventid when tse.prevsladatetime is not null then tse.prevslaeventid else null end) = gse.col_id
--DeadLine (DLine) SLA
LEFT JOIN tbl_dict_slaeventtype dsetp ON dsetp.col_code = 'DEADLINE'
LEFT JOIN tbl_slaevent dse ON dse.col_slaeventtask = t.col_id AND dse.col_slaeventdict_slaeventtype = dsetp.col_id
  AND (case when tse.nextsladatetime is not null then tse.nextslaeventid when tse.prevsladatetime is not null then tse.prevslaeventid else null end) = dse.col_id