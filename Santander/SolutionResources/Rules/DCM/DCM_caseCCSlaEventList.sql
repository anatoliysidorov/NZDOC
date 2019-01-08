with
s01 as
(select (case when subs2.DateValue is not null then subs2.DateValue else sysdate end) as DateEventValue, tsk.col_id as TaskId, se.col_id as SlaEventId
from tbl_taskcc tsk
inner join tbl_slaeventcc se on tsk.col_id = se.col_slaeventcctaskcc
inner join tbl_casecc cs on tsk.col_casecctaskcc = cs.col_id
left join tbl_dateeventcc des on tsk.col_id = des.col_dateeventcctaskcc
                        and se.col_slaeventcc_dateeventtype = des.col_dateeventcc_dateeventtype
                        and (case when :geLinkedCacheRecords is null then 0
                        when :geLinkedCacheRecords is not null then des.col_id
                        end
                  ) = nvl(des.col_dateeventccdateevent, 0)
left join (select subs1.DateEventId, subs1.DateEventTask, subs1.DateName, subs1.DateValue, subs1.DateEventRowNumber
             from
             (select dec.col_id as DateEventId, dec.col_dateeventcctaskcc as DateEventTask, dec.col_datename as DateName, dec.col_datevalue as DateValue,
                     row_number() over (order by dec.col_datevalue desc) as DateEventRowNumber
              from tbl_dateeventcc dec where dec.col_datename = 'DATE_TASK_CLOSED') subs1
              where subs1.DateEventRowNumber = 1) subs2
             on tsk.col_id = subs2.DateEventTask
where cs.col_id = :CaseId
group by (case when subs2.DateValue is not null then subs2.DateValue else sysdate end), tsk.col_id, se.col_id),
s11 as
(select case
when (((de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se2.col_attemptcount + 1) + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) * (se2.col_attemptcount + 1)) - s01.DateEventValue) > 0)
then ((de2.col_datevalue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se2.col_attemptcount + 1) + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) * (se2.col_attemptcount + 1)) - s01.DateEventValue)
else 999999
end as c11, tsk2.col_id as TaskId, se2.col_id as SlaEventId
from tbl_slaeventcc se2
inner join tbl_taskcc tsk2 on se2.col_slaeventcctaskcc = tsk2.col_id
inner join tbl_tw_workitemcc twi2 on tsk2.col_tw_workitemcctaskcc = twi2.col_id
inner join tbl_casecc cs2 on tsk2.col_casecctaskcc = cs2.col_id
left join tbl_dateeventcc de2 on tsk2.col_id = de2.col_dateeventcctaskcc
                                 and se2.col_slaeventcc_dateeventtype = de2.col_dateeventcc_dateeventtype
                                 and (case when :geLinkedCacheRecords is null then 0
                                 when :geLinkedCacheRecords is not null then de2.col_id
                                 end
                                 ) = nvl(de2.col_dateeventccdateevent, 0)
