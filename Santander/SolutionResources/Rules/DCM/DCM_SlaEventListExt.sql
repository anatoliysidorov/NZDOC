select sel.SlaEventId as SlaEventId, sel.SlaEventId as COL_ID, sel.TaskId as TaskId, sel.TaskName as TaskName, sel.TaskTitle as TaskTitle,
sel.CaseId as CaseId, sel.TaskParentId as TaskParentId, sel.TaskWorkitemId as TaskWorkitemId,
sel.SlaDateTime as SlaDateTime,
sel.SlaDaysLeft as SlaDaysLeft,
sel.SlaDateTimeFrom as SlaDateTimeFrom, sel.SlaDaysFrom as SlaDaysFrom, sel.SlaPassed as SlaPassed,
sel.SlaMonths as SlaMonths,
sel.SlaDays as SlaDays,
sel.SlaHours as SlaHours,
sel.SlaMinutes as SlaMinutes,
sel.SlaSeconds as SlaSeconds,
sel.SlaEventTypeId as SlaEventTypeId, sel.SlaEventTypeCode as SlaEventTypeCode, sel.SlaEventTypeName as SlaEventTypeName,
sel.SlaEventTypeIntervalDS as SlaEventTypeIntervalDS, sel.SlaEventTypeIntervalYM as SlaEventTypeIntervalYM,
sel.SlaEventLevelId as SlaEventLevelId, sel.SlaEventLevelCode as SlaEventLevelCode, sel.SlaEventLevelName as SlaEventLevelName,
sel.DateEventTypeId as DateEventTypeId, sel.DateEventTypeCode as DateEventTypeCode, sel.DateEventTypeName as DateEventTypeName,
sel.DateEventId as DateEventId, sel.DateEventName as DateEventName, sel.DateEventValue as DateEventValue, sel.DateEventPerformedby DateEventPerformedby,
sel.DateTimeEventValue as DateTimeEventValue,
ts.col_name as TaskStateName, ts.col_code as TaskStateCode, ts.col_activity as TaskStateActivity,
cst.col_name as CaseStateName, cst.col_code as CaseStateCode, cst.col_activity as CaseStateActivity
from vw_DCM_SlaEventList sel
inner join tbl_tw_workitem twi on sel.taskworkitemid = twi.col_id
inner join tbl_dict_taskstate ts on twi.col_tw_workitemdict_taskstate = ts.col_id
inner join tbl_case cs on sel.caseid = cs.col_id
inner join tbl_cw_workitem cwi on cs.col_cw_workitemcase = cwi.col_id
inner join tbl_dict_casestate cst on cwi.col_cw_workitemdict_casestate = cst.col_id
order by sel.slaeventid