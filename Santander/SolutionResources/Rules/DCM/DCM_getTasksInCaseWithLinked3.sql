select vtsk.id as id,
       vtsk.case_id as Case_Id,
       vtsk.childcaseid as ChildCaseId,
       vtsk.childtaskid as ChildTaskId,
       level as TaskLevel,
       vtsk.name as name,
       vtsk.taskid as taskid,
       vtsk.taskext_id as TaskExt_Id,	
       vtsk.description as description,
       vtsk.enabled as enabled,
       vtsk.icon as icon,
       vtsk.leaf as leaf,
       vtsk.required as required,
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

       vtsk.PERM_CASETYPE_VIEW as PERM_CASETYPE_VIEW,

       vtsk.AssignorName as AssignorName,
       vtsk.AssigneeName as AssigneeName,
       
       
       vtsk.NextSlaDateTime as NextSlaDateTime,
       vtsk.nextslaeventtypename                         AS NextSlaEventTypename, 
       vtsk.nextslaeventlevelname                        AS NextSlaEventLevelName, 
       vtsk.PrevSlaDateTime                              AS PrevSlaDateTime,
       vtsk.prevslaeventtypename                         AS PrevSlaEventTypename, 
       vtsk.prevslaeventlevelname                        AS PrevSlaEventLevelName
from
(select ptsk.id as id, ptsk.case_id as Case_Id, ptsk.taskext_id as TaskExt_Id, DBMS_LOB.SUBSTR(ptsk.description, 1, 200) as description, ptsk.enabled as enabled, ptsk.icon as icon,
        ptsk.leaf as leaf, ptsk.name as name, ptsk.required as required,
        ptsk.taskid as taskid, ptsk.taskorder as taskorder, ptsk.parentid as parentid, ptsk.CaseSysType_Id as CaseSysType_Id, ptsk.executionmethod_id as executionmethod_id,
        ptsk.executionmethod_name as executionmethod_name, ptsk.executionmethod_code as executionmethod_code, ptsk.workitem_id as workitem_id, ptsk.workitem_workflow as workitem_workflow,
        ptsk.workitem_activity as workitem_activity, ptsk.workitem_activity_name as workitem_activity_name, ptsk.workbasket_id as workbasket_id, ptsk.workbasket_name as workbasket_name,
        ptsk.workbaskettype_id as workbaskettype_id, ptsk.workbaskettype_name as workbaskettype_name, ptsk.workbaskettype_code as workbaskettype_code, ptsk.caseworker_id as caseworker_id,
        ptsk.caseworker_name as caseworker_name, ptsk.tasksystypeid as tasksystypeid, ptsk.procedureid as procedureid, ptsk.PageCode as PageCode, ptsk.TaskState_Name as TaskState_Name,
        ptsk.TaskState_Code as TaskState_Code, ptsk.ResolutionCode_Id as ResolutionCode_Id, ptsk.ResolutionCode_Name as ResolutionCode_Name, ptsk.ResolutionCode_Code as ResolutionCode_Code,
        cast(ptsk.ResolutionDescription as nvarchar2(2000)) as ResolutionDescription, ptsk.ManualWorkDuration as ManualWorkDuration, ptsk.ManualDateResolved as ManualDateResolved,
        case when (1 in (select Allowed from table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE',p_PermissionCode =>'VIEW')) where CaseTypeId = ptsk.casesystype_id)) then 1
            else 0 end as PERM_CASETYPE_VIEW,
        (select assignorname from table(f_DCM_getTaskOwnerProxy2(TaskId => ptsk.Id))) as AssignorName,
        (select assigneename from table(f_DCM_getTaskOwnerProxy2(TaskId => ptsk.Id))) as AssigneeName,
        case when f_dcm_getTaskClosedState2(StateConfigId => (select nvl(tst.col_stateconfigtasksystype,0)
                                                             from tbl_dict_tasksystype tst
                                                             inner join tbl_task tsk on tst.col_id = tsk.col_taskdict_tasksystype
                                                             where tsk.col_id = ptsk.Id)) <> ptsk.workitem_activity
            then ptsk.nextsladatetime
            else null end                                AS NextSlaDateTime,
        ptsk.nextslaeventtypename                         AS NextSlaEventTypename, 
        ptsk.nextslaeventlevelname                        AS NextSlaEventLevelName, 
        case when f_dcm_getTaskClosedState2(StateConfigId => (select nvl(tst.col_stateconfigtasksystype,0)
                                                             from tbl_dict_tasksystype tst
                                                             inner join tbl_task tsk on tst.col_id = tsk.col_taskdict_tasksystype
                                                             where tsk.col_id = ptsk.Id)) <> ptsk.workitem_activity
            then ptsk.prevsladatetime
            else null end                                AS PrevSlaDateTime,
        ptsk.prevslaeventtypename                         AS PrevSlaEventTypename, 
        ptsk.prevslaeventlevelname                        AS PrevSlaEventLevelName,
        ccs.col_id                                    AS ChildCaseId,
        ctsk.col_id                                   AS ChildTaskId
from vw_dcm_task ptsk
left join tbl_caselink cl on ptsk.ID = cl.col_caselinkparenttask
left join tbl_case ccs on cl.col_caselinkchildcase = ccs.col_id
left join tbl_task ctsk on cl.col_caselinkchildtask = ctsk.col_id
where ptsk.Case_Id = :Case_Id
and (:Filter_Code IS NULL OR(UPPER(:Filter_Code) = 'ALL'))
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'ACTIVE' AND ptsk.TASKSTATE_CODE IN ('STARTED','ASSIGNED','IN_PROCESS','RESOLVED'))") %>
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'CLOSED' AND ptsk.TASKSTATE_CODE = 'CLOSED')") %>
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'OVERDUE' AND ptsk.PREVSLADATETIME IS NOT NULL)") %>
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'DUE_SOON' AND ptsk.TASKSTATE_CODE ='CLOSED' AND ptsk.PREVSLADATETIME IS NOT NULL)") %>
<%= IFNOTNULL(":Filter_Code","OR(UPPER(:Filter_Code) = 'DUE_SOON' AND ptsk.TASKSTATE_CODE ='CLOSED' AND TO_DATE(TO_CHAR(NEXTSLADATETIME, 'mm.dd.yyyy'),'mm.dd.yyyy') <= (TRUNC(SYSDATE,'dd') + F_DCM_GETSCALARSETTING(2,'DAYS_UPCOMING_SLA')))") %>
) vtsk
connect by prior vtsk.id = vtsk.parentid
start with vtsk.parentid = 0
order siblings by vtsk.taskorder