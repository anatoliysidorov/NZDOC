SELECT 
      qe.QUEUEID         AS QueueId,
      qe.CODE            AS Code,
      qe.DOMAINID        AS DomainId,
      qe.CREATEDBY       AS CreatedBy,
      qe.CREATEDDATE     AS CreatedDate,
      qe.OWNER           AS Owner,
      qe.SCHEDULEDDATE   AS ScheduledDate,
      qe.OBJECTTYPE      AS ObjectType,
      qe.PROCESSEDSTATUS AS ProcessedStatus,
      qe.PRIORITY        AS Priority,
      qe.OBJECTCODE      AS ObjectCode,
      qe.ERROR           AS Error,
      qe.ERRORSTATUS     AS ErrorStatus,
      qe.PARAMETERS      AS Parameters,
      qe.PROCESSEDDATE   AS ProcessedDate,
      qe.PROCESSEDBY     AS ProcessedBy,
      qe.GROUPID         AS GroupId,
      qe.USEADVQUEUE     AS UseAdvQueue,
      qe.BONAME          AS BOName,
      qe.BOID            AS BOid,
      qe.CONSUMER_GROUP  AS Consumer_Group,
      F_getnamefromaccesssubject(qe.CREATEDBY) AS CreatedBy_Name,
      F_UTIL_getDrtnFrmNow(qe.CREATEDDATE)     AS CreatedDuration,
      TRUNC((qe.PROCESSEDDATE - qe.CREATEDDATE) * 24 * 60 * 60 * 1000) AS PerfDuration
FROM QUEUE_EVENT qe
WHERE 1 = 1
	<%= IfNotNull(":QueueId", " AND qe.QUEUEID = :QueueId ") %>
  <%= IfNotNull(":Code", " AND LOWER(qe.OBJECTCODE) LIKE '%' || lower(:Code) || '%' ") %>
  <%= IfNotNull(":Parameters", " AND LOWER(qe.PARAMETERS) LIKE '%' || lower(:Parameters) || '%' ") %>
  <%= IfNotNull(":ProcessStatus", " AND qe.PROCESSEDSTATUS = :ProcessStatus ") %>
  <%= IfNotNull(":ResultStatus", " AND qe.ERRORSTATUS = :ResultStatus ") %>
  <%= IfNotNull(":Created_Start", " AND trunc(qe.CREATEDDATE) >= trunc(to_date(:Created_Start)) ") %>
  <%= IfNotNull(":Created_End", " AND trunc(qe.CREATEDDATE) <= trunc(to_date(:Created_End)) ") %>
<%=Sort("@SORT@","@DIR@")%>