SELECT 
	p.col_id AS ID,
	p.col_name AS NAME,
	p.col_code AS CODE,
	p.col_description AS DESCRIPTION,
	p.col_isdeleted AS ISDELETED,
	p.col_fieldvalues AS FIELDVALUES,
	p.col_config AS CONFIG,
	p.col_usedfor AS USEDFOR,
	p.col_PageCaseSysType AS CASETYPEID,
	p.col_systemdefault AS SYSTEMDEFAULT,
	ct.COL_NAME AS CASETYPENAME,
	ct.COL_CASESYSTYPEMODEL AS MODELID,
	do.COL_ID AS ROOTBOID,
        (CASE WHEN p.COL_CREATEDBY = 'IMPORT' THEN 1 ELSE 0 END) AS ISIMPORTED,
	----------------------------------
	f_getNameFromAccessSubject(p.col_createdBy) AS CreatedBy_Name,
	f_UTIL_getDrtnFrmNow(p.col_createdDate) AS CreatedDuration,
	f_getNameFromAccessSubject(p.col_modifiedBy) AS ModifiedBy_Name,
	f_UTIL_getDrtnFrmNow(p.col_modifiedDate) AS ModifiedDuration
	----------------------------------
FROM tbl_fom_page p
	LEFT JOIN TBL_DICT_CASESYSTYPE ct ON p.col_PageCaseSysType = ct.col_id
	LEFT JOIN tbl_dom_model dm on dm.COL_DOM_MODELMDM_MODEL = ct.COL_CASESYSTYPEMODEL
	LEFT JOIN tbl_dom_object do on (do.col_dom_objectdom_model = dm.col_id and do.col_isroot = 1)
WHERE (:Page_Id IS NULL OR (:Page_Id IS NOT NULL AND p.COL_ID = :Page_Id))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>