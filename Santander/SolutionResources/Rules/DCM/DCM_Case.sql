SELECT c.col_id                                       AS ID,
       c.col_id                                       AS COL_ID,
       c.col_caseid                                   AS CaseId,
       c.col_summary                                  AS SUMMARY,
       ce.col_description                             AS Description,
       C.col_createdby                                AS CreatedBy,
       F_getnamefromaccesssubject(c.col_createdby)    AS CreatedBy_Name,
       c.col_createddate                              AS CreatedDate,
       c.col_modifiedby                               AS ModifiedBy,
       F_getnamefromaccesssubject(c.col_modifiedby)   AS ModifiedBy_Name,
       c.col_modifieddate                             AS ModifiedDate,
       c.col_procedurecase                            AS Procedure_Id,
       c.col_resolveby                                AS ResolveBy,
       c.col_casefrom                                 AS CaseFrom,
       -------------------------------------------------------
       cse.col_id                                     AS CaseServiceExt_Id,
       cse.col_modifiedby                             AS CSvcExt_ModifiedBy,
       F_getnamefromaccesssubject(cse.col_modifiedby) AS CSvcExt_ModifiedBy_Name,
       cse.col_modifieddate                           AS CSvcExt_ModifiedDate,
       ------------------------------------------------------------------
       prty.col_id                                    AS Priority_Id,
       prty.col_name                                  AS Priority_Name,
       prty.col_icon                                  AS Priority_Icon,
       prty.col_value                                 AS Priority_Value,
       -----------------------------------------------------------
       cw.col_id                                      AS WorkItem_Id,
       cw.col_workflow                                AS WorkItem_Workflow,
       dts.col_id                                     AS CaseState_Id,
       dts.col_activity                               AS WorkItem_Activity,
       dts.col_name                                   AS WorkItem_Activity_Name,
       -----------------------------------------------------------
       wb.col_id                                      AS Workbasket_id,
       wb.col_name                                    AS Workbasket_name,
       wbt.col_code                                   AS WorkbasketType_Code,
       cw2.accode                                     AS Owner_CaseWorker_Accode,
	   cw2.id                                         AS Owner_CaseWorker_Id,
       cw2.name                                       AS Owner_CaseWorker_Name,
       cw2.photo                                      AS Owner_CaseWorker_Photo,
       cw2.email                                      AS Owner_CaseWorker_Email,
       ------------------------------------------------------------
       cst.col_id                                     AS CaseSysType_Id,
       cst.col_name                                   AS CaseSysType_Name,
       cst.col_code                                   AS CaseSysType_Code,
       ------------------------------------------------------------
       c.col_stp_resolutioncodecase                   AS ResolutionCode_Id,
       rc.col_name                                    AS ResolutionCode_Name,
       rc.col_code                                    AS ResolutionCode_Code,
       ------------------------------------------------------------
       c.col_manualworkduration                       AS ManualWorkDuration,
       c.col_manualdateresolved                       AS ManualDateResolved,
       ce.col_resolutiondescription                   AS ResolutionDescription
FROM   tbl_case c
       inner join tbl_caseext ce on c.col_id = ce.col_caseextcase
       left join tbl_caseserviceext cse ON c.col_id = cse.col_casecaseserviceext
       left join tbl_stp_priority prty ON c.col_stp_prioritycase = prty.col_id
       left join tbl_cw_workitem cw ON c.col_cw_workitemcase = cw.col_id
       inner join tbl_dict_casestate dts ON cw.col_cw_workitemdict_casestate = dts.col_id
       left join tbl_dict_casesystype cst ON c.col_casedict_casesystype = cst.col_id
       left join tbl_ppl_workbasket wb ON c.col_caseppl_workbasket = wb.col_id
       left join tbl_dict_workbaskettype wbt ON wb.col_workbasketworkbaskettype = wbt.col_id
       left join vw_ppl_caseworkersusers cw2 ON wb.col_caseworkerworkbasket = cw2.id
       left join tbl_stp_resolutioncode rc ON c.col_stp_resolutioncodecase = rc.col_id