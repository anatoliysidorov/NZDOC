with s11 as
(select s.SlaEventId, s.TaskId,
s.SlaEventTypeId, s.SlaEventTypeCode, s.SlaEventTypeName, s.SlaEventTypeIntervalDS, s.SlaEventTypeIntervalYM, s.SlaEventLevelId, s.SlaEventLevelCode, s.SlaEventLevelName,
s.DateEventTypeId, s.DateEventTypeCode, s.DateEventTypeName,
s.DateEventValue,
s.DateTimeEventValue, s.SlaDateTime, s.SlaDaysLeft
from
(select se2.col_id as SlaEventId,
se2.col_slaeventtask as TaskId,
setp2.col_id as SlaEventTypeId, setp2.col_code as SlaEventTypeCode, setp2.col_name as SlaEventTypeName,
setp2.col_intervalds as SlaEventTypeIntervalDS, setp2.col_intervalym as SlaEventTypeIntervalYM,
sel2.col_id as SlaEventLevelId, sel2.col_code as SlaEventLevelCode, sel2.col_name as SlaEventLevelName,
det2.col_id as DateEventTypeId, det2.col_code as DateEventTypeCode,
det2.col_name as DateEventTypeName,
nvl(se2.col_finishdateeventvalue,sysdate) as DateEventValue,
cast (se2.col_startdateeventvalue as timestamp) as DateTimeEventValue,
cast(se2.col_slaeventdate as timestamp) as SlaDateTime,
greatest(se2.col_slaeventdate - cast(nvl(se2.col_finishdateeventvalue,sysdate) as timestamp), to_dsinterval('0 0' || ':' || '0' || ':' || '0')) as SlaDaysLeft,
row_number() over (partition by se2.col_slaeventtask order by (
case when (se2.col_slaeventdate - nvl(se2.col_finishdateeventvalue,sysdate)) > 0 then (se2.col_slaeventdate - nvl(se2.col_finishdateeventvalue,sysdate))
else
999999 end)) as RowNumber
from tbl_slaevent se2
inner join tbl_dict_slaeventtype setp2 on se2.col_slaeventdict_slaeventtype = setp2.col_id
inner join tbl_dict_slaeventlevel sel2 on se2.col_slaevent_slaeventlevel = sel2.col_id
inner join tbl_dict_dateeventtype det2 on se2.col_slaevent_dateeventtype = det2.col_id
where se2.col_isprimary = 1
) s
where s.RowNumber = 1),
s12 as
(select s.SlaEventId, s.TaskId,
s.SlaEventTypeId, s.SlaEventTypeCode, s.SlaEventTypeName, s.SlaEventTypeIntervalDS, s.SlaEventTypeIntervalYM, s.SlaEventLevelId, s.SlaEventLevelCode, s.SlaEventLevelName,
s.DateEventTypeId, s.DateEventTypeCode, s.DateEventTypeName,
s.DateEventValue,
s.DateTimeEventValue, s.SlaDateTime, s.SlaDaysLeft
from
(select se2.col_id as SlaEventId,
se2.col_slaeventtask as TaskId,
setp2.col_id as SlaEventTypeId, setp2.col_code as SlaEventTypeCode, setp2.col_name as SlaEventTypeName,
setp2.col_intervalds as SlaEventTypeIntervalDS, setp2.col_intervalym as SlaEventTypeIntervalYM,
sel2.col_id as SlaEventLevelId, sel2.col_code as SlaEventLevelCode, sel2.col_name as SlaEventLevelName,
det2.col_id as DateEventTypeId, det2.col_code as DateEventTypeCode,
det2.col_name as DateEventTypeName,
nvl(se2.col_finishdateeventvalue,sysdate) as DateEventValue,
cast (se2.col_startdateeventvalue as timestamp) as DateTimeEventValue,
cast(se2.col_slaeventdate as timestamp) as SlaDateTime,
greatest(cast(nvl(se2.col_finishdateeventvalue,sysdate) as timestamp) - se2.col_slaeventdate, to_dsinterval('0 0' || ':' || '0' || ':' || '0')) as SlaDaysLeft,
row_number() over (partition by se2.col_slaeventtask order by (
case when (nvl(se2.col_finishdateeventvalue,sysdate) - se2.col_slaeventdate) > 0 then (nvl(se2.col_finishdateeventvalue,sysdate) - se2.col_slaeventdate)
else
999999 end)) as RowNumber
from tbl_slaevent se2
inner join tbl_dict_slaeventtype setp2 on se2.col_slaeventdict_slaeventtype = setp2.col_id
inner join tbl_dict_slaeventlevel sel2 on se2.col_slaevent_slaeventlevel = sel2.col_id
inner join tbl_dict_dateeventtype det2 on se2.col_slaevent_dateeventtype = det2.col_id
where se2.col_isprimary = 1
) s
where s.RowNumber = 1)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select NextSlaEventId, NextTaskId,
(case when NextSlaDateTime > s11DateEventValue then NextSlaDateTime else null end) as NextSlaDateTime,
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
NextDateEventValue,
NextDateTimeEventValue,
PrevSlaEventId, PrevTaskId,
(case when PrevSlaDateTime < s12DateEventValue then PrevSlaDateTime else null end) as PrevSlaDateTime,
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
PrevDateEventValue,
PrevDateTimeEventValue
from
(select s1.SlaEventId as NextSlaEventId, s1.TaskId as NextTaskId,
s1.SlaDateTime as NextSlaDateTime, s1.SlaDaysLeft as NextSlaDaysLeft,
add_months(sysdate, trunc(months_between(s1.SlaDateTime, sysdate))) as NextSlaDateTimeFrom,
trunc(months_between(s1.SlaDateTime, sysdate)) as NextSlaMonths,
s1.SlaDateTime - add_months(sysdate, trunc(months_between(s1.SlaDateTime, sysdate))) as NextSlaDaysFrom,
s1.SlaEventTypeId as NextSlaEventTypeId, s1.SlaEventTypeCode as NextSlaEventTypeCode, s1.SlaEventTypeName as NextSlaEventTypeName,
s1.SlaEventTypeIntervalDS as NextSlaEventTypeIntervalDS, s1.SlaEventTypeIntervalYM as NextSlaEventTypeIntervalYM,
s1.SlaEventLevelId as NextSlaEventLevelId, s1.SlaEventLevelCode as NextSlaEventLevelCode, s1.SlaEventLevelName as NextSlaEventLevelName,
s1.DateEventTypeId as NextDateEventTypeId, s1.DateEventTypeCode as NextDateEventTypeCode, s1.DateEventTypeName as NextDateEventTypeName,
s1.DateEventValue as NextDateEventValue,
s1.DateTimeEventValue as NextDateTimeEventValue,
s1.s11DateEventValue as s11DateEventValue,
s2.SlaEventId as PrevSlaEventId, s2.TaskId as PrevTaskId,
s2.SlaDateTime as PrevSlaDateTime, s2.SlaDaysLeft as PrevSlaDaysLeft,
trunc(months_between(sysdate, s2.SlaDateTime)) as PrevSlaMonths,
add_months(s2.SlaDateTime, trunc(months_between(sysdate, s2.SlaDateTime))) as PrevSlaDateTimeFrom,
cast(sysdate as timestamp) - add_months(s2.SlaDateTime, trunc(months_between(sysdate, s2.SlaDateTime))) as PrevSlaDaysFrom,
s2.SlaEventTypeId as PrevSlaEventTypeId, s2.SlaEventTypeCode as PrevSlaEventTypeCode, s2.SlaEventTypeName as PrevSlaEventTypeName,
s2.SlaEventTypeIntervalDS as PrevSlaEventTypeIntervalDS, s2.SlaEventTypeIntervalYM as PrevSlaEventTypeIntervalYM,
s2.SlaEventLevelId as PrevSlaEventLevelId, s2.SlaEventLevelCode as PrevSlaEventLevelCode, s2.SlaEventLevelName as PrevSlaEventLevelName,
s2.DateEventTypeId as PrevDateEventTypeId, s2.DateEventTypeCode as PrevDateEventTypeCode, s2.DateEventTypeName as PrevDateEventTypeName,
s2.DateEventValue as PrevDateEventValue,
s2.DateTimeEventValue as PrevDateTimeEventValue
,s2.s12DateEventValue as s12DateEventValue
from
(select s11.SlaEventId, s11.TaskId,
s11.SlaDateTime, s11.SlaDaysLeft,
trunc(months_between(s11.SlaDateTime, sysdate)) as trancated,
s11.SlaEventTypeId, s11.SlaEventTypeCode, s11.SlaEventTypeName, s11.SlaEventTypeIntervalDS, s11.SlaEventTypeIntervalYM, s11.SlaEventLevelId, s11.SlaEventLevelCode, s11.SlaEventLevelName,
s11.DateEventTypeId, s11.DateEventTypeCode, s11.DateEventTypeName,
s11.DateEventValue,
s11.DateTimeEventValue,
s11.DateEventValue as s11DateEventValue
from s11) s1
left join
(select s12.SlaEventId, s12.TaskId,
s12.SlaDateTime, s12.SlaDaysLeft,
s12.SlaEventTypeId, s12.SlaEventTypeCode, s12.SlaEventTypeName, s12.SlaEventTypeIntervalDS, s12.SlaEventTypeIntervalYM, s12.SlaEventLevelId, s12.SlaEventLevelCode, s12.SlaEventLevelName,
s12.DateEventTypeId, s12.DateEventTypeCode, s12.DateEventTypeName,
s12.DateEventValue,
s12.DateTimeEventValue,
s12.DateEventValue as s12DateEventValue
from s12) s2 on s1.TaskId = s2.TaskId)