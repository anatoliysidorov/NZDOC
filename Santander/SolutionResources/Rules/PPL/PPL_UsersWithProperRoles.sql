SELECT     usrMap.userid AS userid
FROM       @TOKEN_SYSTEMDOMAINUSER@.asf_userrole usrMap
inner join vw_users usr ON(usrMap.userid = usr.userid)
WHERE      usrMap.roleid =(SELECT rl.roleid
           FROM    @TOKEN_SYSTEMDOMAINUSER@.asf_role rl
           WHERE   rl.envid = '@TOKEN_DOMAIN@'
                   AND lower(rl.localcode) = 'root_caseworker')
UNION
SELECT     usrMap.userid AS userid
FROM       @TOKEN_SYSTEMDOMAINUSER@.asf_usergroup usrMap
inner join vw_users usr ON(usrMap.userid = usr.userid)
WHERE      usrMap.groupid IN(SELECT groupid
           FROM    @TOKEN_SYSTEMDOMAINUSER@.asf_grouprole
           WHERE   roleid =(SELECT rl.roleid
                   FROM    @TOKEN_SYSTEMDOMAINUSER@.asf_role rl
                   WHERE   rl.envid = '@TOKEN_DOMAIN@'
                           AND lower(rl.localcode) = 'root_caseworker'))