SELECT ap.*, 
       F_getnamefromaccesssubject(ap.createdby) AS CreatedBy_Name, 
       F_util_getdrtnfrmnow(ap.createddate)     AS Created 
FROM   vw_dcm_assocpage ap 
       INNER JOIN tbl_dict_partytype pt 
               ON ap.partytype = pt.col_id 
       LEFT JOIN tbl_externalparty ep 
               ON (pt.col_id = ep.col_externalpartypartytype 
			   AND (NVL(:PARTYTYPE_ID, 0) = 0 AND :PARTYTYPE_CODE IS NULL)
		   )
WHERE 
       LOWER(ap.pagetype_code) = LOWER(:PAGETYPE_CODE)
	   AND (:PARTYTYPE_CODE IS NULL OR LOWER(pt.col_code) = LOWER(:PARTYTYPE_CODE))
	   AND (NVL(:EXTERNALPARTY, 0) = 0 OR ep.col_id = :EXTERNALPARTY) 
	   AND (NVL(:PARTYTYPE_ID, 0) = 0 OR pt.col_id = :PARTYTYPE_ID) 
	   AND (:EXTSYSID IS NULL OR lower(ep.col_extsysid) = lower(:EXTSYSID)) 
	   AND NVL(ap.isdeleted, 0) = 0
ORDER  BY ap.showorder ASC 