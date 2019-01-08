SELECT act.col_id AS Id,
       evnt.col_slaeventdict_tasksystype AS TaskType_Id,
       act.col_slaaction_slaeventlevel AS SLAEventLevel_Id,
       dict_evntlvl.col_name AS SLAEventLevel_Name,
       evnt.col_slaevent_dateeventtype AS DateEventLevel_Id,
       dict_dateevnttype.col_name AS DateEventLevel_Name,
       evnt.col_slaeventdict_slaeventtype AS SLAEventType_Id,
       dict_evnttype.col_name AS SLAEventType_Name,
       evnt.col_maxattempts AS MaxAttempts,
       EXTRACT(SECOND FROM TO_DSINTERVAL(evnt.col_intervalds)) AS Seconds,
       EXTRACT(MINUTE FROM TO_DSINTERVAL(evnt.col_intervalds)) AS Minutes,
       EXTRACT(HOUR FROM TO_DSINTERVAL(evnt.col_intervalds)) AS Hours,
       EXTRACT(DAY FROM TO_DSINTERVAL(evnt.col_intervalds)) AS Days,
       EXTRACT(MONTH FROM TO_YMINTERVAL(evnt.col_intervalym)) AS Months,
       act.col_description AS Description,
       act.col_processorcode AS ProcessorCode,
       t1.ParamCodes AS ParamCodes,
       t1.ParamValues AS ParamValues,
       f_getNameFromAccessSubject(act.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(act.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(act.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(act.col_modifiedDate) AS ModifiedDuration       
  FROM TBL_SLAACTION act
 INNER JOIN TBL_SLAEVENT evnt ON evnt.col_id = act.col_slaactionslaevent
  LEFT JOIN TBL_DICT_SLAEVENTLEVEL dict_evntlvl ON dict_evntlvl.col_id = act.col_slaaction_slaeventlevel
  LEFT JOIN TBL_DICT_DATEEVENTTYPE dict_dateevnttype ON dict_dateevnttype.col_id = evnt.col_slaevent_dateeventtype
  LEFT JOIN TBL_DICT_SLAEVENTTYPE dict_evnttype ON dict_evnttype.col_id = evnt.col_slaeventdict_slaeventtype
  LEFT JOIN (SELECT a.col_id,
                    LISTAGG(TO_CHAR(ap.col_paramcode), '|||') WITHIN GROUP(ORDER BY ap.col_paramcode) AS ParamCodes,
                    LISTAGG(TO_CHAR(ap.col_paramvalue), '|||') WITHIN GROUP(ORDER BY ap.col_paramvalue) AS ParamValues
               FROM TBL_AUTORULEPARAMETER ap
              INNER JOIN TBL_SLAACTION a
                 ON ap.col_autoruleparamslaaction = a.col_id
              GROUP BY a.col_id) t1
    ON t1.col_id = act.col_id
 WHERE (:TaskType_Id IS NULL OR (:TaskType_Id IS NOT NULL AND evnt.col_slaeventdict_tasksystype = :TaskType_Id))