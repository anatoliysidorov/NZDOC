with
s01 as
(select s.DateEventValue, s.TaskId, s.SlaEventId, s.RowNumber
from
(
select (case when dec.col_datevalue is not null then dec.col_datevalue else sysdate end) as DateEventValue, tsk.col_id as TaskId, se.col_id as SlaEventId,
row_number() over (partition by tsk.col_id order by (case when dec.col_datevalue is not null then dec.col_datevalue else sysdate end) asc) as RowNumber
from tbl_task tsk
inner join tbl_slaevent se on tsk.col_id = se.col_slaeventtask
inner join tbl_case cs on tsk.col_casetask = cs.col_id
inner join tbl_dateevent des on tsk.col_id = des.col_dateeventtask and se.col_slaevent_dateeventtype = des.col_dateevent_dateeventtype
left join tbl_dateevent dec on tsk.col_id = dec.col_dateeventtask and dec.col_datename = 'DATE_TASK_CLOSED') s
where s.RowNumber = 1),
s02 as
(select s.DateEventValue, s.TaskId, s.SlaEventId, s.RowNumber  
from
(
select (case when dec.col_datevalue is not null then dec.col_datevalue else sysdate end) as DateEventValue, tsk.col_id as TaskId, se.col_id as SlaEventId,
row_number() over (partition by tsk.col_id order by (case when dec.col_datevalue is not null then dec.col_datevalue else sysdate end) desc) as RowNumber
from tbl_task tsk
inner join tbl_slaevent se on tsk.col_id = se.col_slaeventtask
inner join tbl_case cs on tsk.col_casetask = cs.col_id
inner join tbl_dateevent des on tsk.col_id = des.col_dateeventtask and se.col_slaevent_dateeventtype = des.col_dateevent_dateeventtype
left join tbl_dateevent dec on tsk.col_id = dec.col_dateeventtask and dec.col_datename = 'DATE_TASK_CLOSED') s
where s.RowNumber = 1),
s11 as
(select s.SlaEventId, s.TaskId, s.TaskName, s.TaskTitle, s.CaseId, s.TaskParentId, s.TaskWorkitemId,
s.SlaEventTypeId, s.SlaEventTypeCode, s.SlaEventTypeName, s.SlaEventTypeIntervalDS, s.SlaEventTypeIntervalYM, s.SlaEventLevelId, s.SlaEventLevelCode, s.SlaEventLevelName,
s.DateEventTypeId, s.DateEventTypeCode, s.DateEventTypeName, s.DateEventId, s.DateEventName, s.DateEventValue, s.DateEventPerformedBy, s.DateTimeEventValue, s.SlaDateTime, s.SlaDaysLeft,
s.RowNumber
from
(select se2.col_id as SlaEventId,
tsk2.col_id as TaskId, tsk2.col_name as TaskName, tsk2.col_taskid as TaskTitle, tsk2.col_casetask as CaseId, tsk2.col_parentid as TaskParentId,
twi2.col_id as TaskWorkitemId,
setp2.col_id as SlaEventTypeId, setp2.col_code as SlaEventTypeCode, setp2.col_name as SlaEventTypeName,
setp2.col_intervalds as SlaEventTypeIntervalDS, setp2.col_intervalym as SlaEventTypeIntervalYM,
sel2.col_id as SlaEventLevelId, sel2.col_code as SlaEventLevelCode, sel2.col_name as SlaEventLevelName,
det2.col_id as DateEventTypeId, det2.col_code as DateEventTypeCode, det2.col_name as DateEventTypeName,
de2.col_id as DateEventId, de2.col_datename as DateEventName, de2.col_datevalue as DateEventValue, de2.col_performedby as DateEventPerformedBy,
cast (de2.col_datevalue as timestamp) as DateTimeEventValue,
(cast(de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) /* * (se2.col_attemptcount + 1) */ + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ as timestamp)) as SlaDateTime,
greatest(((de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) /* * (se2.col_attemptcount + 1) */ + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ ) - cast(s01.DateEventValue as timestamp)), to_dsinterval('0 0' || ':' || '0' || ':' || '0')) as SlaDaysLeft,
row_number() over (partition by tsk2.col_id order by (case
when (((de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) /* * (se2.col_attemptcount + 1) */ + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ ) - s01.DateEventValue) > 0)
then ((de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) /* * (se2.col_attemptcount + 1) */ + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ ) - s01.DateEventValue)
else 999999
end) asc) as RowNumber
from tbl_slaevent se2
inner join tbl_task tsk2 on se2.col_slaeventtask = tsk2.col_id
inner join tbl_tw_workitem twi2 on tsk2.col_tw_workitemtask = twi2.col_id
inner join tbl_case cs2 on tsk2.col_casetask = cs2.col_id
inner join tbl_dict_slaeventtype setp2 on se2.col_slaeventdict_slaeventtype = setp2.col_id
inner join tbl_dict_slaeventlevel sel2 on se2.col_slaevent_slaeventlevel = sel2.col_id
inner join tbl_dict_dateeventtype det2 on se2.col_slaevent_dateeventtype = det2.col_id
inner join tbl_dateevent de2 on tsk2.col_id = de2.col_dateeventtask and se2.col_slaevent_dateeventtype = de2.col_dateevent_dateeventtype
inner join s01 on tsk2.col_id = s01.TaskId) s
where s.RowNumber = 1),
s12 as
(select s.SlaEventId, s.TaskId, s.TaskName, s.TaskTitle, s.CaseId, s.TaskParentId, s.TaskWorkitemId,
s.SlaEventTypeId, s.SlaEventTypeCode, s.SlaEventTypeName, s.SlaEventTypeIntervalDS, s.SlaEventTypeIntervalYM, s.SlaEventLevelId, s.SlaEventLevelCode, s.SlaEventLevelName,
s.DateEventTypeId, s.DateEventTypeCode, s.DateEventTypeName, s.DateEventId, s.DateEventName, s.DateEventValue, s.DateEventPerformedBy, s.DateTimeEventValue, s.SlaDateTime, s.SlaDaysLeft,
s.RowNumber
from
(select se2.col_id as SlaEventId,
tsk2.col_id as TaskId, tsk2.col_name as TaskName, tsk2.col_taskid as TaskTitle, tsk2.col_casetask as CaseId, tsk2.col_parentid as TaskParentId,
twi2.col_id as TaskWorkitemId,
setp2.col_id as SlaEventTypeId, setp2.col_code as SlaEventTypeCode, setp2.col_name as SlaEventTypeName,
setp2.col_intervalds as SlaEventTypeIntervalDS, setp2.col_intervalym as SlaEventTypeIntervalYM,
sel2.col_id as SlaEventLevelId, sel2.col_code as SlaEventLevelCode, sel2.col_name as SlaEventLevelName,
det2.col_id as DateEventTypeId, det2.col_code as DateEventTypeCode, det2.col_name as DateEventTypeName,
de2.col_id as DateEventId, de2.col_datename as DateEventName, de2.col_datevalue as DateEventValue, de2.col_performedby as DateEventPerformedBy,
cast (de2.col_datevalue as timestamp) as DateTimeEventValue,
(cast(de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) /* * (se2.col_attemptcount + 1) */ + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ as timestamp)) as SlaDateTime,
greatest((cast(s02.DateEventValue as timestamp) - (de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) /* * (se2.col_attemptcount + 1) */ + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ )), to_dsinterval('0 0' || ':' || '0' || ':' || '0')) as SlaDaysLeft,
row_number() over (partition by tsk2.col_id order by (case
when ((s02.DateEventValue - (de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) /* * (se2.col_attemptcount + 1) */ + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ ) ) > 0)
then (s02.DateEventValue - (de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) /* * (se2.col_attemptcount + 1) */ + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ ))
else 999999
end) asc) as RowNumber
from tbl_slaevent se2
inner join tbl_task tsk2 on se2.col_slaeventtask = tsk2.col_id
inner join tbl_tw_workitem twi2 on tsk2.col_tw_workitemtask = twi2.col_id
inner join tbl_case cs2 on tsk2.col_casetask = cs2.col_id
inner join tbl_dict_slaeventtype setp2 on se2.col_slaeventdict_slaeventtype = setp2.col_id
inner join tbl_dict_slaeventlevel sel2 on se2.col_slaevent_slaeventlevel = sel2.col_id
inner join tbl_dict_dateeventtype det2 on se2.col_slaevent_dateeventtype = det2.col_id
inner join tbl_dateevent de2 on tsk2.col_id = de2.col_dateeventtask and se2.col_slaevent_dateeventtype = de2.col_dateevent_dateeventtype
inner join s02 on tsk2.col_id = s02.TaskId) s
where s.RowNumber = 1)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select NextSlaEventId, NextTaskId, NextTaskName, NextTaskTitle,
NextCaseId, NextTaskParentId, NextTaskWorkitemId,
(case when NextSlaDateTime > s01DateEventValue then NextSlaDateTime else null end) as NextSlaDateTime,
NextSlaDaysLeft,
NextSlaDateTimeFrom, NextSlaDaysFrom,
(case when NextSlaMonths > 0 then NextSlaMonths else 0 end) as NextSlaMonths,
(case when extract(day from NextSlaDaysFrom) > 0 then extract(day from NextSlaDaysFrom) else 0 end) as NextSlaDays,
(case when extract(hour from NextSlaDaysFrom) > 0 then extract(hour from NextSlaDaysFrom) else 0 end) as NextSlaHours,
(case when extract(minute from NextSlaDaysFrom) > 0 then extract(minute from NextSlaDaysFrom) else 0 end) as NextSlaMinutes,
(case when extract(second from NextSlaDaysFrom) > 0 then extract(second from NextSlaDaysFrom) else 0 end) as NextSlaSeconds,
NextSlaEventTypeId, NextSlaEventTypeCode, NextSlaEventTypeName,
NextSlaEventTypeIntervalDS, NextSlaEventTypeIntervalYM,
NextSlaEventLevelId, NextSlaEventLevelCode, NextSlaEventLevelName,
NextDateEventTypeId, NextDateEventTypeCode, NextDateEventTypeName,
NextDateEventId, NextDateEventName, NextDateEventValue, NextDateEventPerformedby,
NextDateTimeEventValue,
PrevSlaEventId, PrevTaskId, PrevTaskName, PrevTaskTitle,
PrevCaseId, PrevTaskParentId, PrevTaskWorkitemId,
(case when PrevSlaDateTime < s02DateEventValue then PrevSlaDateTime else null end) as PrevSlaDateTime,
PrevSlaDaysLeft,
PrevSlaDateTimeFrom, PrevSlaDaysFrom,
(case when PrevSlaMonths > 0 then PrevSlaMonths else 0 end) as PrevSlaMonths,
(case when extract(day from PrevSlaDaysFrom) > 0 then extract(day from PrevSlaDaysFrom) else 0 end) as PrevSlaDays,
(case when extract(hour from PrevSlaDaysFrom) > 0 then extract(hour from PrevSlaDaysFrom) else 0 end) as PrevSlaHours,
(case when extract(minute from PrevSlaDaysFrom) > 0 then extract(minute from PrevSlaDaysFrom) else 0 end) as PrevSlaMinutes,
(case when extract(second from PrevSlaDaysFrom) > 0 then extract(second from PrevSlaDaysFrom) else 0 end) as PrevSlaSeconds,
PrevSlaEventTypeId, PrevSlaEventTypeCode, PrevSlaEventTypeName,
PrevSlaEventTypeIntervalDS, PrevSlaEventTypeIntervalYM,
PrevSlaEventLevelId, PrevSlaEventLevelCode, PrevSlaEventLevelName,
PrevDateEventTypeId, PrevDateEventTypeCode, PrevDateEventTypeName,
PrevDateEventId, PrevDateEventName, PrevDateEventValue, PrevDateEventPerformedBy,
PrevDateTimeEventValue
from
(select s1.SlaEventId as NextSlaEventId, s1.TaskId as NextTaskId, s1.TaskName as NextTaskName, s1.TaskTitle as NextTaskTitle,
s1.CaseId as NextCaseId, s1.TaskParentId as NextTaskParentId, s1.TaskWorkitemId as NextTaskWorkitemId, s1.SlaDateTime as NextSlaDateTime, s1.SlaDaysLeft as NextSlaDaysLeft,
add_months(sysdate, trunc(months_between(s1.SlaDateTime, sysdate))) as NextSlaDateTimeFrom,
trunc(months_between(s1.SlaDateTime, sysdate)) as NextSlaMonths,
s1.SlaDateTime - add_months(sysdate, trunc(months_between(s1.SlaDateTime, sysdate))) as NextSlaDaysFrom,
s1.SlaEventTypeId as NextSlaEventTypeId, s1.SlaEventTypeCode as NextSlaEventTypeCode, s1.SlaEventTypeName as NextSlaEventTypeName,
s1.SlaEventTypeIntervalDS as NextSlaEventTypeIntervalDS, s1.SlaEventTypeIntervalYM as NextSlaEventTypeIntervalYM,
s1.SlaEventLevelId as NextSlaEventLevelId, s1.SlaEventLevelCode as NextSlaEventLevelCode, s1.SlaEventLevelName as NextSlaEventLevelName,
s1.DateEventTypeId as NextDateEventTypeId, s1.DateEventTypeCode as NextDateEventTypeCode, s1.DateEventTypeName as NextDateEventTypeName,
s1.DateEventId as NextDateEventId, s1.DateEventName as NextDateEventName, s1.DateEventValue as NextDateEventValue, s1.DateEventPerformedBy as NextDateEventPerformedby,
s1.DateTimeEventValue as NextDateTimeEventValue,
s1.s01DateEventValue as s01DateEventValue,
s2.SlaEventId as PrevSlaEventId, s2.TaskId as PrevTaskId, s2.TaskName as PrevTaskName, s2.TaskTitle as PrevTaskTitle,
s2.CaseId as PrevCaseId, s2.TaskParentId as PrevTaskParentId, s2.TaskWorkitemId as PrevTaskWorkitemId, s2.SlaDateTime as PrevSlaDateTime, s2.SlaDaysLeft as PrevSlaDaysLeft,
trunc(months_between(sysdate, s2.SlaDateTime)) as PrevSlaMonths,
add_months(s2.SlaDateTime, trunc(months_between(sysdate, s2.SlaDateTime))) as PrevSlaDateTimeFrom,
cast(sysdate as timestamp) - add_months(s2.SlaDateTime, trunc(months_between(sysdate, s2.SlaDateTime))) as PrevSlaDaysFrom,
s2.SlaEventTypeId as PrevSlaEventTypeId, s2.SlaEventTypeCode as PrevSlaEventTypeCode, s2.SlaEventTypeName as PrevSlaEventTypeName,
s2.SlaEventTypeIntervalDS as PrevSlaEventTypeIntervalDS, s2.SlaEventTypeIntervalYM as PrevSlaEventTypeIntervalYM,
s2.SlaEventLevelId as PrevSlaEventLevelId, s2.SlaEventLevelCode as PrevSlaEventLevelCode, s2.SlaEventLevelName as PrevSlaEventLevelName,
s2.DateEventTypeId as PrevDateEventTypeId, s2.DateEventTypeCode as PrevDateEventTypeCode, s2.DateEventTypeName as PrevDateEventTypeName,
s2.DateEventId as PrevDateEventId, s2.DateEventName as PrevDateEventName, s2.DateEventValue as PrevDateEventValue, s2.DateEventPerformedBy as PrevDateEventPerformedBy,
s2.DateTimeEventValue as PrevDateTimeEventValue,
s2.s02DateEventValue as s02DateEventValue
from
(select s11.SlaEventId, s11.TaskId, s11.TaskName, s11.TaskTitle, s11.CaseId, s11.TaskParentId, s11.TaskWorkitemId, s11.SlaDateTime, s11.SlaDaysLeft,
trunc(months_between(s11.SlaDateTime, sysdate)) as trancated,
s11.SlaEventTypeId, s11.SlaEventTypeCode, s11.SlaEventTypeName, s11.SlaEventTypeIntervalDS, s11.SlaEventTypeIntervalYM, s11.SlaEventLevelId, s11.SlaEventLevelCode, s11.SlaEventLevelName,
s11.DateEventTypeId, s11.DateEventTypeCode, s11.DateEventTypeName, s11.DateEventId, s11.DateEventName, s11.DateEventValue, s11.DateEventPerformedBy, s11.DateTimeEventValue,
s01.DateEventValue as s01DateEventValue
from s11
left join s01 on s11.TaskId = s01.TaskId) s1
left join
(select s12.SlaEventId, s12.TaskId, s12.TaskName, s12.TaskTitle, s12.CaseId, s12.TaskParentId, s12.TaskWorkitemId, s12.SlaDateTime, s12.SlaDaysLeft,
s12.SlaEventTypeId, s12.SlaEventTypeCode, s12.SlaEventTypeName, s12.SlaEventTypeIntervalDS, s12.SlaEventTypeIntervalYM, s12.SlaEventLevelId, s12.SlaEventLevelCode, s12.SlaEventLevelName,
s12.DateEventTypeId, s12.DateEventTypeCode, s12.DateEventTypeName, s12.DateEventId, s12.DateEventName, s12.DateEventValue, s12.DateEventPerformedBy, s12.DateTimeEventValue,
s02.DateEventValue as s02DateEventValue
from s12
left join s02 on s12.TaskId = s02.TaskId) s2 on s1.TaskId = s2.TaskId)