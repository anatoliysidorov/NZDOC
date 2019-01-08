SELECT     T.col_id                                         AS ID,
           T.col_id                                         AS COL_ID,
           T.col_description                                AS Description,
           T.col_enabled                                    AS Enabled,
           T.col_icon                                       AS Icon,
           T.col_leaf                                       AS Leaf,
           T.col_depth                                      AS Depth,
           T.col_name                                       AS NAME,
           T.col_required                                   AS REQUIRED,
           T.col_taskid                                     AS TaskId,
           T.col_taskorder                                  AS TaskOrder,
           T.col_parentid                                   AS ParentId,
           T.col_taskdict_tasksystype                       AS TaskSysTypeId,
           tst.col_name                                     AS TaskSysType_Name,
           tst.col_code                                     AS TaskSysType_Code,
           T.col_pagecode                                   AS PageCode,
           T.col_taskstp_resolutioncode                     AS TASKSTP_RESOLUTIONCODE,
           T.col_modifiedby                                 AS ModifiedBy,
           T.col_modifieddate                               AS ModifiedDate,
           T.col_resolutiondescription                      AS ResolutionDescription,
           T.col_createdby                                  AS CreatedBy,
           T.col_createddate                                AS CreatedDate,
           te.col_id                                        AS TaskExt_Id,
           proc.col_id                                      AS ProcedureId,
           em.col_id                                        AS ExecutionMethod_id,
           em.col_name                                      AS ExecutionMethod_Name,
           em.col_code                                      AS ExecutionMethod_Code,
           wi.col_id                                        AS WorkItem_Id,
           wi.col_workflow                                  AS WorkItem_Workflow,
           wi.col_tw_workitemdict_taskstate                 AS WorkItem_TaskStateId,
           dts.col_id                                       AS TaskState_Id,
           dts.col_activity                                 AS WorkItem_Activity,
           dts.col_name                                     AS WorkItem_Activity_Name2,
           F_dcm_invokestatenameproc(t.col_id)              AS WorkItem_Activity_Name,
           dts.col_name                                     AS TaskState_Name2,
           F_dcm_invokestatenameproc(t.col_id)              AS TaskState_Name,
           dts.col_code                                     AS TaskState_Code,
           wb.id                                            AS Workbasket_id,
           wb.calcname                                      AS Workbasket_name,
           wb.calcname                                      AS Owner_CaseWorker_Name,
           wb.emailaddress                                  AS Workbasket_email,
		   wb.ACCESSSUBJECTCODE                             AS Workbasket_ACC,
           wb.workbaskettype_id                             AS WorkbasketType_Id,
           wb.workbaskettype_name                           AS WorkbasketType_Name,
           wb.workbaskettype_code                           AS WorkbasketType_Code,
           wb.Caseworker_Id                                 AS CaseWorker_Id,
           wb.calcname                                      AS CaseWorker_Name,
           NULL                                             AS CaseWorker_Email,
           NULL                                             AS CaseWorker_Photo,
           NULL                                             AS CaseWorker_ACCode,
           pri.col_id                                       AS Case_Priority,
           pri.col_name                                     AS Case_Priority_Name,
           pri.col_icon                                     AS Case_Priority_Icon,
           pri.col_value                                    AS Case_Priority_Value,
           rc.col_id                                        AS ResolutionCode_Id,
           rc.col_code                                      AS ResolutionCode_Code,
           rc.col_name                                      AS ResolutionCode_Name,
           F_util_unparseduration(T.col_manualworkduration) AS ManualWorkDuration,
           T.col_manualdateresolved                         AS ManualDateResolved,
           cs.col_id                                        AS Case_Id,
           cse.col_id                                       AS Case_Ext_Id,
           cs.col_caseid                                    AS Case_CaseId,
           cs.col_summary                                   AS Case_Summary,
           dcst.col_id                                      AS CaseSysType_Id,
           dcst.col_name                                    AS CaseSysType_Name,
           dcst.col_code                                    AS CaseSysType_Code,
           wbc.id                                           AS Case_CaseWorker_Id,
           wbc.calcname                                     AS Case_CaseWorker_Name,
           null                                             AS Case_CaseWorker_Photo,
           --SLA EVENT DATA BELOW
           tse.nextsladatetime       AS NextSlaDateTime,
           tse.nextslaeventtypename  AS NextSlaEventTypename,
           tse.nextslaeventlevelname AS NextSlaEventLevelName,
           tse.prevsladatetime       AS PrevSlaDateTime,
           tse.prevslaeventtypename  AS PrevSlaEventTypename,
           tse.prevslaeventlevelname AS PrevSlaEventLevelName
FROM       tbl_task                     T
left join  tbl_taskext                  te   ON T.col_id = te.col_taskexttask
inner join tbl_case                     cs   ON t.col_casetask = cs.col_id
left join  tbl_caseserviceext           cse  ON cs.col_id = cse.col_casecaseserviceext
left join  tbl_stp_priority             pri  ON cs.col_stp_prioritycase = pri.col_id
left join  tbl_dict_casesystype         dcst ON cs.col_casedict_casesystype = dcst.col_id
left join  tbl_procedure                proc ON cs.col_id = proc.col_proceduredict_casesystype
left join  tbl_dict_executionmethod     em   ON(em.col_id = T.col_taskdict_executionmethod)
inner join tbl_tw_workitem              wi   ON(wi.col_id = T.col_tw_workitemtask)
inner join tbl_dict_taskstate           dts  ON wi.col_tw_workitemdict_taskstate = dts.col_id
left join  tbl_stp_resolutioncode       rc   ON T.col_taskstp_resolutioncode = rc.col_id
left join  tbl_dict_tasksystype         tst  ON T.col_taskdict_tasksystype = tst.col_id
           --task ownernship
left join  vw_ppl_simpleworkbasket wb ON(wb.id = t.col_taskppl_workbasket)
           --case ownernship
left join  vw_ppl_simpleworkbasket wbc ON(wbc.id = cs.col_caseppl_workbasket)
           -- sla
left join  vw_dcm_taskslaevent6 tse ON T.col_id = tse.nexttaskid AND T.col_id = tse.prevtaskid