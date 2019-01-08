SELECT TP.COL_ID AS Id,
       TP.COL_STARTDATE AS StartDate,
       TP.COL_ENDDATE AS EndDate,
       TP.COL_REASON AS Reason,
       cw.NAME AS CaseWorker_Assignee_Name,
       TP.COL_ASSIGNEE AS CaseWorker_Assignee_Id,
       (CASE WHEN TRUNC(SYSDATE) >= TP.COL_STARTDATE AND TRUNC(SYSDATE) <= TP.COL_ENDDATE THEN 1 ELSE 0 END) AS IsActive,
       TP.COL_ISDELETED AS IsDeleted,
       f_getNameFromAccessSubject(tp.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(tp.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(tp.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(tp.col_modifiedDate) AS ModifiedDuration
  FROM TBL_PROXY TP
       LEFT JOIN VW_PPL_CASEWORKERSUSERS cw
          ON TP.COL_ASSIGNEE = cw.ID
       LEFT JOIN VW_PPL_CASEWORKERSUSERS cw2
          ON TP.COL_ASSIGNOR = cw2.ID
 WHERE (:Id IS NULL OR TP.COL_ID = :Id) AND cw2.ACCODE = SYS_CONTEXT('CLIENTCONTEXT', 'AccessSubject')
<%=Sort("@SORT@","@DIR@")%>