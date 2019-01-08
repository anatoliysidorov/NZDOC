SELECT vtsk.id                                          AS id, 
       vtsk.description                                 AS description, 
       vtsk.enabled                                     AS enabled, 
       vtsk.icon                                        AS icon, 
       vtsk.leaf                                        AS leaf, 
       vtsk.name                                        AS name, 
       vtsk.required                                    AS required, 
       vtsk.taskid                                      AS taskid, 
       vtsk.taskext_id                                  AS TaskExt_Id, 
       vtsk.taskorder                                   AS taskorder, 
       vtsk.parentid                                    AS parentid, 
       vtsk.executionmethod_id                          AS executionmethod_id, 
       vtsk.executionmethod_name                        AS executionmethod_name, 
       vtsk.executionmethod_code                        AS executionmethod_code, 
       vtsk.workitem_id                                 AS workitem_id, 
       vtsk.workbasket_id                               AS workbasket_id, 
       vtsk.workbasket_name                             AS workbasket_name, 
       vtsk.workbaskettype_id                           AS workbaskettype_id, 
       vtsk.workbaskettype_name                         AS workbaskettype_name, 
       vtsk.workbaskettype_code                         AS workbaskettype_code, 
       vtsk.caseworker_id                               AS caseworker_id, 
       vtsk.caseworker_name                             AS caseworker_name, 
       vtsk.caseworker_email                            AS caseworker_email, 
       vtsk.caseworker_photo                            AS caseworker_photo, 
       vtsk.tasksystypeid                               AS tasksystype_id, 
	   vtsk.tasksystype_name                             AS tasksystype_name, 
       vtsk.procedureid                                 AS procedureid, 
       vtsk.pagecode                                    AS PageCode, 
       vtsk.taskstate_name                              AS TaskState_Name, 
       vtsk.taskstate_code                              AS TaskState_Code, 
       vtsk.resolutioncode_id                           AS ResolutionCode_Id, 
       vtsk.resolutioncode_name                         AS ResolutionCode_Name, 
       vtsk.resolutioncode_code                         AS ResolutionCode_Code, 
       vtsk.resolutiondescription                       AS ResolutionDescription , 
       F_util_unparseduration (vtsk.manualworkduration) AS ManualWorkDuration, 
       vtsk.manualdateresolved                          AS ManualDateResolved, 
       vtsk.modifieddate                                AS ModifiedDate, 
       cw_cb.name                                       AS CreatedBy_Name, 
       cw_cb.email                                      AS CreatedBy_Email, 
       cw_cb.photo                                      AS CreatedBy_Photo, 
	  vtsk.TaskState_Name 								as TaskState_Name,
       vtsk.TaskState_Code 								as TaskState_Code,
	   cw_mb.name                                       AS ModifiedBy_Name, 
       cw_mb.email                                      AS ModifiedBy_Email, 
       cw_mb.photo                                      AS ModifiedBy_Photo, 
	   
       --SLA EVENT DATA BELOW 
       vtsk.nextsladatetime                             AS NextSlaDateTime, 
       vtsk.nextslaeventtypename                        AS NextSlaEventTypename, 
       vtsk.nextslaeventlevelname                       AS NextSlaEventLevelName, 
       vtsk.prevsladatetime                             AS PrevSlaDateTime, 
       vtsk.prevslaeventtypename                        AS PrevSlaEventTypename, 
       vtsk.prevslaeventlevelname                       AS PrevSlaEventLevelName,
       --
       
       vtsk.CASE_ID                                     AS Case_Id,
	   vtsk.CASE_EXT_ID                                 AS Case_Ext_Id,
       vtsk.CASE_CASEID                                 AS Case_CaseId,
       vtsk.CASE_SUMMARY                                AS Case_Summary,
       vtsk.CASE_CASEWORKER_NAME                        AS Case_CaseWorker_Name,

       case when (1 in (select Allowed from table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE',p_PermissionCode =>'DETAIL')) where CaseTypeId = vtsk.casesystype_id)) then 1
            else 0 end as PERM_CASETYPE_VIEW,

       (select assignorname from table(f_DCM_getTaskOwnerProxy2(TaskId => vtsk.Id))) as AssignorName,
       (select assigneename from table(f_DCM_getTaskOwnerProxy2(TaskId => vtsk.Id))) as AssigneeName,

      (SELECT  d.COL_ACTIVITYTIMEDATE     
       FROM (SELECT  th.COL_ACTIVITYTIMEDATE
               FROM TBL_HISTORY th
              WHERE th.COL_HISTORYTASK = :Task_Id
              ORDER BY th.COL_ACTIVITYTIMEDATE DESC) d
              WHERE ROWNUM <= 1)                        AS LastActivityDate
      
       
       
FROM   vw_dcm_task vtsk 
       --ATTACH INVOVLED PEOPLE HERE 
       left join vw_ppl_caseworkersusers cw_cb 
              ON cw_cb.accode = vtsk.createdby 
		 left join vw_ppl_caseworkersusers cw_mb 
              ON cw_mb.accode = vtsk.modifiedby 
WHERE  vtsk.id = :Task_Id