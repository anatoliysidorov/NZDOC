SELECT 
	wa.col_id AS ID,
	wa.col_hoursspent AS HoursSpent,
	wa.col_peopleinvovled AS PEOPLEINVOLVED,
	wa.col_resolution AS Resolution,
	wa.col_summary AS Summary,
	dbms_xmlgen.CONVERT(wa.col_customdata.getCLOBval()) AS CustomData,
	wa.col_workactivitycase AS Case_Id,
	wa.col_workactivitytask AS Task_Id,
	wa.col_isdeleted AS IsDeleted,

	wat.col_id AS WorkActivityType_id,
	wat.col_name AS WorkActivityType_name,
	wat.col_iconcode AS WorkActivityType_IconCode,

	DECODE(NVL(:TASK_ID, 0),0,(select CASESTATE_ISFINISH  from vw_dcm_simplecase where id = wa.col_workactivitycase), (select TASKSTATE_ISFINISH  from vw_dcm_simpletask where id = wa.col_workactivitytask)) AS State_IsFinish,

	f_getNameFromAccessSubject(wa.col_createdBy)  AS CreatedBy_Name,
	f_UTIL_getDrtnFrmNow(wa.col_createdDate) AS CreatedDuration,
	wa.col_createdDate as CreatedDate,
	f_getNameFromAccessSubject(wa.col_modifiedBy) AS ModifiedBy_Name,
	f_UTIL_getDrtnFrmNow(wa.col_modifiedDate) AS ModifiedDuration,
	wa.col_modifiedDate as ModifiedDate
from tbl_dcm_workactivity wa
inner join tbl_dict_workactivitytype wat ON wat.col_id = wa.col_workactivitytype
where 1 = 1
<%=IfNotNull(":ID", " and wa.col_id = :ID ")%>
<%=IfNotNull(":TASK_ID", " and wa.col_workactivitytask = :TASK_ID ")%>
<%=IfNotNull(":CASE_ID", " and wa.col_workactivitycase = :CASE_ID ")%>
<%=IfNotNull(":WORKON", " and (wa.col_workactivitycase = :WORKON or col_workactivitytask = :WORKON) ")%>
<%=IfNotNull(":WA_SUMMARY", " and LOWER(wa.col_summary) LIKE f_UTIL_toWildcards(:WA_SUMMARY) ")%>
<%=IfNotNull(":WORKACTIVITYTYPE_IDS", " and wa.col_id IN (SELECT to_number(regexp_substr(:WORKACTIVITYTYPE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:WORKACTIVITYTYPE_IDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ")%>
<%=IfNotNull(":CREATED_START", " and TRUNC(wa.col_createdDate) >= TRUNC(TO_DATE(:CREATED_START)) ")%>
<%=IfNotNull(":CREATED_END", " and TRUNC(wa.col_createdDate) <= TRUNC(TO_DATE(:CREATED_END)) ")%>
<%=IfNotNull(":TIMESPENT_START", " and wa.col_hoursspent >= :TIMESPENT_START ")%>
<%=IfNotNull(":TIMESPENT_END", " and wa.col_hoursspent <= :TIMESPENT_END ")%>
<%=IfNotNull(":LOGGED_START", " and TRUNC(wa.col_createdDate) >= TRUNC(TO_DATE(:LOGGED_START)) ")%>
<%=IfNotNull(":LOGGED_END", " and TRUNC(wa.col_createdDate) <= TRUNC(TO_DATE(:LOGGED_END)) ")%>

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>