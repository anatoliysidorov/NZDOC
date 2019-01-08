SELECT
     --DATA FROM VIEW
     tv.*,
     tv.TaskName as CalcName,
     case
        when(1 in(select Allowed
           from    table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE',p_PermissionCode =>'VIEW'))
           where   CaseTypeId = (SELECT COL_CASEDICT_CASESYSTYPE FROM TBL_CASE WHERE COL_ID = tv.CASEID))) then 1 else 0
     end as PERM_CASETYPE_VIEW,

     --CALC SLAs AND OTHER DURATIONS
     F_util_getdrtnfrmnow(tv.GoalSlaDateTime) AS GoalSlaDuration,
     F_util_getdrtnfrmnow(tv.DLineSlaDateTime) AS DLineSlaDuration,
     F_getnamefromaccesssubject(tv.createdby) AS createdby_name,
     F_util_getdrtnfrmnow(tv.createddate) AS createdduration,
     F_getnamefromaccesssubject(tv.MODIFIEDBY) AS modifiedby_name,
     F_util_getdrtnfrmnow(tv.MODIFIEDDATE) AS modifiedduration,

     -- calculate Parentid
     DECODE(NVL(:Parent_Id,0),0,tv.parentid, DECODE(:Parent_Id, tv.id,0,tv.parentid)) AS CalcParentId,

     -- calculate BO Type
     DECODE(NVL(:Parent_Id,0),0,'CASE','TASK') AS CalcObjType
FROM  (with tsk2 as
                (select tsk.col_id as ID, tsk.col_parentid as parentid, tsk.col_casetask as CaseId
                 from    tbl_task tsk
                 where   1 = 1
                 <%=IfNotNull(":Case_Id", " and (tsk.col_casetask = :Case_Id)")%>
                 <%=IfNotNull(":TASKSTATEIDS", " AND (tsk.COL_TASKDICT_TASKSTATE IN (SELECT regexp_substr(:TASKSTATEIDS, '[[:' || 'alnum:]_]+', 1, LEVEL) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:TASKSTATEIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) OR lower(tsk.COL_NAME) = 'root')")%>),
            tsk3 as
                (select stps.*
                 from vw_dcm_simpletasksla stps
                 where 1 = 1
                 <%=IfNotNull(":Case_Id", " and (stps.CaseId= :Case_Id)")%>)
            select     s2.*
            from
            (select tsk2.id
             from    tsk2
             start with(:Parent_Id IS NULL AND tsk2.parentid = 0)
                     OR(:Parent_Id IS NOT NULL AND tsk2.id = :Parent_Id)
             connect by prior tsk2.Id = tsk2.parentId) s1
             inner join
             (select tsk3.*
              from    tsk3) s2 on s1.id = s2.id
              ) tv
WHERE
  -- check on Active Caseworker
  f_DCM_getActiveCaseWorkerIdFn > 0

  --BY CASE
  <%=IfNotNull(":Case_Id", " AND tv.caseid = :Case_Id")%>

  <%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>