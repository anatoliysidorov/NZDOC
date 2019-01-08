SELECT templateid, 
       code, 
       NAME, 
       templatetype 
FROM   @TOKEN_SYSTEMDOMAINUSER@.conf_template 
WHERE  componentid = (SELECT v.componentid 
                      FROM   @TOKEN_SYSTEMDOMAINUSER@.conf_version v 
                             INNER JOIN 
                             @TOKEN_SYSTEMDOMAINUSER@.conf_environment e 
                                     ON ( e.depversionid = v.versionid ) 
                      WHERE  e.domain = '@TOKEN_DOMAIN@') 
       AND templatetype = 1 