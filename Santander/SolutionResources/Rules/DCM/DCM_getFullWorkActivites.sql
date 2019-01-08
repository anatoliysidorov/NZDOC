SELECT wa.WAId AS ID,
       wa.WAHoursSpent AS HoursSpent,
       wa.WAPEOPLEINVOLVED AS PEOPLEINVOLVED,
       wa.WAResolution AS Resolution,
       wa.WASummary AS Summary,
       dbms_xmlgen.CONVERT(wa.WACustomData) AS CustomData,
       wa.WACase_Id AS Case_Id,
       wa.WATask_Id AS Task_Id,
       DECODE(NVL(:TASK_ID, 0),0,(select CASESTATE_ISFINISH  from vw_dcm_simplecase where id = wa.WACase_Id), (select TASKSTATE_ISFINISH  from vw_dcm_simpletask where id = wa.WATask_Id)) AS State_IsFinish,
       wa.Task_TaskID AS Task_TaskID,
       wa.WorkActivityType_id AS WorkActivityType_id,
       wa.WorkActivityType_name AS WorkActivityType_name,
       wa.WAIsDeleted AS IsDeleted,
       wa.WorkActivityType_IconCode AS WorkActivityType_IconCode,
       wa.Case_Summary AS Case_Summary,
       -------------------------------------------
       wa.CreatedBy_Name AS CreatedBy_Name,
       wa.CreatedDuration AS CreatedDuration,
       wa.ModifiedBy_Name AS ModifiedBy_Name,
       wa.ModifiedDuration AS ModifiedDuration
       -------------------------------------------
  FROM
       (select 
            wa.col_id as WAId,
            wa.col_hoursspent AS WAHoursSpent,
            wa.col_peopleinvovled AS WAPEOPLEINVOLVED,
            wa.col_resolution AS WAResolution,
            wa.col_summary AS WASummary,
            wa.col_isdeleted as WAIsDeleted,
            wa.col_customdata.getCLOBval() AS WACustomData,
            wa.col_workactivitycase AS WACase_Id,
            wa.col_workactivitytask AS WATask_Id,
            t.col_taskid AS Task_TaskID,
            f_getNameFromAccessSubject(wa.col_createdBy) AS CreatedBy_Name,
            f_UTIL_getDrtnFrmNow(wa.col_createdDate) AS CreatedDuration,
            wa.col_createdDate as CreatedDate,
            f_getNameFromAccessSubject(wa.col_modifiedBy) AS ModifiedBy_Name,
            f_UTIL_getDrtnFrmNow(wa.col_modifiedDate) AS ModifiedDuration,
            wa.col_modifiedDate as ModifiedDate,
            wat.col_id AS WorkActivityType_id,
            wat.col_name AS WorkActivityType_name,
            wat.col_iconcode AS WorkActivityType_IconCode,
            t.col_id AS Task_Id,
            null AS Case_Summary,
            null AS Case_Workbasket_Id
        from tbl_dcm_workactivity wa
        inner join tbl_dict_workactivitytype wat ON wat.col_id = wa.col_workactivitytype
        inner join tbl_task t ON wa.col_WorkActivityTask = t.col_id
        <%=IfNotNull(":TASK_ID", " where t.col_id = nvl(:TASK_ID,0)")%>
        union all
        select 
            wa.col_id as WAId,
            wa.col_hoursspent AS WAHoursSpent,
            wa.col_peopleinvovled AS WAPEOPLEINVOLVED,
            wa.col_resolution AS WAResolution,
            wa.col_summary AS WASummary,
            wa.col_isdeleted as WAIsDeleted,
            wa.col_customdata.getCLOBval() AS WACustomData,
            wa.col_workactivitycase AS WACase_Id,
            wa.col_workactivitytask AS WATask_Id,
            null AS Task_TaskID,
            f_getNameFromAccessSubject(wa.col_createdBy) AS CreatedBy_Name,
            f_UTIL_getDrtnFrmNow(wa.col_createdDate) AS CreatedDuration,
            wa.col_createdDate as CreatedDate,
            f_getNameFromAccessSubject(wa.col_modifiedBy) AS ModifiedBy_Name,
            f_UTIL_getDrtnFrmNow(wa.col_modifiedDate) AS ModifiedDuration,
            wa.col_modifiedDate as ModifiedDate,
            wat.col_id AS WorkActivityType_id,
            wat.col_name AS WorkActivityType_name,
            wat.col_iconcode AS WorkActivityType_IconCode,
            null AS Task_Id,
            cast(c.col_summary as nvarchar2(2000)) AS Case_Summary, 
            c.col_caseppl_workbasket AS Case_Workbasket_Id
        from tbl_dcm_workactivity wa
        inner join tbl_dict_workactivitytype wat ON wat.col_id = wa.col_workactivitytype
        inner join tbl_case c on c.col_id = wa.col_workactivitycase
        inner join tbl_ac_casetypeviewcache ctvc on  c.col_casedict_casesystype = ctvc.col_casetypeviewcachecasetype and ctvc.col_accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject')
        <%=IfNotNull(":CASE_ID", " where c.col_id = nvl(:CASE_ID,0)")%>
        ) wa
 WHERE  1 = 1
      <%=IfNotNull(":ID", " and wa.WAId = :ID ")%>
      <%=IfNotNull(":TASK_ID", " and wa.WATask_Id = :TASK_ID ")%>
      <%=IfNotNull(":CASE_ID", " and wa.WACase_Id = :CASE_ID ")%>
      <%=IfNotNull(":WORKON", " and LOWER('CASE-' || TO_CHAR(wa.WACase_Id) || '' || TO_CHAR(NVL(wa.Task_TaskID, ''))) LIKE f_UTIL_toWildcards(:WORKON) ")%>
      <%=IfNotNull(":WA_SUMMARY", " and LOWER(wa.WASummary) LIKE f_UTIL_toWildcards(:WA_SUMMARY) ")%>
      <%=IfNotNull(":CASE_SUMMARY", " and LOWER(wa.Case_Summary) LIKE f_UTIL_toWildcards(:CASE_SUMMARY) ")%>
      <%=IfNotNull(":WORKBASKET_IDS", " and wa.Case_Workbasket_Id IN (SELECT TO_NUMBER(COLUMN_VALUE) AS c2 FROM TABLE(asf_splitclob(:WORKBASKET_IDS, ','))) ")%>
      <%=IfNotNull(":WORKACTIVITYTYPE_IDS", " and wa.WorkActivityType_id IN (SELECT TO_NUMBER(COLUMN_VALUE) AS c2 FROM TABLE(asf_splitclob(:WORKACTIVITYTYPE_IDS, ','))) ")%>
      <%=IfNotNull(":CREATED_START", " and TRUNC(wa.CreatedDate) >= TRUNC(TO_DATE(:CREATED_START)) ")%>
      <%=IfNotNull(":CREATED_END", " and TRUNC(wa.CreatedDate) <= TRUNC(TO_DATE(:CREATED_END)) ")%>
      <%=IfNotNull(":TIMESPENT_START", " and wa.WAHoursSpent >= :TIMESPENT_START ")%>
      <%=IfNotNull(":TIMESPENT_END", " and wa.WAHoursSpent <= :TIMESPENT_END ")%>
      <%=IfNotNull(":LOGGED_START", " and TRUNC(wa.CreatedDate) >= TRUNC(TO_DATE(:LOGGED_START)) ")%>
      <%=IfNotNull(":LOGGED_END", " and TRUNC(wa.CreatedDate) <= TRUNC(TO_DATE(:LOGGED_END)) ")%>

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>