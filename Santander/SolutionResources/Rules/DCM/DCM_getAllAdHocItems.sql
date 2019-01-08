SELECT ROWNUM AS id, 
       item_type, 
       item_typename,
       item_id, 
       item_name, 
       item_description,
       CreatedBy_Name,
       CreatedDuration,
       ModifiedBy_Name,
       ModifiedDuration
FROM   (SELECT 'TASKSYSTYPE'       AS item_type, 
               'Task Type'         AS item_typename, 
               tst.col_id          AS item_id, 
               tst.col_name        AS item_name, 
               tst.col_description AS item_description, 
               NULL                AS Ext_Id,
               f_getNameFromAccessSubject(aah.col_createdBy) AS CreatedBy_Name,
               f_UTIL_getDrtnFrmNow(aah.col_createdDate) AS CreatedDuration,
               f_getNameFromAccessSubject(aah.col_modifiedBy) AS ModifiedBy_Name,
               f_UTIL_getDrtnFrmNow(aah.col_modifiedDate) AS ModifiedDuration,
               GREATEST(NVL(tst.COL_ISDELETED, 0), NVL(aah.COL_ISDELETED, 0))  AS ISDELETED
        FROM   tbl_stp_availableadhoc aah 
          INNER  JOIN tbl_dict_tasksystype tst ON (:Case_Id IS NULL AND Aah.Col_Tasksystype  = tst.Col_Id) OR 
            (:Case_Id IS NOT NULL AND  Aah.Col_Tasksystype  = tst.Col_Id and Aah.Col_Casesystype in 
            (select Tbl_Case.Col_Casedict_Casesystype from tbl_case where col_id = :Case_Id) )
        WHERE  f_dcm_isCaseTypeAccessAllow(AccessObjectId => (select col_casedict_casesystype from tbl_case where col_id = :Case_Id)) = 1
            AND  f_dcm_isTaskTypeAccessAllow(AccessObjectId => tst.col_id) = 1
            --tasktype associated with casetype
            AND aah.COL_CASESYSTYPE = (select col_casedict_casesystype from tbl_case where col_id = :Case_Id)
            --AND  (tst.col_isdeleted = 0 OR tst.col_isdeleted IS NULL)
        UNION ALL 
SELECT 'PROCEDURE'         AS item_type, 
               'Procedure'         AS item_typename, 
               tp.col_id           AS item_id, 
               tp.col_name        AS item_name, 
               tp.col_description AS item_description, 
               tp.col_id          AS Ext_Id,
               null AS CreatedBy_Name,
               null AS CreatedDuration,
               null AS ModifiedBy_Name,
               null AS ModifiedDuration,
               tp.COL_ISDELETED AS ISDELETED
FROM tbl_stp_availableadhoc adh
  
INNER JOIN TBL_PROCEDURE tp ON adh.COL_PROCEDURE = tp.COL_ID
WHERE adh.COL_CASESYSTYPE = (select col_casedict_casesystype from tbl_case where col_id = :Case_Id)
AND f_dcm_isCaseTypeAccessAllow(AccessObjectId => (select col_casedict_casesystype from tbl_case where col_id = :Case_Id)) = 1  
--AND  (tp.col_isdeleted = 0 OR tp.col_isdeleted IS NULL)
) 
ORDER  BY item_type ASC, 
          item_name ASC