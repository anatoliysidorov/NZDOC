SELECT tv.ID,
       tv.TaskID,
       tv.CaseId,
       tv.CaseId_Name,
       tv.Name,
       tv.Icon,
       tv.CALC_ICON,
       tv.ParentId,
       tv.TaskOrder,
       tv.TaskSysType_Name,
       tv.ExecutionMethod_Code,
       tv.Owner_CaseWorker_Name,
       tv.Workbasket_name,
       tv.Workbasket_Id,
       tv.Workbasket_type_code,
       tv.TaskState_id,
       tv.TaskState_Name,
       tv.TaskState_IsDefaultOnCreate,
       tv.TaskState_IsStart,
       tv.TaskState_CanAssign,
       tv.TaskState_IsInProcess,
       tv.TaskState_IsFinish,
       tv.TaskState_IsResolve,
       tv.TaskState_IsAssign,
       tv.StateConfig_id,
       tv.StateConfig_Name,
       tv.StateConfig_IsDefault,
       tv.CreatedBy,
       tv.CreatedDate,

       (SELECT LISTAGG(TO_CHAR(cht.col_Id), ',') WITHIN GROUP (ORDER BY cht.col_Id)
        FROM tbl_task cht
        start with tv.ID = cht.col_ParentId AND tv.TaskID <> 'root'
        connect by prior cht.col_ID = cht.col_ParentId
       ) AS ChildTaskIDs,

       f_getNameFromAccessSubject(tv.createdby) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(tv.createddate) AS CreatedDuration,
       f_getNameFromAccessSubject(tv.modifiedby) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(tv.modifieddate) AS ModifiedDuration
  FROM vw_dcm_simpletask tv
 WHERE 1 = 1
   AND (lower(tv.TaskID) <> 'root')
   AND (:ID IS NULL OR tv.ID = :ID)
   AND (:Case_Id IS NULL OR (LOWER(tv.CaseId_Name) LIKE f_UTIL_toWildcards(:Case_Id)))
   AND (:Task_Id IS NULL OR (LOWER(tv.TaskID) LIKE f_UTIL_toWildcards(:Task_Id)))
   AND (:TASK_NAME IS NULL OR (LOWER(tv.Name) LIKE f_UTIL_toWildcards(:TASK_NAME)))
   AND (:TASKTYPEIDS IS NULL OR (tv.TaskSysType IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM TABLE(asf_splitclob(:TASKTYPEIDS, ',')))))
   AND (:WORKBASKETIDS IS NULL OR tv.Workbasket_Id IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM TABLE(asf_splitclob(:WORKBASKETIDS, ','))))
   AND (:TASKSTATEIDS IS NULL OR tv.TaskState_id IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM TABLE(asf_splitclob(:TASKSTATEIDS, ','))))
   AND (:Created_Start IS NULL OR (:Created_Start IS NOT NULL AND TRUNC(tv.Createddate) >= TRUNC(TO_DATE(:Created_Start))))
   AND (:Created_End IS NULL OR (:Created_End IS NOT NULL AND TRUNC(tv.Createddate) <= TRUNC(TO_DATE(:Created_End))))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1 ")%>