SELECT p.code AS Code, 
       p.name AS Name, 
       p.description AS Description, 
       ROWNUM AS ID,
       ROWNUM AS COL_ID,
	   p.pagetype as PageType
FROM   @TOKEN_SYSTEMDOMAINUSER@.conf_environment e 
       inner join @TOKEN_SYSTEMDOMAINUSER@.conf_version v ON v.versionid = e.depversionid 
       inner join @TOKEN_SYSTEMDOMAINUSER@.conf_navpage p ON p.componentid = v.componentid 
WHERE  	e.code = '@TOKEN_DOMAIN@' 
		AND (
			UPPER(p.code) LIKE '%CUST%' OR 
			UPPER(p.code) LIKE '%ECX%' OR 
			UPPER(p.code) LIKE '%SMPL%' OR 
			UPPER(p.code) LIKE '%BASEPAGE' 
		)
        