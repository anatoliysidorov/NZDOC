SELECT
       u.userid          AS col_id,
       u.userid          AS userid,
       CASE u.source
       WHEN 0 THEN 'DB'
       WHEN 1 THEN 'AD'
       ELSE 'DB'
       END                 AS LoginType,
       u.code            AS code,
       u.NAME            AS NAME,
       NULL              AS domainid,
       u.createdby       AS createdby,
       u.createddate     AS createddate,
       u.modifiedby      AS modifiedby,
       u.modifieddate    AS modifieddate,
       u.accesssubjectid AS accesssubjectid,
       u.login           AS login,
       u.source          AS SOURCE,
       u.profile         AS PROFILE,
       u.status          AS status,
       ora_m.islockedout AS islockedout,
       u.issystem        AS issystem,
       prof.title        AS POSITION,
       prof.photo        AS PHOTO,
       prof.email        AS EMAIL,
       prof.firstname    AS FIRSTNAME,
       prof.lastname     AS LASTNAME,
       prof.city         AS CITY,
       prof.state        AS STATE,
       prof.phone        AS PHONE,
       prof.cellphone    AS CELLPHONE,
       prof.birthday     AS BIRTHDAY,
       prof.fax          AS FAX,
       prof.country      AS COUNTRY,
       prof.street       AS STREET,
       prof.zip          AS ZIP,
       prof.localecode   AS LOCALE,
       prof.languagecode AS LANGUAGE,
       prof.timezone     AS TIMEZONE,
       sup.NAME          AS SUPERVISOR,
       cws.col_id        AS ID,
       acc.code          AS ACCODE,
       cws.col_isdeleted AS ISDELETED,
       cws.col_code AS CW_CODE,
       cws.col_extsysid  AS EXTSYSID,
       --CALCULATED
       CASE
         WHEN NVL(ora_m.islockedout, 0) = 0 AND NVL(u.status, 0) = 0 AND NVL(cws.col_isdeleted, 0) = 0 THEN
          1
         ELSE
          0
       END AS ISACTIVE,
       --CALCULATED
       CASE
         WHEN NVL(ora_m.islockedout, 0) = 0 AND NVL(u.status, 0) = 0 AND NVL(cws.col_isdeleted, 0) = 0 THEN
          1
         ELSE
          -1
       END AS CWSTATUS
  FROM tbl_ppl_caseworker cws
 INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_user u
    ON (u.userid = cws.col_userid)
  LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_user sup
    ON (sup.userid = u.refsupervisorid)
 INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.user_profile prof
    ON (u.userid = prof.userid)
 INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_accesssubject acc
    ON (u.accesssubjectid = acc.accesssubjectid)
  LEFT OUTER JOIN @TOKEN_SYSTEMDOMAINUSER@.ora_aspnet_users ora_u
    ON (ora_u.username = u.login)
  LEFT OUTER JOIN @TOKEN_SYSTEMDOMAINUSER@.ora_aspnet_membership ora_m
    ON (ora_m.userid = ora_u.userid)