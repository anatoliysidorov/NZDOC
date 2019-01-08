SELECT ap.*, 
       F_getnamefromaccesssubject(ap.createdby) AS CreatedBy_Name, 
       F_util_getdrtnfrmnow(ap.createddate)     AS Created 
FROM   vw_dcm_assocpage ap 
       INNER JOIN tbl_dict_workactivitytype wat 
               ON ap.workactivitytype = wat.col_id 
       LEFT JOIN tbl_dcm_workactivity wa 
               ON (wat.col_id = wa.Col_Workactivitytype 
			   AND (NVL(:WorkActivityType_Id, 0) = 0 AND :WorkActivity_Id IS NULL)
		   )
WHERE 
       LOWER(ap.pagetype_code) = LOWER(:PAGETYPE_CODE)
	   AND (NVL(:WorkActivity_Id, 0) = 0 OR wa.col_id = :WorkActivity_Id) 
	   AND (NVL(:WorkActivityType_Id, 0) = 0 OR wat.col_id = :WorkActivityType_Id) 
	   AND NVL(ap.isdeleted, 0) = 0
ORDER  BY ap.showorder ASC 