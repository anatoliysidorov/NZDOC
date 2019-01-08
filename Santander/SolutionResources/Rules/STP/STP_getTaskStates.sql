SELECT ts.col_Id AS Id,
       ts.col_Name AS NAME,
       ts.col_Code AS Code,
       ts.col_Description AS Description,
       ts.col_isDeleted AS IsDeleted,
       sc.col_Name AS StateConfig_Name,
       Nvl(ts.col_isdefaultoncreate, 0) AS ISCREATE,
       Nvl(ts.col_isstart, 0) AS ISSTART,
       Nvl(ts.col_isassign, 0) AS ISASSIGN,
       Nvl(ts.col_isdefaultoncreate2, 0) AS ISINPROCESS,
       Nvl(ts.col_isresolve, 0) AS ISRESOLVE,
       Nvl(ts.col_isfinish, 0) AS ISFINISH,
       CASE
         WHEN Nvl(ts.col_isdefaultoncreate, 0) = 1 THEN
          'ISCREATE'
         WHEN Nvl(ts.col_isstart, 0) = 1 THEN
          'ISSTART'
         WHEN Nvl(ts.col_isassign, 0) = 1 THEN
          'ISASSIGN'
         WHEN Nvl(ts.col_isdefaultoncreate2, 0) = 1 THEN
          'ISINPROCESS'
         WHEN Nvl(ts.col_isfinish, 0) = 1 THEN
          'ISFINISH'
         WHEN Nvl(ts.col_isresolve, 0) = 1 THEN
          'ISRESOLVE'
         ELSE
          NULL
       END AS StateFlag,
       f_getNameFromAccessSubject(ts.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(ts.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(ts.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(ts.col_modifiedDate) AS ModifiedDuration
  FROM tbl_dict_stateconfig sc
  LEFT JOIN tbl_dict_taskstate ts ON ts.col_stateconfigtaskstate = sc.col_id
 WHERE upper(sc.col_type) = 'TASK'
   AND sc.col_isdefault = 1
   <%= IfNotNull(":Id", " AND ts.col_id = :Id ") %>
   <%= IfNotNull(":IsDeleted", " AND ts.col_isDeleted = :IsDeleted ") %>
   <%= IfNotNull(":StateConfig_Id", " AND ts.col_stateconfigtaskstate = :StateConfig_Id ") %>
   <%= IfNotNull(":STATECONFIGIDS", " AND ts.col_stateconfigtaskstate IN (SELECT TO_NUMBER(regexp_substr(:STATECONFIGIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:STATECONFIGIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ") %>
   <%= IfNotNull(":TASK_ID", " AND (ts.col_Activity IN (SELECT NextActivity FROM TABLE(f_DCM_getNextActivityList3(TaskId => :TASK_ID))) OR ts.col_Id = (SELECT tv.TaskState_id FROM vw_dcm_simpletask tv WHERE tv.ID = :TASK_ID)) ")%>
   --Get only available states by transition
   <%= IfNotNull(":TransitionForState", " AND (select count(*) from tbl_dict_taskstate ts1 inner join tbl_dict_tasktransition tr1 on tr1.col_targettasktranstaskstate = ts1.col_id where ts1.col_code = :TransitionForState and tr1.col_sourcetasktranstaskstate = ts.col_id) > 0 ") %>

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>
