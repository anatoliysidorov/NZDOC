SELECT c.componentid AS comp_id,
       c.createddate AS comp_createddate,
       f_getNameFromAccessSubject(c.createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(c.createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(c.modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(c.modifiedDate) AS ModifiedDuration,
       e.code AS env_code,
       e.NAME AS env_name,
       e.status AS env_status,
       s.code AS sol_code,
       s.NAME AS sol_name
FROM   @TOKEN_SYSTEMDOMAINUSER@.conf_environment e 
left join  @TOKEN_SYSTEMDOMAINUSER@.conf_solution s 
    ON         (s.solutionid = e.solutionid) 
inner join @TOKEN_SYSTEMDOMAINUSER@.conf_component c 
    ON         (lower(s.code) = lower(c.code)) 
WHERE      lower(e.code) = lower('@TOKEN_DOMAIN@') 
ORDER BY   c.createddate DESC