SELECT usr.*,
       t2.list_roles_names AS SECURITYROLES,
       t_groups.list_groups AS SECURITYGROUPS,
       t_roles.list_roles_names AS SROLES_WOUT_GROUPS_NAMES,
       t_roles.list_roles AS SECURITYROLES_WOUT_GROUPS,
       CASE
         WHEN nvl(usr.ID, 0) = 0 THEN
          0
         WHEN nvl(usr.ISDELETED, 0) = 1 THEN
          1
         WHEN nvl(INSTR(upper(t2.list_roles), 'ROOT_CASEWORKER'), 0) = 0 THEN
          2
         ELSE
          3
       END AS CALC_CSTATUS,
       CASE
         WHEN nvl(usr.USERID, 0) = 0 THEN
          0
         WHEN nvl(usr.STATUS, 0) = 1 THEN
          1
         WHEN nvl(usr.ISLOCKEDOUT, 0) = 1 THEN
          2
         ELSE
          3
       END AS CALC_USERSTATUS
  FROM (SELECT 'U_' || nvl(cw.col_userid, 0) || '_CW' || cw.col_id AS KEY_ID,
               nvl(usr.userid, 0) AS USERID,
               NVL(usr.STATUS, 0) AS STATUS,
               NVL(usr.ISLOCKEDOUT, 0) AS ISLOCKEDOUT,
               usr.LOGIN AS USERLOGIN,
               usr.FIRSTNAME AS FIRSTNAME,
               usr.LASTNAME AS LASTNAME,
               usr.ACCESSSUBJECTCODE AS USER_ACCESSSUBJECTCODE,
               usr.EMAIL AS EMAIL,
               usr.NAME AS NAME,
               cw.col_id AS ID,
               cw.COL_ISDELETED AS ISDELETED,
               cw.COL_ISMANUAL AS CW_ISMANUAL,
               cw.COL_NAME AS CW_NAME,
               cw.COL_EXTSYSID AS EXTERNALID,
               nvl(usr.SOURCE, 0) AS SOURCE,
               TO_CHAR(usr.PROFILE) AS LAST_LOGIN_TEXT,
               TO_DATE(usr.PROFILE, 'mm/dd/yyyy HH:MI:SS AM') AS LAST_LOGIN_DATE,
               usr.TITLE AS TITLE,
               prof.city AS CITY,
               prof.state AS STATE,
               prof.phone AS PHONE,
               prof.cellphone AS CELLPHONE,
               prof.birthday AS BIRTHDAY,
               prof.fax AS FAX,
               prof.country AS COUNTRY,
               prof.street AS STREET,
               prof.zip AS ZIP,
               prof.localecode AS LOCALE,
               prof.languagecode AS LANGUAGE,
               prof.timezone AS TIMEZONE
          FROM tbl_ppl_caseworker cw
          LEFT JOIN vw_users usr
            ON cw.col_userid = usr.userid
          LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.user_profile prof
            ON (usr.userid = prof.userid)
         WHERE (:USER_CW_ID IS NULL OR ('U_' || nvl(cw.col_userid, 0) || '_CW' || cw.col_id) = :USER_CW_ID)
        
        UNION
        SELECT 'U_' || nvl(usr.userid, 0) || '_CW0' AS KEY_ID,
               usr.userid AS USERID,
               NVL(usr.STATUS, 0) AS STATUS,
               NVL(usr.ISLOCKEDOUT, 0) AS ISLOCKEDOUT,
               usr.LOGIN AS USERLOGIN,
               usr.FIRSTNAME AS FIRSTNAME,
               usr.LASTNAME AS LASTNAME,
               usr.ACCESSSUBJECTCODE AS USER_ACCESSSUBJECTCODE,
               usr.EMAIL AS EMAIL,
               usr.NAME AS NAME,
               0 AS ID,
               0 AS ISDELETED,
               0 AS CW_ISMANUAL,
               NULL AS CW_NAME,
               NULL AS EXTERNALID,
               nvl(usr.SOURCE, 0) AS SOURCE,
               TO_CHAR(usr.PROFILE) AS LAST_LOGIN_TEXT,
               TO_DATE(usr.PROFILE, 'mm/dd/yyyy HH:MI:SS AM') AS LAST_LOGIN_DATE,
               usr.TITLE AS TITLE,
               prof.city AS CITY,
               prof.state AS STATE,
               prof.phone AS PHONE,
               prof.cellphone AS CELLPHONE,
               prof.birthday AS BIRTHDAY,
               prof.fax AS FAX,
               prof.country AS COUNTRY,
               prof.street AS STREET,
               prof.zip AS ZIP,               
               prof.localecode AS LOCALE,
               prof.languagecode AS LANGUAGE,
               prof.timezone AS TIMEZONE
          FROM vw_users usr
          LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.user_profile prof
            ON (usr.userid = prof.userid)
         WHERE usr.userid NOT IN (SELECT col_userid AS UserId FROM tbl_ppl_caseworker cw)
           AND (:USER_CW_ID IS NULL OR ('U_' || nvl(usr.userid, 0) || '_CW0') = :USER_CW_ID)) usr
  LEFT JOIN (SELECT t1.userid,
                    list_collect(cast(collect(to_char(t1.localCode) order by to_char(t1.localCode)) as split_tbl),'|||',1) as list_roles,
                    list_collect(cast(collect(to_char(t1.rolename) order by to_char(t1.rolename)) as split_tbl),'|||',1) as list_roles_names                   
               FROM (SELECT usr_roles.USERID AS userid,
                            role.localCode AS localCode,
                            TRIM(SUBSTR(role.name, 1, INSTR(role.name, '(', 1, 1) - 1)) AS rolename
                       FROM @TOKEN_SYSTEMDOMAINUSER@.asf_userrole usr_roles
                       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_role role
                         ON usr_roles.roleid = role.roleid
                      WHERE role.envid = '@TOKEN_DOMAIN@'

                     UNION
                     SELECT usr_groups.userid AS userid,
                            role.localCode AS localCode,
                            TRIM(SUBSTR(role.name, 1, INSTR(role.name, '(', 1, 1) - 1)) AS rolename
                       FROM @TOKEN_SYSTEMDOMAINUSER@.asf_usergroup usr_groups
                       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_grouprole group_role
                         ON usr_groups.groupid = group_role.groupid
                       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_role role
                         ON group_role.roleid = role.roleid
                      WHERE role.envid = '@TOKEN_DOMAIN@') t1
              GROUP BY t1.userid) t2
    ON t2.userid = usr.USERID
  LEFT JOIN (SELECT usr_group.userid,
                    list_collect(cast(collect(to_char(t_group.Code) order by to_char(t_group.Code)) as split_tbl),'|||',1) as list_groups
               FROM vw_UserGroup usr_group
               LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.ASF_GROUP t_group
                 ON (t_group.GROUPID = usr_group.GROUPID AND nvl(usr_group.SOURCE, 0) = 0)
              GROUP BY usr_group.userid) t_groups
    ON t_groups.userid = usr.USERID
  LEFT JOIN ( SELECT usr_role.userid,
                    list_collect(cast(collect(to_char(t_role.localCode) order by to_char(t_role.localCode)) as split_tbl),'|||',1) as list_roles,
                    list_collect(cast(collect(to_char(SUBSTR(t_role.name, 1, INSTR(t_role.name, '(', 1, 1) - 1)) order by to_char(t_role.name)) as split_tbl),'|||',1) as list_roles_names
               FROM vw_UserRole usr_role
               LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.ASF_ROLE t_role
                 ON (usr_role.ROLEID = t_role.ROLEID)
              WHERE t_role.envid = '@TOKEN_DOMAIN@'
              GROUP BY usr_role.userid
              UNION ALL
              (SELECT t.userid,
          list_collect(cast(collect(to_char(t.role_code) order by to_char(t.role_code)) as split_tbl),'|||',1) as list_roles,
          list_collect(cast(collect(to_char(SUBSTR(t.role_name, 1, INSTR(t.role_name, '(', 1, 1) - 1)) order by to_char(t.role_name)) as split_tbl),'|||',1) as list_roles_names
          FROM (SELECT usr_groups.userid,
                    t_role.localcode AS role_code,
                    t_role.name AS role_name
            FROM @TOKEN_SYSTEMDOMAINUSER@.asf_usergroup usr_groups
            LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_grouprole group_role
              ON usr_groups.groupid = group_role.groupid
            LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_role t_role
              ON group_role.roleid = t_role.roleid
              WHERE t_role.envid = '@TOKEN_DOMAIN@'
              GROUP BY usr_groups.userid, t_role.localcode, t_role.name) t
              GROUP BY t.userid) ) t_roles
    ON t_roles.userid = usr.USERID
 WHERE (:USERNAME IS NULL OR (upper(nvl(usr.NAME, 'null')) LIKE ('%' || upper(:USERNAME) || '%')))
   AND (:USERLOGIN IS NULL OR (upper(nvl(usr.USERLOGIN, 'null')) LIKE ('%' || upper(:USERLOGIN) || '%')))
   AND (:USEREMAIL IS NULL OR (upper(nvl(usr.EMAIL, 'null')) LIKE ('%' || upper(:USEREMAIL) || '%')))
   AND (:USERID IS NULL OR (nvl(usr.USERID, 0) = :USERID))
   AND (:CWID IS NULL OR (nvl(usr.ID, 0) = :CWID))
   AND (nvl(:DELETED, 0) = 0 OR (nvl(usr.ISDELETED, 0) = 1))
   AND (nvl(:MANUAL, 0) = 0 OR (nvl(usr.CW_ISMANUAL, 0) = 1))
   AND (nvl(:ACTIVE, 0) = 0 OR (nvl(usr.STATUS, 0) = 0))
   AND (nvl(:INACTIVE, 0) = 0 OR (nvl(usr.STATUS, 0) <> 0))
   AND (:ROLES_CODES IS NULL OR EXISTS (
                                        SELECT  to_char(regexp_substr(t2.list_roles,'[[:'||'alnum:]_]+',1,LEVEL)) lr
                                          FROM dual
                                          CONNECT BY dbms_lob.getLength(regexp_substr(t2.list_roles,'[[:'||'alnum:]_]+',1,LEVEL))> 0
                                          intersect
                                         SELECT  to_char(regexp_substr(:ROLES_CODES,'[[:alnum:]_]+',1,LEVEL)) lr
                                          FROM dual
                                          CONNECT BY dbms_lob.getLength(regexp_substr(:ROLES_CODES,'[[:'||'alnum:]_]+',1,LEVEL))> 0
                                          )
       )
<%= IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1") %>