left join s01 on tsk2.col_id = s01.TaskId and se2.col_id = s01.SlaEventId
where cs2.col_id = :CaseId
group by case
when (((de2.col_DateValue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se2.col_attemptcount + 1) + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) * (se2.col_attemptcount + 1)) - s01.DateEventValue) > 0)
then ((de2.col_DateValue + 
(case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se2.col_attemptcount + 1) + 
(case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) * (se2.col_attemptcount + 1)) - s01.DateEventValue)
else 999999
end, tsk2.col_id, se2.col_id
),
s21 as
(select se.col_id as SlaEventId,
tsk.col_id as TaskId, tsk.col_name as TaskName, tsk.col_taskid as TaskTitle, tsk.col_casecctaskcc as CaseId,
tsk.col_parentidcc as TaskParentId, tsk.col_tw_workitemcctaskcc as TaskWorkitemId,
setp.col_id as SlaEventTypeId, setp.col_code as SlaEventTypeCode, setp.col_name as SlaEventTypeName,
setp.col_intervalds as SlaEventTypeIntervalDS, setp.col_intervalym as SlaEventTypeIntervalYM,
sel.col_id as SlaEventLevelId, sel.col_code as SlaEventLevelCode, sel.col_name as SlaEventCodeName,
det.col_id as DateEventTypeId, det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName,
de.col_id as DateEventId, de.col_datename as DateEventName, de.col_datevalue as DateEventValue, de.col_performedby as DateEventPerformedBy,
cast (de.col_datevalue as timestamp) as DateTimeEventValue,
(cast(de.col_datevalue + 
(case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se.col_attemptcount + 1) + 
(case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) * (se.col_attemptcount + 1) as timestamp)) as SlaDateTime,
greatest(((de.col_datevalue + 
(case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se.col_attemptcount + 1) + 
(case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) * (se.col_attemptcount + 1)) - cast(s01.DateEventValue as timestamp)),
to_dsinterval('0 0' || ':' || '0' || ':' || '0')) as SlaDaysLeft
from tbl_slaeventcc se
inner join tbl_taskcc tsk on se.col_slaeventcctaskcc = tsk.col_id
inner join tbl_tw_workitemcc twi on tsk.col_tw_workitemcctaskcc = twi.col_id
inner join tbl_casecc cs on tsk.col_casecctaskcc = cs.col_id
inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id
inner join tbl_dict_slaeventlevel sel on se.col_slaeventcc_slaeventlevel = sel.col_id
inner join tbl_dict_dateeventtype det on se.col_slaeventcc_dateeventtype = det.col_id
inner join tbl_dateeventcc de on tsk.col_id = de.col_dateeventcctaskcc and 
                                  se.col_slaeventcc_dateeventtype = de.col_dateeventcc_dateeventtype 
                                  --de.col_dateeventccdateevent IS NULL
                                  AND (CASE
                                        WHEN :geLinkedCacheRecords IS NULL THEN 0
                                        WHEN :geLinkedCacheRecords IS NOT NULL THEN de.col_id
                                       END 
                                      ) = NVL(de.col_dateeventccdateevent, 0) 
                                  
left join s01 on tsk.col_id = s01.TaskId and se.col_id = s01.SlaEventId
where
cs.col_id = :CaseId
and
(case
when (((de.col_datevalue + 
(case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se.col_attemptcount + 1) + 
(case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) * (se.col_attemptcount + 1)) - s01.DateEventValue) > 0)
then ((de.col_datevalue + 
(case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (se.col_attemptcount + 1) + 
(case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) * (se.col_attemptcount + 1)) - s01.DateEventValue)
else 999999
end) = (select MAX(c11) from s11 where TaskId = tsk.col_id and SlaEventId = se.col_id)
),
s3 as
(select s1.SlaEventId as SlaEventId, s1.TaskId as TaskId, s1.TaskName as TaskName, s1.TaskTitle as TaskTitle,
s1.CaseId as CaseId, s1.TaskParentId as TaskParentId, s1.TaskWorkitemId as TaskWorkitemId, s1.SlaDateTime as SlaDateTime, s1.SlaDaysLeft as SlaDaysLeft,
add_months(sysdate, trunc(months_between(s1.SlaDateTime, sysdate))) as SlaDateTimeFrom,
trunc(months_between(s1.SlaDateTime, sysdate)) as SlaMonths,
s1.SlaDateTime - add_months(sysdate, trunc(months_between(s1.SlaDateTime, sysdate))) as SlaDaysFrom,
(case when s1.SlaDateTime - add_months(sysdate, trunc(months_between(s1.SlaDateTime, sysdate))) > to_dsinterval('0 0' || ':' || '0' || ':' || '0') then 'Upcoming' else 'Passed' end) as SlaPassed,
s1.SlaEventTypeId as SlaEventTypeId, s1.SlaEventTypeCode as SlaEventTypeCode, s1.SlaEventTypeName as SlaEventTypeName,
s1.SlaEventTypeIntervalDS as SlaEventTypeIntervalDS, s1.SlaEventTypeIntervalYM as SlaEventTypeIntervalYM,
s1.SlaEventLevelId as SlaEventLevelId, s1.SlaEventLevelCode as SlaEventLevelCode, s1.SlaEventCodeName as SlaEventLevelName,
s1.DateEventTypeId as DateEventTypeId, s1.DateEventTypeCode as DateEventTypeCode, s1.DateEventTypeName as DateEventTypeName,
s1.DateEventId as DateEventId, s1.DateEventName as DateEventName, s1.DateEventValue as DateEventValue, s1.DateEventPerformedBy as DateEventPerformedby,
s1.DateTimeEventValue as DateTimeEventValue,
s1.RowNumber as RowNumber
from
(select SlaEventId, TaskId, TaskName, TaskTitle, CaseId, TaskParentId, TaskWorkitemId, SlaDateTime, SlaDaysLeft,
trunc(months_between(SlaDateTime, sysdate)) as trancated,
SlaEventTypeId, SlaEventTypeCode, SlaEventTypeName, SlaEventTypeIntervalDS, SlaEventTypeIntervalYM, SlaEventLevelId, SlaEventLevelCode, SlaEventCodeName,
DateEventTypeId, DateEventTypeCode, DateEventTypeName, DateEventId, DateEventName, DateEventValue, DateEventPerformedBy, DateTimeEventValue,
row_number() over (partition by TaskId order by SlaDateTime asc) as RowNumber
from s21) s1
order by s1.TaskId, s1.SlaDateTime desc)
--ACTUAL SELECT STARTS BELOW
select s31.SlaEventId as Id, s31.SlaEventId as SlaEventId, s31.TaskId, s31.TaskName, s31.TaskTitle,
s31.CaseId, s31.TaskParentId, s31.TaskWorkitemId,
(case when s31.SlaDateTime > s01.DateEventValue then s31.SlaDateTime else null end) as SlaDateTime,
/*s31.SlaDaysLeft,*/
s31.SlaDateTimeFrom, /*s31.SlaDaysFrom,*/ s31.SlaPassed,
(case when s31.SlaMonths > 0 then s31.SlaMonths else 0 end) as SlaMonths,
(case when extract(day from s31.SlaDaysFrom) > 0 then extract(day from s31.SlaDaysFrom) else 0 end) as SlaDays,
(case when extract(hour from s31.SlaDaysFrom) > 0 then extract(hour from s31.SlaDaysFrom) else 0 end) as SlaHours,
(case when extract(minute from s31.SlaDaysFrom) > 0 then extract(minute from s31.SlaDaysFrom) else 0 end) as SlaMinutes,
(case when extract(second from s31.SlaDaysFrom) > 0 then extract(second from s31.SlaDaysFrom) else 0 end) as SlaSeconds,
SlaEventTypeId, SlaEventTypeCode, SlaEventTypeName,
SlaEventTypeIntervalDS, SlaEventTypeIntervalYM,
SlaEventLevelId, SlaEventLevelCode, SlaEventLevelName,
DateEventTypeId, DateEventTypeCode, DateEventTypeName,
DateEventId, DateEventName, s31.DateEventValue, DateEventPerformedby,
DateTimeEventValue
from s3 s31
left join s01 on s31.TaskId = s01.TaskId and s31.SlaEventId = s01.SlaEventId
order by s31.TaskId, s31.SlaEventId