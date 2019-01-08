select 
       vtsk.id as id,
       level,
       vtsk.taskext_id as TaskExt_Id,    
       vtsk.description as description,
       vtsk.enabled as enabled,
       vtsk.icon as icon,
       vtsk.leaf as leaf,
       vtsk.name as name,
       vtsk.required as required,
       vtsk.taskid as taskid,
       vtsk.taskorder as taskorder,
       vtsk.parentid as parentid,
       vtsk.CaseSysType_Id as CaseSysType_Id,
       vtsk.executionmethod_id as executionmethod_id,
       vtsk.executionmethod_name as executionmethod_name,
       vtsk.executionmethod_code as executionmethod_code,
       vtsk.workitem_id as workitem_id,
       vtsk.workitem_workflow as workitem_workflow,
       vtsk.workitem_activity as workitem_activity,
       vtsk.workitem_activity_name as workitem_activity_name,
       vtsk.workbasket_id as workbasket_id,
       vtsk.workbasket_name as workbasket_name,
       vtsk.workbaskettype_id as workbaskettype_id,
       vtsk.workbaskettype_name as workbaskettype_name,
       vtsk.workbaskettype_code as workbaskettype_code,
       vtsk.caseworker_id as caseworker_id,
       vtsk.caseworker_name as caseworker_name,
       vtsk.tasksystypeid as tasksystypeid,
       vtsk.procedureid as procedureid,
       vtsk.PageCode as PageCode,
       vtsk.TaskState_Name as TaskState_Name,
       vtsk.TaskState_Code as TaskState_Code,
       vtsk.ResolutionCode_Id as ResolutionCode_Id,
       vtsk.ResolutionCode_Name as ResolutionCode_Name,
       vtsk.ResolutionCode_Code as ResolutionCode_Code,
       vtsk.ResolutionDescription as ResolutionDescription,
       vtsk.ManualWorkDuration as ManualWorkDuration,
       vtsk.ManualDateResolved as ManualDateResolved,

       case when (1 in (select Allowed from table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE',p_PermissionCode =>'VIEW')) where CaseTypeId = vtsk.casesystype_id)) then 1
            else 0 end as PERM_CASETYPE_VIEW,

       (select assignorname from table(f_DCM_getTaskOwnerProxy2(TaskId => vtsk.Id))) as AssignorName,
       (select assigneename from table(f_DCM_getTaskOwnerProxy2(TaskId => vtsk.Id))) as AssigneeName,
       
       case when f_dcm_getTaskClosedState2(StateConfigId => (select nvl(tst.col_stateconfigtasksystype,0)
                                                             from tbl_dict_tasksystype tst
                                                             inner join tbl_task tsk on tst.col_id = tsk.col_taskdict_tasksystype
                                                             where tsk.col_id = vtsk.Id)) <> vtsk.workitem_activity
            then vtsk.nextsladatetime
            else null end                                AS NextSlaDateTime,
       vtsk.nextslaeventtypename                         AS NextSlaEventTypename, 
       vtsk.nextslaeventlevelname                        AS NextSlaEventLevelName, 
       case when f_dcm_getTaskClosedState2(StateConfigId => (select nvl(tst.col_stateconfigtasksystype,0)
                                                             from tbl_dict_tasksystype tst
                                                             inner join tbl_task tsk on tst.col_id = tsk.col_taskdict_tasksystype
                                                             where tsk.col_id = vtsk.Id)) <> vtsk.workitem_activity
            then vtsk.prevsladatetime
            else null end                                AS PrevSlaDateTime,
       vtsk.prevslaeventtypename                         AS PrevSlaEventTypename, 
       vtsk.prevslaeventlevelname                        AS PrevSlaEventLevelName 
from   vw_dcm_task vtsk
where vtsk.case_id = :Case_Id
connect by prior vtsk.id = vtsk.parentid
start with vtsk.parentid = 0
    AND (:Filter_Code IS NULL OR(UPPER(:Filter_Code) = 'ALL'))
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'ACTIVE' AND vtsk.TASKSTATE_CODE IN ('STARTED','ASSIGNED','IN_PROCESS','RESOLVED'))") %>
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'CLOSED' AND vtsk.TASKSTATE_CODE = 'CLOSED')") %>
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'OVERDUE' AND vtsk.PREVSLADATETIME IS NOT NULL)") %>
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'DUE_SOON' AND vtsk.TASKSTATE_CODE ='CLOSED' AND vtsk.PREVSLADATETIME IS NOT NULL)") %>
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'DUE_SOON' AND vtsk.TASKSTATE_CODE ='CLOSED' AND TO_DATE(TO_CHAR(NEXTSLADATETIME, 'mm.dd.yyyy'),'mm.dd.yyyy') <= (TRUNC(SYSDATE,'dd') + F_DCM_GETSCALARSETTING(2,'DAYS_UPCOMING_SLA')))") %>
ORDER SIBLINGS BY vtsk.TASKORDER ASC