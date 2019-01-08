SELECT     --BASIC DATA
       c.col_id AS ID,
       c.col_id AS COL_ID,
       c.col_caseid AS CaseId,
       c.col_extsysid AS ExtSysId,
       c.col_int_integtargetcase AS IntegTarget_Id,
       c.col_summary AS SUMMARY,
       (select col_description from tbl_caseext where col_caseextcase = c.col_id) AS Description,
       c.col_createdby AS CreatedBy,
       c.col_createddate AS CreatedDate,
       c.col_modifiedby AS ModifiedBy,
       c.col_modifieddate AS ModifiedDate,
       c.col_dateassigned AS DateAssigned,
       c.col_dateclosed AS DateClosed,
       c.col_manualworkduration AS ManualWorkDuration,
       c.col_manualdateresolved AS ManualDateResolved,
       NULL AS ResolutionDescription,
       c.col_draft AS Draft,
       c.col_casefrom AS CaseFrom,
       --CASE TYPE
       c.col_casedict_casesystype AS CaseSysType_Id,
       cst.col_name AS CaseSysType_Name,
       cst.col_code AS CaseSysType_Code,
       cst.col_iconcode AS CaseSysType_IconCode,
       cst.col_colorcode AS CaseSysType_ColorCode,
       cst.col_usedatamodel AS CaseSysType_UseDataModel,
       cst.col_isdraftmodeavail AS CaseSysType_IsDraftModeAvail,
       --WORKITEM
       c.col_cw_workitemcase AS Workitem_Id,
       c.col_activity AS Workitem_Activity,
       c.col_workflow AS Workitem_Workflow,
       --PRIORITY
       c.col_stp_prioritycase AS Priority_Id,
       prty.col_name AS Priority_Name,
       prty.col_value AS Priority_Value,
       --CASE STATE
       c.col_casedict_casestate AS CaseState_Id,
       dts.col_name AS CaseState_name,
       dts.col_isstart AS CaseState_ISSTART,
       dts.col_isresolve AS CaseState_ISRESOLVE,
       dts.col_isfinish AS CaseState_ISFINISH,
       dts.col_isassign AS CaseState_ISASSIGN,
       dts.col_isfix AS CaseState_ISFIX,
       dts.col_isdefaultoncreate2 AS CaseState_ISINPROCESS,
       dts.col_isdefaultoncreate AS CaseState_ISDEFAULTONCREATE,
       --OWNERSHIP
       c.col_caseppl_workbasket AS Workbasket_Id,
       wb.calcname AS Workbasket_name,
       wb.calcname AS Owner_CaseWorker_Name,
       wb.workbaskettype_name AS Workbasket_type_name,
       wb.workbaskettype_code AS Workbasket_type_code,
       --RESOLUTION
       c.col_stp_resolutioncodecase AS ResolutionCode_Id,
       rc.col_name AS ResolutionCode_Name,
       rc.col_code AS ResolutionCode_Code,
       rc.col_iconcode AS ResolutionCode_Icon,
       rc.col_theme AS ResolutionCode_Theme,
       --(SELECT SUM (col_hoursspent) FROM tbl_dcm_workactivity WHERE col_workactivitycase = c.col_id) AS HoursSpent,
       --MILESTONE
       c.col_casedict_state AS MS_StateId,
       dict_state.col_name AS MS_StateName
    ----
  FROM tbl_case c
  	   --INNER JOIN tbl_caseext ce ON c.col_id = ce.col_caseextcase
       LEFT JOIN tbl_stp_priority prty ON c.col_stp_prioritycase = prty.col_id
       LEFT JOIN tbl_dict_casestate dts ON c.col_casedict_casestate = dts.col_id
       LEFT JOIN tbl_dict_casesystype cst ON c.col_casedict_casesystype = cst.col_id
       LEFT JOIN vw_ppl_simpleworkbasket wb ON (wb.id = c.col_caseppl_workbasket)
       LEFT JOIN tbl_stp_resolutioncode rc ON c.col_stp_resolutioncodecase = rc.col_id
       LEFT JOIN tbl_dict_state dict_state ON c.col_casedict_state = dict_state.col_id