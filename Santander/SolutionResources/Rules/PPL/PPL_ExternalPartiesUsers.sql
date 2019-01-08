SELECT accounts.userid              AS userid,
       accounts.userid              AS col_id,
       accounts.code                AS code,
       accounts.NAME                AS NAME,
       NULL                         AS domainid,
       accounts.createdby           AS createdby,
       accounts.createddate         AS createddate,
       accounts.modifiedby          AS modifiedby,
       accounts.modifieddate        AS modifieddate,
       accounts.accesssubjectid     AS accesssubjectid,
       accounts.login               AS login,
       accounts.source              AS SOURCE,
       accounts.profile             AS PROFILE,
       accounts.status              AS status,
       accounts.issystem            AS issystem,
       prof.title                   AS POSITION,
       prof.photo                   AS PHOTO,
       prof.email                   AS EMAIL,
       prof.firstname               AS FIRSTNAME,
       prof.lastname                AS LASTNAME,
       prof.city                    AS CITY,
       prof.state                   AS STATE,
       prof.phone                   AS PHONE,
       supervisors.NAME             AS SUPERVISOR,
       ep.col_id                    AS ID,
       ep.col_code                  AS EPCODE,
       ep.col_name                  AS EPNAME,
       ep.col_extpartyaccesssubject AS EPACCESSSUBJECTID,
       acc.code                     AS ACCODE
  FROM tbl_externalparty ep
 INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_user accounts
    ON (accounts.userid = ep.col_userid)
  LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_user supervisors
    ON (supervisors.userid = accounts.refsupervisorid)
 INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.user_profile prof
    ON (accounts.userid = prof.userid)
 INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_accesssubject acc
    ON (accounts.accesssubjectid = acc.accesssubjectid)
