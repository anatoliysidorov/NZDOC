SELECT 
    verConf.code
FROM @TOKEN_SYSTEMDOMAINUSER@.conf_environment e 
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version verR ON verR.versionid = e.depversionid 
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version verConf ON verConf.solutionid = verR.solutionid AND verConf.type=1
WHERE  e.code = '@TOKEN_DOMAIN@' AND ROWNUM = 1