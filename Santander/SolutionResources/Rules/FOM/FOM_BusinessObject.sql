SELECT 
       bo.objectid 				AS col_id,
       bo.code                  AS BOCode, 
       bo.localcode             AS BOLocalCode, 
       bo.NAME                  AS BOName, 
       'tbl_' || bo.localcode          AS BOTableName
       
FROM  @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo 
            
       INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version vrs 
               ON bo.componentid = vrs.componentid 
       INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_environment env 
               ON vrs.versionid = env.depversionid 
WHERE  env.code = '@TOKEN_DOMAIN@'