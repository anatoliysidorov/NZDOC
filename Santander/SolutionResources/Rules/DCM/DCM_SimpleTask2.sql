SELECT --BASIC DATA
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
       --INTEGRATION
       t.col_ExtSysId AS ExtSysId,
       t.COL_INT_INTEGTARGETTASK AS IntegTarget_Id,
       it.col_name AS IntegTarget_Name,
       --CASE
       c.col_summary AS Summary,
       ce.col_description AS Case_Description,
       c.col_caseid AS CaseId_Name,
       c.col_draft AS Case_Draft,
       c.col_cw_workitemcase AS Case_WORKITEM,
       --CASE PRIORITY
       prty.col_id AS Priority_Id,
       prty.col_name AS Priority_Name,
       prty.col_value AS Priority_Value,
       --TASK TYPE
       tst.col_name AS TaskSysType_Name,
       tst.col_code AS TaskSysType_Code,
       tst.col_id AS TaskSysType,
       --PARENT TASK
       tpt.col_name AS ParentTask_Name,
       tpt.col_taskid AS ParentTask_TaskId,
       tst_parent.col_name AS ParentTask_Type_Name,
       tst_parent.col_code AS ParentTask_Type_Code,
       --CASE TYPE
       cst.col_name AS CaseSysType_Name,
       cst.col_code AS CaseSysType_Code,
       cst.col_id AS CaseSysType,
       cst.COL_ICONCODE AS CaseSysType_IconCode,
       cst.COL_COLORCODE AS CaseSysType_ColorCode,
       --EXECUTION METHOD
       em.col_name AS ExecutionMethod_Name,
       em.col_code AS ExecutionMethod_Code,
       --TASK STATE
       dts.col_id AS TaskState_id,
       --dts.col_name AS TaskState_name,
       f_dcm_invokestatenameproc(t.col_id) AS TaskState_Name,
       dts.col_activity AS TaskState_code,
       dts.col_isstart AS TaskState_IsStart,
       dts.col_canassign AS TaskState_CanAssign,
       dts.col_isfinish AS TaskState_IsFinish,
       dts.col_isresolve AS TaskState_IsResolve,
       --CASE STATE
       dcs.col_id AS CaseState_id,
       dcs.col_name AS CaseState_Name,
       dcs.col_code AS CaseState_Code,
       --OWNERSHIP
       wb.id AS Workbasket_id,
       wb.calcname AS Workbasket_name,
       wb.calcname AS Owner_CaseWorker_Name,
       wb.workbaskettype_name AS Workbasket_type_name,
       wb.workbaskettype_code AS Workbasket_type_code,
       --for CASE
       wb2.id AS CaseWorkbasket_id,
       wb2.calcname AS CaseWorkbasket_name,
       wb2.calcname AS CaseOwner_CaseWorker_Name,
       wb2.workbaskettype_name AS CaseWorkbasket_type_name,
       wb2.workbaskettype_code AS CaseWorkbasket_type_code,
       --RESOLUTION
       t.col_taskstp_resolutioncode AS ResolutionCode_Id,
       rt.col_name AS ResolutionCode_Name,
       rt.col_code AS ResolutionCode_Code,
       rt.col_iconcode AS ResolutionCode_Icon,
       rt.col_theme AS ResolutionCode_Theme,
       --CALCULATED
       tst.col_iconCode AS CALC_ICON
  FROM tbl_task t
       LEFT JOIN tbl_case c ON t.col_casetask = c.col_id
       INNER JOIN tbl_caseext ce ON c.col_id = ce.col_caseextcase
       LEFT JOIN tbl_tw_workitem tw ON t.col_tw_workitemtask = tw.col_id
       LEFT JOIN tbl_dict_taskstate dts ON tw.col_tw_workitemdict_taskstate = dts.col_id
       LEFT JOIN tbl_dict_tasksystype tst ON t.col_taskdict_tasksystype = tst.col_id
       LEFT JOIN tbl_dict_casesystype cst ON c.col_casedict_casesystype = cst.col_id
       LEFT JOIN tbl_task tpt ON t.col_parentid = tpt.col_id
       LEFT JOIN tbl_dict_tasksystype tst_parent ON tpt.col_taskdict_tasksystype = tst_parent.col_id
       LEFT JOIN vw_ppl_simpleworkbasket wb ON (wb.id = t.col_taskppl_workbasket)
       LEFT JOIN tbl_stp_resolutioncode rt ON t.col_taskstp_resolutioncode = rt.col_id
       LEFT JOIN tbl_dict_executionmethod em ON em.col_id = t.col_taskdict_executionmethod
       LEFT JOIN tbl_dict_casestate dcs ON dcs.col_id = c.col_cw_workitemcase
       LEFT JOIN tbl_int_integtarget it ON it.col_id = t.COL_INT_INTEGTARGETTASK
       LEFT JOIN tbl_stp_priority prty ON c.col_stp_prioritycase = prty.col_id
       LEFT JOIN vw_ppl_simpleworkbasket wb2 ON (wb2.id = c.col_caseppl_workbasket)