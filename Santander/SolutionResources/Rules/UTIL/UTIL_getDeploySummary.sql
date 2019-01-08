SELECT Trunc(c.createddate) AS CREATEDDATE, 
       Count(1)             AS DEPLOYMENTS 
FROM   @TOKEN_SYSTEMDOMAINUSER@.conf_environment e 
left join  @TOKEN_SYSTEMDOMAINUSER@.conf_solution s 
	ON         (s.environmentid = e.environmentid) 
inner join @TOKEN_SYSTEMDOMAINUSER@.conf_component c 
	ON         (lower(s.code) = lower(c.code)) 
WHERE      lower(e.code) = lower('@TOKEN_DOMAIN@') 
GROUP BY TRUNC(c.CREATEDDATE)
ORDER BY TRUNC(c.CREATEDDATE) ASC