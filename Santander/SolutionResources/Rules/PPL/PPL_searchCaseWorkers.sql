SELECT cw.id AS Id,
       cw.userid AS UserId,
       cw.ExtSysId AS ExternalId,
       cw.isdeleted AS IsDeleted,
       NVL(cw.name, cw.firstname || ' ' || cw.lastname) AS NAME,
       cw.CW_CODE AS CODE,
       cw.logintype AS LOGINTYPE,
       cw.firstname AS FIRSTNAME,
       cw.lastname AS LASTNAME,
       cw.login AS USERLOGIN,
       cw.photo AS PHOTO,
       cw.email AS EMAIL,
       (SELECT list_collect(cast(collect(to_char(s2.col_Name) order by to_char(s2.col_Name)) as split_tbl),'|||',1) 
               FROM tbl_caseworkerskill cws2 
               LEFT JOIN tbl_ppl_skill s2
                 ON cws2.col_tbl_ppl_skill = s2.col_id
               WHERE cw.ID = cws2.col_sk_ppl_caseworker
              GROUP BY cws2.col_sk_ppl_caseworker) AS skills,
       (SELECT list_collect(cast(collect(to_char(t2.col_Name) order by to_char(t2.col_Name)) as split_tbl),'|||',1)
               FROM tbl_caseworkerteam cwt2
               LEFT JOIN tbl_ppl_team t2
                 ON cwt2.col_tbl_ppl_team = t2.col_id
               WHERE cw.id = cwt2.col_tm_ppl_caseworker
              GROUP BY cwt2.col_tm_ppl_caseworker) teams,
       (SELECT list_collect(cast(collect(to_char(br2.col_Name) order by to_char(br2.col_Name)) as split_tbl),'|||',1) 
               FROM tbl_caseworkerbusinessrole cwb2
               LEFT JOIN tbl_ppl_businessrole br2
                 ON cwb2.col_tbl_ppl_businessrole = br2.col_id
               WHERE  cw.id = cwb2.COL_BR_PPL_CASEWORKER 
              GROUP BY cwb2.col_br_ppl_caseworker) AS b_roles, 
       cw.STATUS AS STATUS,
       cw.ISLOCKEDOUT AS ISLOCKEDOUT,
       cw.isactive AS ISACTIVE,
       cw.position AS TITLE,
       cw.city AS CITY,
       cw.state AS STATE,
       cw.phone AS PHONE,
       cw.cellphone AS CELLPHONE,
       cw.birthday AS BIRTHDAY,
       cw.fax AS FAX,
       cw.country AS COUNTRY,
       cw.street AS STREET,
       cw.zip AS ZIP,
       cw.locale AS LOCALE,
       cw.language AS LANGUAGE,
       cw.timezone AS TIMEZONE,
       cw.ACCODE AS ACCODE,
