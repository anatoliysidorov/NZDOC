SELECT ap.*, 
	   F_getnamefromaccesssubject(ap.createdby)              AS CreatedBy_Name, 
	   F_UTIL_getDrtnFrmNow(ap.createddate)              AS Created  
FROM   vw_dcm_assocpage ap 
WHERE  
	ap.casesystype = :CaseType_Id AND
	(:PAGETYPE_CODE IS NULL OR lower(ap.PAGETYPE_CODE) = lower(:PAGETYPE_CODE))
ORDER BY ShowOrder ASC