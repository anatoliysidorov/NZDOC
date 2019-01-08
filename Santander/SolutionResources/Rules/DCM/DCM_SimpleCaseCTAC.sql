SELECT --BASIC DATA
	sc.id                          AS ID,
	sc.col_id                      AS COL_ID,
	sc.caseid                      AS CaseId,
	sc.extsysid                    AS ExtSysId,
	sc.integtarget_id              AS IntegTarget_Id,
	sc.summary                     AS SUMMARY,
	sc.description                 AS Description,
	sc.createdby                   AS CreatedBy,
	sc.createddate                 AS CreatedDate,
	sc.modifiedby                  AS ModifiedBy,
	sc.modifieddate                AS ModifiedDate,
	sc.dateassigned                AS DateAssigned,
	sc.dateclosed                  AS DateClosed,
	sc.manualworkduration          AS ManualWorkDuration,
	sc.manualdateresolved          AS ManualDateResolved,
	sc.resolutiondescription       AS ResolutionDescription,
	sc.draft                       AS Draft,
	sc.casefrom                    AS CaseFrom,
	--CASE TYPE
	sc.casesystype_id              AS CaseSysType_Id,
	sc.casesystype_name            AS CaseSysType_Name,
	sc.casesystype_code            AS CaseSysType_Code,
	sc.casesystype_iconcode        AS CaseSysType_IconCode,
	sc.casesystype_colorcode       AS CaseSysType_ColorCode,
	--WORKITEM
	sc.workitem_id                 AS Workitem_Id,
	sc.workitem_activity           AS Workitem_Activity,
	sc.workitem_workflow           AS Workitem_Workflow,
	--PRIORITY
	sc.priority_id                 AS Priority_Id,
	sc.priority_name               AS Priority_Name,
	sc.priority_value              AS Priority_Value,
	--CASE STATE
	sc.casestate_id                AS CaseState_Id,
	sc.casestate_name              AS CaseState_name,
	sc.casestate_isstart           AS CaseState_ISSTART,
	sc.casestate_isresolve         AS CaseState_ISRESOLVE,
	sc.casestate_isfinish          AS CaseState_ISFINISH,
	sc.casestate_isassign          AS CaseState_ISASSIGN,
	sc.casestate_isfix             AS CaseState_ISFIX,
	sc.casestate_isinprocess       AS CaseState_ISINPROCESS,
	sc.casestate_isdefaultoncreate AS CaseState_ISDEFAULTONCREATE,
	--OWNERSHIP
	sc.workbasket_id               AS Workbasket_id,
	sc.workbasket_name             AS Workbasket_name,
	sc.owner_caseworker_name       AS Owner_CaseWorker_Name,
	sc.workbasket_type_name        AS Workbasket_type_name,
	sc.workbasket_type_code        AS Workbasket_type_code,
	--RESOLUTION
	sc.resolutioncode_id           AS ResolutionCode_Id,
	sc.resolutioncode_name         AS ResolutionCode_Name,
	sc.resolutioncode_code         AS ResolutionCode_Code,
	sc.resolutioncode_icon         AS ResolutionCode_Icon,
	sc.resolutioncode_theme        AS ResolutionCode_Theme,
	sc.hoursspent                  AS HoursSpent
FROM   vw_dcm_simplecase sc
WHERE sc.CaseSysType_Id in (select ct.col_id
from tbl_dict_casesystype ct
 where 1 in (select Allowed from table(f_dcm_getCaseworkerAccessFn2(p_AccessObjectId => (select ao.col_id
                                                                      from tbl_ac_accessobject ao
                                                                      inner join tbl_dict_casesystype cst on ao.col_accessobjectcasesystype = cst.col_id
                                                                      inner join tbl_ac_accessobjecttype aot on ao.col_accessobjaccessobjtype = aot.col_id
                                                                      where lower(aot.col_code) = 'case_type' and cst.col_id = ct.col_id),
                                                 p_CaseId => null,
                                                 p_CaseworkerId => (select id
                                                                    from vw_ppl_activecaseworkersusers
                                                                    where accode = sys_context('CLIENTCONTEXT', 'AccessSubject')),
                                                 p_PermissionId => (select col_id from tbl_ac_permission where col_code = 'VIEW' and col_permissionaccessobjtype =
                                                                    (select col_id from tbl_ac_accessobjecttype where col_code = 'CASE_TYPE')),
                                                 p_TaskId => null)) where caseworkertype = 'CASEWORKER'))