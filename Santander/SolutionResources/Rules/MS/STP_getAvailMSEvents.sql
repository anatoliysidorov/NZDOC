SELECT ROWNUM AS ID,
       --subQ.Flag,
       subQ.UniqueEventId,
       --subQ.EventId,
       --subQ.EventCode,
       --subQ.EventName,
       --subQ.SLACode,
       --subQ.SLAName,
       CASE
        WHEN subQ.Flag =1 THEN 'SLA: '||subQ.SLAName||', Event: '||subQ.EventName
        WHEN subQ.Flag =0 THEN 'Event: '||subQ.EventName
       END AS FullEventName
FROM
(
  SELECT 0 AS Flag,
         'EVT_'||TO_CHAR(ste.COL_ID) AS UniqueEventId,
         ste.COL_ID AS EventId,
         ste.COL_EVENTCODE AS EventCode,
         ste.COL_EVENTNAME AS EventName,
         NULL AS SLACode,
         NULL AS SLAName
  FROM TBL_DICT_StateEvent ste
  INNER JOIN TBL_DICT_STATE st ON ste.COL_STATEEVENTSTATE=st.COL_ID
  --INNER JOIN TBL_DICT_STATECONFIG sc ON st.COL_STATESTATECONFIG=sc.COL_ID
  WHERE st.COL_STATESTATECONFIG=(SELECT s.COL_STATESTATECONFIG 
                                 FROM TBL_CASE c
                                 LEFT JOIN TBL_DICT_STATE s ON s.COL_ID =c.COL_CASEDICT_STATE                                     
                                 WHERE c.COL_ID = :CaseId)
        AND st.COL_ACTIVITY = :ActivityCode
  
  UNION ALL
  
  SELECT 1 AS Flag,
         'SLA_'||TO_CHAR(act.COL_ID) AS UniqueEventId,
         act.COL_ID AS EventId,
         act.COL_EVENTCODE AS EventCode,
         act.COL_EVENTNAME AS EventName,
         sla.COL_EVENTCODE AS SLACode,
         sla.COL_EVENTNAME AS SLAName
  FROM TBL_DICT_STATESLAACTION act
  INNER JOIN TBL_DICT_STATESLAEVENT sla ON act.COL_STATESLAACTNSTATESLAEVNT = sla.COL_ID
  INNER JOIN TBL_DICT_STATE st ON sla.COL_STATESLAEVENTDICT_STATE=st.COl_ID
  WHERE st.COL_STATESTATECONFIG=(SELECT s.COL_STATESTATECONFIG 
                                 FROM TBL_CASE c
                                 LEFT JOIN TBL_DICT_STATE s ON s.COL_ID =c.COL_CASEDICT_STATE                                     
                                 WHERE c.COL_ID = :CaseId)
  AND st.COL_ACTIVITY = :ActivityCode
) subQ

ORDER BY subQ.Flag DESC, subQ.SLACode ASC, subQ.EventName
