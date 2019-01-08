select se.col_id as SlaEventId,se.col_id as COL_ID, se.col_slaeventtask as SlaTaskId,
       se.col_intervalds as SlaEventIntervalDS, se.col_intervalym as SlaEventIntervalYM,
       de.col_dateeventtask as DateEventTaskId,
       de.col_datevalue as SlaDateValue, cast(de.col_datevalue as timestamp) as SlaTimestampValue,
       setp.col_code as SlaEventTypeCode,
       setp.col_intervalds as SlaEventTypeIntervalDS, setp.col_intervalym as SlaEventTypeIntervalYM,
       cast(de.col_datevalue
       +
       (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end)
       --(case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end)
       +
       (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else to_yminterval('0-0') end) as timestamp) as SlaExpDate
       --(case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else to_yminterval('0-0') end) as timestamp) as SlaExpDate
  from tbl_slaevent se
    inner join tbl_dict_dateeventtype det on se.col_slaevent_dateeventtype = det.col_id
    inner join tbl_dateevent de on det.col_id = de.col_dateevent_dateeventtype and se.col_slaeventtask = de.col_dateeventtask
    inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'