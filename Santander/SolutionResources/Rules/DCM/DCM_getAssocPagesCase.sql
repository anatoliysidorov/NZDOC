SELECT ap.*, 
	   F_getnamefromaccesssubject(ap.createdby)              AS CreatedBy_Name, 
	   F_UTIL_getDrtnFrmNow(ap.createddate)              AS Created  
FROM   vw_dcm_assocpage ap 
       INNER JOIN tbl_dict_casesystype cst 
               ON ap.casesystype = cst.col_id 
       INNER JOIN tbl_case cs 
               ON cst.col_id = cs.col_casedict_casesystype 
WHERE  
	(NVL(:Task_Id, 0) > 0 OR NVL(:Case_Id, 0) > 0) AND
	(NVL(:Task_Id, 0) = 0 OR cs.col_id = (select col_casetask from tbl_task where col_id = :Task_Id) ) AND
	(NVL(:Case_Id, 0) = 0 OR cs.col_id = :Case_Id ) AND
	(:PAGETYPE_CODE IS NULL OR lower(ap.PAGETYPE_CODE) = lower(:PAGETYPE_CODE) )
ORDER BY ShowOrder ASC