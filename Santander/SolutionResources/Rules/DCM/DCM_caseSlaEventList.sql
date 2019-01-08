WITH s01 AS (
SELECT
(CASE WHEN subs2.datevalue IS NOT NULL THEN subs2.datevalue ELSE SYSDATE END) AS dateeventvalue,tsk.col_id AS taskid,se.col_id AS slaeventid
FROM tbl_task tsk
INNER JOIN tbl_slaevent se ON tsk.col_id = se.col_slaeventtask
INNER JOIN tbl_case cs ON tsk.col_casetask = cs.col_id
LEFT JOIN tbl_dateevent des ON tsk.col_id = des.col_dateeventtask
                            AND se.col_slaevent_dateeventtype = des.col_dateevent_dateeventtype
LEFT JOIN
(SELECT subs1.dateeventid,subs1.dateeventtask,subs1.datename,subs1.datevalue,subs1.dateeventrownumber
FROM
(SELECT dec.col_id AS dateeventid, dec.col_dateeventtask AS dateeventtask,dec.col_datename AS datename,dec.col_datevalue AS datevalue,
ROW_NUMBER() OVER(PARTITION BY dec.col_dateeventtask ORDER BY dec.col_datevalue DESC) AS dateeventrownumber
FROM tbl_dateevent dec
WHERE dec.col_dateeventtask in (select col_id from tbl_task where col_casetask = :CaseId) AND dec.col_datename = 'DATE_TASK_CLOSED') subs1
WHERE subs1.dateeventrownumber = 1) subs2 ON tsk.col_id = subs2.dateeventtask
WHERE cs.col_id = :CaseId
),
s11 AS (
SELECT CASE WHEN (((de2.col_datevalue +
                    (CASE WHEN se2.col_intervalds IS NOT NULL THEN to_dsinterval(se2.col_intervalds) ELSE to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') END) * ( se2.col_attemptcount + 1 ) +
                    (CASE WHEN se2.col_intervalym IS NOT NULL THEN to_yminterval(se2.col_intervalym) ELSE to_yminterval('0-0') END) * (se2.col_attemptcount + 1)) - s01.dateeventvalue) > 0)
                    THEN ((de2.col_datevalue +
                    (CASE WHEN se2.col_intervalds IS NOT NULL THEN to_dsinterval(se2.col_intervalds) ELSE to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0')
                    END) * (se2.col_attemptcount + 1) +
                    (CASE WHEN se2.col_intervalym IS NOT NULL THEN to_yminterval(se2.col_intervalym) ELSE to_yminterval('0-0') END) * (se2.col_attemptcount + 1)) - s01.dateeventvalue)
                ELSE 999999
        END AS c11,
        tsk2.col_id AS taskid,se2.col_id AS slaeventid
FROM tbl_slaevent se2
INNER JOIN tbl_task tsk2 ON se2.col_slaeventtask = tsk2.col_id
INNER JOIN tbl_tw_workitem twi2 ON tsk2.col_tw_workitemtask = twi2.col_id
INNER JOIN tbl_case cs2 ON tsk2.col_casetask = cs2.col_id
INNER JOIN tbl_dateevent de2 ON tsk2.col_id = de2.col_dateeventtask
                             AND se2.col_slaevent_dateeventtype = de2.col_dateevent_dateeventtype
LEFT JOIN s01 ON tsk2.col_id = s01.taskid AND se2.col_id = s01.slaeventid
WHERE cs2.col_id = :CaseId
),
s21 AS (
SELECT se.col_id AS slaeventid,tsk.col_id AS taskid,tsk.col_name AS taskname,tsk.col_taskid AS tasktitle,tsk.col_casetask AS caseid,tsk.col_parentid AS taskparentid,
       tsk.col_tw_workitemtask AS taskworkitemid,setp.col_id AS slaeventtypeid,setp.col_code AS slaeventtypecode,setp.col_name AS slaeventtypename,setp.col_intervalds AS slaeventtypeintervalds,
       setp.col_intervalym AS slaeventtypeintervalym,sel.col_id AS slaeventlevelid,sel.col_code AS slaeventlevelcode,sel.col_name AS slaeventcodename,det.col_id AS dateeventtypeid,
       det.col_code AS dateeventtypecode,det.col_name AS dateeventtypename,de.col_id AS dateeventid,de.col_datename AS dateeventname,de.col_datevalue AS dateeventvalue,
       de.col_performedby AS dateeventperformedby,
       CAST(de.col_datevalue AS TIMESTAMP) AS datetimeeventvalue,
       (CAST(de.col_datevalue +
       (CASE WHEN se.col_intervalds IS NOT NULL THEN to_dsinterval(se.col_intervalds) ELSE to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') END) * (se.col_attemptcount + 1) +
       (CASE WHEN se.col_intervalym IS NOT NULL THEN to_yminterval(se.col_intervalym) ELSE to_yminterval('0-0') END) * (se.col_attemptcount + 1) AS TIMESTAMP) ) AS sladatetime,
       greatest(((de.col_datevalue +
       (CASE WHEN se.col_intervalds IS NOT NULL THEN to_dsinterval(se.col_intervalds) ELSE to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') END) * (se.col_attemptcount + 1) +
       (CASE WHEN se.col_intervalym IS NOT NULL THEN to_yminterval(se.col_intervalym) ELSE to_yminterval('0-0') END) * (se.col_attemptcount + 1)) -
       CAST(s01.dateeventvalue AS TIMESTAMP) ),to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') ) AS sladaysleft
    FROM
        tbl_slaevent se
        INNER JOIN tbl_task tsk ON se.col_slaeventtask = tsk.col_id
        INNER JOIN tbl_tw_workitem twi ON tsk.col_tw_workitemtask = twi.col_id
        INNER JOIN tbl_case cs ON tsk.col_casetask = cs.col_id
        INNER JOIN tbl_dict_slaeventtype setp ON se.col_slaeventdict_slaeventtype = setp.col_id
        INNER JOIN tbl_dict_slaeventlevel sel ON se.col_slaevent_slaeventlevel = sel.col_id
        INNER JOIN tbl_dict_dateeventtype det ON se.col_slaevent_dateeventtype = det.col_id
        INNER JOIN tbl_dateevent de ON tsk.col_id = de.col_dateeventtask
                                       AND se.col_slaevent_dateeventtype = de.col_dateevent_dateeventtype
        LEFT JOIN s01 ON tsk.col_id = s01.taskid
                         AND se.col_id = s01.slaeventid
    WHERE cs.col_id = :CaseId
    AND(CASE WHEN (((de.col_datevalue + (CASE WHEN se.col_intervalds IS NOT NULL THEN to_dsinterval(se.col_intervalds) ELSE to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') END) * (se.col_attemptcount + 1) +
    (CASE WHEN se.col_intervalym IS NOT NULL THEN to_yminterval(se.col_intervalym) ELSE to_yminterval('0-0') END) * (se.col_attemptcount + 1)) - s01.dateeventvalue) > 0 ) THEN
               ((de.col_datevalue +
               (CASE WHEN se.col_intervalds IS NOT NULL THEN to_dsinterval(se.col_intervalds) ELSE to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') END) * (se.col_attemptcount + 1) +
               (CASE WHEN se.col_intervalym IS NOT NULL THEN to_yminterval(se.col_intervalym) ELSE to_yminterval('0-0') END) * (se.col_attemptcount + 1)) - s01.dateeventvalue)
                ELSE 999999
          END) IN (SELECT c11 FROM s11 WHERE taskid = tsk.col_id AND slaeventid = se.col_id)
),
s3 AS (
SELECT s1.slaeventid AS slaeventid,s1.taskid AS taskid,s1.taskname AS taskname,s1.tasktitle AS tasktitle,s1.caseid AS caseid,s1.taskparentid AS taskparentid,s1.taskworkitemid AS taskworkitemid,
       s1.sladatetime AS sladatetime,s1.sladaysleft AS sladaysleft,
       add_months(SYSDATE,trunc(months_between(s1.sladatetime,SYSDATE) ) ) AS sladatetimefrom,
       trunc(months_between(s1.sladatetime,SYSDATE) ) AS slamonths,
       s1.sladatetime - add_months(SYSDATE,trunc(months_between(s1.sladatetime,SYSDATE) ) ) AS sladaysfrom,
       (CASE WHEN s1.sladatetime - add_months(SYSDATE,trunc(months_between(s1.sladatetime,SYSDATE) ) ) > to_dsinterval('0 0'|| ':'|| '0'|| ':'|| '0') THEN 'Upcoming' ELSE 'Passed' END) AS slapassed,
       s1.slaeventtypeid AS slaeventtypeid,s1.slaeventtypecode AS slaeventtypecode,s1.slaeventtypename AS slaeventtypename,s1.slaeventtypeintervalds AS slaeventtypeintervalds,
       s1.slaeventtypeintervalym AS slaeventtypeintervalym,s1.slaeventlevelid AS slaeventlevelid,s1.slaeventlevelcode AS slaeventlevelcode,s1.slaeventcodename AS slaeventlevelname,
       s1.dateeventtypeid AS dateeventtypeid,s1.dateeventtypecode AS dateeventtypecode,s1.dateeventtypename AS dateeventtypename,s1.dateeventid AS dateeventid,
       s1.dateeventname AS dateeventname,s1.dateeventvalue AS dateeventvalue,s1.dateeventperformedby AS dateeventperformedby,s1.datetimeeventvalue AS datetimeeventvalue,s1.rownumber AS rownumber
FROM
(SELECT slaeventid,taskid,taskname,tasktitle,caseid,taskparentid,taskworkitemid,sladatetime,sladaysleft,trunc(months_between(sladatetime,SYSDATE)) AS trancated,slaeventtypeid,
        slaeventtypecode,slaeventtypename,slaeventtypeintervalds,slaeventtypeintervalym,slaeventlevelid,slaeventlevelcode,slaeventcodename,dateeventtypeid,dateeventtypecode,
        dateeventtypename,dateeventid,dateeventname,dateeventvalue,dateeventperformedby,datetimeeventvalue,ROW_NUMBER() OVER(PARTITION BY taskid ORDER BY sladatetime ASC) AS rownumber
 FROM s21) s1
 ORDER BY s1.taskid,s1.sladatetime DESC
)
--ACTUAL SELECT STARTS BELOW
 SELECT s31.slaeventid AS id,s31.slaeventid AS slaeventid,s31.taskid,s31.taskname,s31.tasktitle,s31.caseid,s31.taskparentid,s31.taskworkitemid,
        (CASE WHEN s31.sladatetime > s01.dateeventvalue THEN s31.sladatetime ELSE NULL END) AS sladatetime,/*s31.SlaDaysLeft,*/s31.sladatetimefrom, /*s31.SlaDaysFrom,*/s31.slapassed,
        (CASE WHEN s31.slamonths > 0 THEN s31.slamonths ELSE 0 END) AS slamonths,
        (CASE WHEN EXTRACT(DAY FROM s31.sladaysfrom) > 0 THEN EXTRACT(DAY FROM s31.sladaysfrom) ELSE 0 END) AS sladays,
        (CASE WHEN EXTRACT(HOUR FROM s31.sladaysfrom) > 0 THEN EXTRACT(HOUR FROM s31.sladaysfrom) ELSE 0 END) AS slahours,
        (CASE WHEN EXTRACT(MINUTE FROM s31.sladaysfrom) > 0 THEN EXTRACT(MINUTE FROM s31.sladaysfrom) ELSE 0 END) AS slaminutes,
        (CASE WHEN EXTRACT(SECOND FROM s31.sladaysfrom) > 0 THEN EXTRACT(SECOND FROM s31.sladaysfrom) ELSE 0 END) AS slaseconds,
        slaeventtypeid,slaeventtypecode,slaeventtypename,slaeventtypeintervalds,slaeventtypeintervalym,slaeventlevelid,slaeventlevelcode,slaeventlevelname,
        dateeventtypeid,dateeventtypecode,dateeventtypename,dateeventid,dateeventname,s31.dateeventvalue,dateeventperformedby,datetimeeventvalue
 FROM s3 s31
 LEFT JOIN s01 ON s31.taskid = s01.taskid AND s31.slaeventid = s01.slaeventid
ORDER BY s31.taskid,s31.slaeventid