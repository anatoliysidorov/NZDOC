with s01 as (
select
/*(case when subs2.datevalue is not null then subs2.datevalue else sysdate end) as dateeventvalue,*/
subs2.datevalue as dateeventvalue,tsk.col_id as taskid,se.col_id as slaeventid
from tbl_task tsk
inner join tbl_slaevent se on tsk.col_id = se.col_slaeventtask
inner join tbl_case cs on tsk.col_casetask = cs.col_id
left join tbl_dateevent des on tsk.col_id = des.col_dateeventtask and se.col_slaevent_dateeventtype = des.col_dateevent_dateeventtype
left join
(select subs1.dateeventid,subs1.dateeventtask,subs1.datename,subs1.datevalue,subs1.dateeventrownumber
from
(select dec.col_id as dateeventid, dec.col_dateeventtask as dateeventtask,dec.col_datename as datename,dec.col_datevalue as datevalue,
row_number() over(partition by dec.col_dateeventtask order by dec.col_datevalue desc) as dateeventrownumber
from tbl_dateevent dec
where dec.col_datename = 'DATE_TASK_CLOSED') subs1
where subs1.dateeventrownumber = 1) subs2 on tsk.col_id = subs2.dateeventtask
),
s11 as (
select case when (((de2.col_datevalue +
                    (case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') end) +
                    (case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ ) - s01.dateeventvalue) > 0)
                    then ((de2.col_datevalue +
                    (case when se2.col_intervalds is not null then to_dsinterval(se2.col_intervalds) else to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') end) +
                    (case when se2.col_intervalym is not null then to_yminterval(se2.col_intervalym) else to_yminterval('0-0') end) /* * (se2.col_attemptcount + 1) */ ) - s01.dateeventvalue)
                else 999999
        end as c11,
        tsk2.col_id as taskid,se2.col_id as slaeventid
from tbl_slaevent se2
inner join tbl_task tsk2 on se2.col_slaeventtask = tsk2.col_id
inner join tbl_tw_workitem twi2 on tsk2.col_tw_workitemtask = twi2.col_id
inner join tbl_case cs2 on tsk2.col_casetask = cs2.col_id
inner join tbl_dateevent de2 on tsk2.col_id = de2.col_dateeventtask
                             and se2.col_slaevent_dateeventtype = de2.col_dateevent_dateeventtype
left join s01 on tsk2.col_id = s01.taskid and se2.col_id = s01.slaeventid
),
s21 as (
select se.col_id as slaeventid,tsk.col_id as taskid,tsk.col_name as taskname,tsk.col_taskid as tasktitle,tsk.col_casetask as caseid,tsk.col_parentid as taskparentid,
       tsk.col_tw_workitemtask as taskworkitemid,setp.col_id as slaeventtypeid,setp.col_code as slaeventtypecode,setp.col_name as slaeventtypename,setp.col_intervalds as slaeventtypeintervalds,
       setp.col_intervalym as slaeventtypeintervalym,sel.col_id as slaeventlevelid,sel.col_code as slaeventlevelcode,sel.col_name as slaeventcodename,det.col_id as dateeventtypeid,
       det.col_code as dateeventtypecode,det.col_name as dateeventtypename,de.col_id as dateeventid,de.col_datename as dateeventname,de.col_datevalue as dateeventvalue,
       de.col_performedby as dateeventperformedby,
       cast(de.col_datevalue as timestamp) as datetimeeventvalue,
       (cast(de.col_datevalue +
       (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') end) +
       (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) /* * (se.col_attemptcount + 1) */ as timestamp) ) as sladatetime,
       greatest(((de.col_datevalue +
       (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') end) +
       (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) /* * (se.col_attemptcount + 1) */ ) -
       cast(s01.dateeventvalue as timestamp) ),to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') ) as sladaysleft
    from
        tbl_slaevent se
        inner join tbl_task tsk on se.col_slaeventtask = tsk.col_id
        inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
        inner join tbl_case cs on tsk.col_casetask = cs.col_id
        inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id
        inner join tbl_dict_slaeventlevel sel on se.col_slaevent_slaeventlevel = sel.col_id
        inner join tbl_dict_dateeventtype det on se.col_slaevent_dateeventtype = det.col_id
        inner join tbl_dateevent de on tsk.col_id = de.col_dateeventtask
                                       and se.col_slaevent_dateeventtype = de.col_dateevent_dateeventtype
        left join s01 on tsk.col_id = s01.taskid
                         and se.col_id = s01.slaeventid
    and(case when (((de.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') end) +
    (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) /* * (se.col_attemptcount + 1) */ ) - s01.dateeventvalue) > 0 ) then
               ((de.col_datevalue +
               (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') end) +
               (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) /* * (se.col_attemptcount + 1) */ ) - s01.dateeventvalue)
                else 999999
          end) in (select c11 from s11 where taskid = tsk.col_id and slaeventid = se.col_id)
),
s3 as (
select s1.slaeventid as slaeventid,s1.taskid as taskid,s1.taskname as taskname,s1.tasktitle as tasktitle,s1.caseid as caseid,s1.taskparentid as taskparentid,s1.taskworkitemid as taskworkitemid,
       s1.sladatetime as sladatetime,s1.sladaysleft as sladaysleft,
       add_months(sysdate,trunc(months_between(s1.sladatetime,sysdate) ) ) as sladatetimefrom,
       trunc(months_between(s1.sladatetime,sysdate) ) as slamonths,
       s1.sladatetime - add_months(sysdate,trunc(months_between(s1.sladatetime,sysdate) ) ) as sladaysfrom,
       (case when s1.sladatetime - add_months(sysdate,trunc(months_between(s1.sladatetime,sysdate) ) ) > to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') then 'Upcoming' else 'Passed' end) as slapassed,
       s1.slaeventtypeid as slaeventtypeid,s1.slaeventtypecode as slaeventtypecode,s1.slaeventtypename as slaeventtypename,s1.slaeventtypeintervalds as slaeventtypeintervalds,
       s1.slaeventtypeintervalym as slaeventtypeintervalym,s1.slaeventlevelid as slaeventlevelid,s1.slaeventlevelcode as slaeventlevelcode,s1.slaeventcodename as slaeventlevelname,
       s1.dateeventtypeid as dateeventtypeid,s1.dateeventtypecode as dateeventtypecode,s1.dateeventtypename as dateeventtypename,s1.dateeventid as dateeventid,
       s1.dateeventname as dateeventname,s1.dateeventvalue as dateeventvalue,s1.dateeventperformedby as dateeventperformedby,s1.datetimeeventvalue as datetimeeventvalue,s1.rownumber as rownumber
from
(select slaeventid,taskid,taskname,tasktitle,caseid,taskparentid,taskworkitemid,sladatetime,sladaysleft,trunc(months_between(sladatetime,sysdate)) as trancated,slaeventtypeid,
        slaeventtypecode,slaeventtypename,slaeventtypeintervalds,slaeventtypeintervalym,slaeventlevelid,slaeventlevelcode,slaeventcodename,dateeventtypeid,dateeventtypecode,
        dateeventtypename,dateeventid,dateeventname,dateeventvalue,dateeventperformedby,datetimeeventvalue,row_number() over(partition by taskid order by sladatetime asc) as rownumber
 from s21) s1
 order by s1.taskid,s1.sladatetime desc
)
--ACTUAL SELECT STARTS BELOW
 select s31.slaeventid as id,s31.slaeventid as slaeventid,s31.taskid,s31.taskname,s31.tasktitle,s31.caseid,s31.taskparentid,s31.taskworkitemid,s31.sladatetime,
        /*(case when s31.sladatetime > s01.dateeventvalue then s31.sladatetime else null end) as sladatetime,*/
        s31.SlaDaysLeft,s31.sladatetimefrom, s31.SlaDaysFrom,s31.slapassed,
        (case when s31.slamonths > 0 then s31.slamonths else 0 end) as slamonths,
        (case when extract(day from s31.sladaysfrom) > 0 then extract(day from s31.sladaysfrom) else 0 end) as sladays,
        (case when extract(hour from s31.sladaysfrom) > 0 then extract(hour from s31.sladaysfrom) else 0 end) as slahours,
        (case when extract(minute from s31.sladaysfrom) > 0 then extract(minute from s31.sladaysfrom) else 0 end) as slaminutes,
        (case when extract(second from s31.sladaysfrom) > 0 then extract(second from s31.sladaysfrom) else 0 end) as slaseconds,
        slaeventtypeid,slaeventtypecode,slaeventtypename,slaeventtypeintervalds,slaeventtypeintervalym,slaeventlevelid,slaeventlevelcode,slaeventlevelname,
        dateeventtypeid,dateeventtypecode,dateeventtypename,dateeventid,dateeventname,s31.dateeventvalue,dateeventperformedby,datetimeeventvalue
 from s3 s31
 left join s01 on s31.taskid = s01.taskid and s31.slaeventid = s01.slaeventid