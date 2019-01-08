 select
 s1.processedstatus STATUS,
 s1.errorstatus ErrorCode,
 s1.error ErrorMessage
      from
      (select * from queue_event
      where lower(objectcode) like lower('%'||NVL(:RuleCodePattern,'UTIL_importCaseType')||'%')
      and Processedstatus <> 8
      order by queueid desc) s1 
      where rownum =1