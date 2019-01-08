SELECT 
	   acc.accesssubjectid as col_id,
       acc.code    AS CODE, 
       acc.NAME    AS NAME, 
       acc.type    AS TYPE, 
       p.firstname AS FIRSTNAME, 
       p.lastname  AS LASTNAME 
FROM   @TOKEN_SYSTEMDOMAINUSER@.asf_accesssubject acc 
       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_user u 
              ON ( u.accesssubjectid = acc.accesssubjectid ) 
       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.user_profile p 
              ON ( p.userid = u.userid ) 