--Skills, Teams and Business Roles for Grouping
       (SELECT list_collect(cast(collect(to_char(t1.localCode) order by to_char(t1.userid)) as split_tbl),'|||',1) AS list_roles
               FROM (SELECT usr_roles.USERID AS userid,
                            role.localCode   AS localCode
                       FROM @TOKEN_SYSTEMDOMAINUSER@.asf_userrole usr_roles
                       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_role role
                         ON usr_roles.roleid = role.roleid
                      WHERE role.envid = '@TOKEN_DOMAIN@'
                     UNION
                     SELECT usr_groups.userid AS userid,
                            role.localCode    AS localCode
                       FROM @TOKEN_SYSTEMDOMAINUSER@.asf_usergroup usr_groups
                       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_grouprole group_role
                         ON usr_groups.groupid = group_role.groupid
                       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_role role
                         ON group_role.roleid = role.roleid
                      WHERE role.envid = '@TOKEN_DOMAIN@') t1
              WHERE t1.userid = cw.USERID
              GROUP BY t1.userid) AS SECURITYROLES,
        (SELECT list_collect(cast(collect(to_char(t_group.Code) order by to_char(usr_group.userid)) as split_tbl),'|||',1) AS list_groups
               FROM vw_UserGroup usr_group
               LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.ASF_GROUP t_group
                 ON (t_group.GROUPID = usr_group.GROUPID AND nvl(usr_group.SOURCE, 0) = 0)
               WHERE usr_group.userid = cw.USERID  
              GROUP BY usr_group.userid) SECURITYGROUPS,
         (SELECT 
                    list_collect(cast(collect(to_char(t_role.localCode) order by to_char(usr_role.userid)) as split_tbl),'|||',1) AS list_roles
               FROM vw_UserRole usr_role
               LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.ASF_ROLE t_role
                 ON (usr_role.ROLEID = t_role.ROLEID)
              WHERE usr_role.userid = cw.USERID
              AND t_role.envid = '@TOKEN_DOMAIN@'
              GROUP BY usr_role.userid) SECURITYROLES_WOUT_GROUPS,
       wb.col_id AS WORKBASKET_ID
  FROM vw_ppl_caseworkersusers cw
  LEFT JOIN tbl_ppl_workbasket wb ON cw.id = wb.COL_CASEWORKERWORKBASKET
 WHERE (:Caseworker_Id IS NULL OR (:Caseworker_Id IS NOT NULL AND cw.id = :Caseworker_Id))
   AND (:IsDeleted IS NULL OR NVL(cw.isdeleted, 0) = :IsDeleted)
   AND (:Name_VALUE1 IS NULL OR (:Name_VALUE1 IS NOT NULL AND LOWER(cw.name) LIKE '%' || LOWER(:Name_VALUE1) || '%'))
   AND (:Skill_VALUE1 IS NULL OR (:Skill_VALUE1 IS NOT NULL AND EXISTS(SELECT 1 FROM tbl_ppl_skill S, 
                                                                                      tbl_caseworkerskill cws 
                                                                                 WHERE cws.col_tbl_ppl_skill = s.col_id 
                                                                                 AND cw.id = cws.col_sk_ppl_caseworker
                                                                                 AND :Skill_VALUE1 = s.col_id) 
                                  )
       )
   AND (:teams_VALUE1 IS NULL OR (:teams_VALUE1 IS NOT NULL AND EXISTS(SELECT 1 FROM tbl_ppl_team t, tbl_caseworkerteam cwt 
                                                                                where cwt.col_tbl_ppl_team = t.col_id AND cw.id = cwt.col_tm_ppl_caseworker
                                                                                   AND t.col_id = :teams_VALUE1)
                                 )
        )
   AND (:b_roles_VALUE1 IS NULL OR (:b_roles_VALUE1 IS NOT NULL AND EXISTS(SELECT 1 FROM tbl_ppl_businessrole br, tbl_caseworkerBusinessRole cwb 
                                                                                     where cwb.col_tbl_ppl_businessrole = br.col_id 
                                                                                      AND cw.id = cwb.COL_BR_PPL_CASEWORKER
                                                                                      AND br.col_id = :b_roles_VALUE1)
                                   )
       )
   AND (:Status IS NULL OR (:Status IS NOT NULL AND cw.isactive = :Status))
   AND (:CurrentUser IS NULL OR (:CurrentUser IS NOT NULL AND cw.id = f_DCM_getCaseWorkerId()))
   AND (:Team_CODE IS NULL OR EXISTS(SELECT 1 FROM tbl_ppl_team t, tbl_caseworkerteam cwt 
                                                                            where cwt.col_tbl_ppl_team = t.col_id 
                                                                               AND cw.id = cwt.col_tm_ppl_caseworker
                                                                               AND lower(t.col_code) = LOWER(:Team_CODE))
       )
   AND (:Skill_CODE IS NULL OR EXISTS(SELECT 1 FROM tbl_ppl_skill S, tbl_caseworkerskill cws 
                                                            where cws.col_tbl_ppl_skill = s.col_id 
                                                              AND cw.id = cws.col_sk_ppl_caseworker
                                                              AND lower(s.col_code) = LOWER(:Skill_CODE)
                                )
        )
   AND (:BusinessRole_CODE IS NULL OR EXISTS(SELECT 1 FROM tbl_ppl_businessrole br, tbl_caseworkerBusinessRole cwb 
                                                                                  where cwb.col_tbl_ppl_businessrole = br.col_id 
                                                                                      AND cw.id = cwb.COL_BR_PPL_CASEWORKER
                                                                                      AND lower(br.col_code) = LOWER(:BusinessRole_CODE))
        )
   AND (:Team_CODES IS NULL OR EXISTS(SELECT 1 FROM tbl_ppl_team t, tbl_caseworkerteam cwt 
                                                                            where cwt.col_tbl_ppl_team = t.col_id 
                                                                                AND cw.id = cwt.col_tm_ppl_caseworker
                                                                                AND lower(t.col_code) IN (SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:Team_CODES, ',')))
                                      )
       )
   AND (:Skill_CODES IS NULL OR EXISTS(SELECT 1 FROM tbl_ppl_skill S, tbl_caseworkerskill cws 
                                                          where cws.col_tbl_ppl_skill = s.col_id AND cw.id = cws.col_sk_ppl_caseworker
                                                              AND lower(s.col_code) IN (SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:Skill_CODES, ',')))
                                       )
        )
   AND (:BusinessRole_CODES IS NULL OR EXISTS (SELECT 1 FROM tbl_ppl_businessrole br, tbl_caseworkerBusinessRole cwb 
                                                                                   where cwb.col_tbl_ppl_businessrole = br.col_id 
                                                                                      AND cw.id = cwb.COL_BR_PPL_CASEWORKER
                                                                                      AND lower(br.col_code) IN (SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:BusinessRole_CODES, ',')))
                                               )
       )
   AND (:PSEARCH IS NULL OR LOWER(NVL(cw.name, cw.firstname || ' ' || cw.lastname)) LIKE '%' || LOWER(:PSEARCH) || '%')
   <%=Sort("@SORT@","@DIR@")%>