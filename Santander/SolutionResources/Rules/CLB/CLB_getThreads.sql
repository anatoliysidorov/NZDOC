SELECT thr.col_id                                    AS Id, 
       thr.col_threadcase                            AS Case_Id, 
       
       thr.col_parentmessageid                       AS ParentThread, 
       thr.col_code                                  AS Code, 
       thr.col_threadsourcetask                      AS SourceTask_Id, 
	   f_DCM_isTaskClosedFn(thr.col_threadsourcetask)                      AS SourceTask_IsClosed, 
       task_source.col_name                          AS SourceTask_Name, 
       thr.col_threadtargettask                      AS TargetTask_Id, 
	   f_DCM_isTaskClosedFn(thr.col_threadtargettask)                      AS TargetTask_IsClosed, 
       task_target.col_name                          AS TargetTask_Name, 
       thr.col_threadworkbasket                      AS WorkBasket_Id, 
       wb.col_code                                   AS WorkBasket_Code, 
       wb.col_name                                   AS WorkBasket_Name, 
       thr.col_status                                AS Status, 
       thr.col_message                               AS message, 
       F_util_getdrtnfrmnow(thr.col_datereopen)      AS DateReopen, 
       F_util_getdrtnfrmnow(thr.col_datemessage)     AS Datemessage, 
       F_util_getdrtnfrmnow(thr.col_dateclosed)      AS DateClosed, 
       F_util_getdrtnfrmnow(thr.col_datestarted)     AS DateStarted, 
       thr.col_messageworkbasket                     AS messageWorkBasket_Id, 
       ---------------------
       F_getnamefromaccesssubject(thr.col_createdby) AS CreatedBy_Name, 
       F_util_getdrtnfrmnow(thr.col_createddate)     AS CreatedDuration, 
       thr.col_createdby                             AS CreatedBy,
       F_getnamefromaccesssubject(thr.col_modifiedby) AS ModifiedBy_Name, 
       F_util_getdrtnfrmnow(thr.col_modifieddate)     AS ModifiedDuration,
       
       (select count(*)
       from vw_users usr
       inner join tbl_ppl_caseworker cw on cw.col_userid = usr.userid
       inner join tbl_threadcaseworker tcw on tcw.col_caseworkerid = cw.col_id 
       where usr.accesssubjectcode = '@TOKEN_USERACCESSSUBJECT@'
             and tcw.col_threadid = thr.col_id) as IsUserMemberOfThread
FROM   tbl_thread thr 
       left join tbl_task task_source 
              ON task_source.col_id = thr.col_threadsourcetask 
       left join tbl_task task_target 
              ON task_target.col_id = thr.col_threadtargettask 
       left join tbl_ppl_workbasket wb 
              ON wb.col_id = thr.col_threadworkbasket 
WHERE  (:Id IS NULL OR thr.col_id = :Id) 
       AND (:State IS NULL OR (:State IS NOT NULL AND Upper(thr.col_status) = Upper(:State))) 
       AND (
		:Case_Id IS NULL 
		OR (thr.col_threadcase = :Case_Id) 
		OR (:Case_Id = (SELECT col_casetask from tbl_task where col_id = thr.col_threadsourcetask)) 
		OR (:Case_Id = (SELECT col_casetask from tbl_task where col_id = thr.col_threadtargettask)) 
)
<%=Sort("@SORT@","@DIR@")%>