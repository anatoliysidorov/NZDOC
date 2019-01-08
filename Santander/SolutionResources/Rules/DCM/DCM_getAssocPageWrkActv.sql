SELECT ap.*,
       F_getnamefromaccesssubject(ap.createdby) AS CreatedBy_Name,
       F_UTIL_getDrtnFrmNow(ap.createddate) AS Created
  FROM vw_dcm_assocpage ap
  LEFT JOIN tbl_dcm_workactivity wa
    ON wa.col_id = :WorkActivity_Id
   AND ap.WORKACTIVITYTYPE = wa.COL_WORKACTIVITYTYPE
 WHERE (NVL(:WorkActivity_Id, 0) > 0 OR NVL(:WorkActivityType_Id, 0) > 0)
   AND (NVL(:WorkActivity_Id, 0) = 0 OR wa.col_id = :WorkActivity_Id)
   AND (NVL(:WorkActivityType_Id, 0) = 0 OR ap.WORKACTIVITYTYPE = :WorkActivityType_Id)
   AND (:PAGETYPE_CODE IS NULL OR lower(ap.PAGETYPE_CODE) = lower(:PAGETYPE_CODE))
   AND (:IsDeleted IS NULL OR NVL(ap.isDeleted, 0) = :IsDeleted)
 ORDER BY ShowOrder ASC