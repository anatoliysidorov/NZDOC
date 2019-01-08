SELECT TP.COL_ID AS Id,
       TP.COL_STARTDATE AS StartDate,
       TP.COL_ENDDATE AS EndDate,
       TRUNC(TO_DATE(TP.COL_ENDDATE) - TO_DATE(TP.COL_STARTDATE) + 1) || ' days' AS Period,
       TP.COL_REASON AS Reason,
       cw.NAME AS CaseWorker_Assignee_Name,
       TP.COL_ASSIGNEE AS CaseWorker_Assignee_Id,
       cw2.NAME AS CaseWorker_Assignor_Name,
       TP.COL_ASSIGNOR AS CaseWorker_Assignor_Id,
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
 WHERE     (:Id IS NULL OR TP.COL_ID = :Id)
       AND (:Reason IS NULL OR (LOWER(tp.col_reason) LIKE '%' || LOWER(:Reason) || '%'))
       AND (:StartDate IS NULL OR (TRUNC(tp.COL_STARTDATE) >= TRUNC(TO_DATE(:StartDate))))
       AND (:EndDate IS NULL OR (TRUNC(tp.COL_STARTDATE) <= TRUNC(TO_DATE(:EndDate))))
       AND ((:CaseWorker_Assignee_Id IS NULL OR (tp.COL_ASSIGNEE = :CaseWorker_Assignee_Id))
            OR (:CaseWorker_Assignor_Id IS NULL OR (tp.COL_ASSIGNOR = :CaseWorker_Assignor_Id))) 
<%=Sort("@SORT@","@DIR@")%>