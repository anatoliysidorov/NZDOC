SELECT *
  FROM (SELECT col_id AS id,
               col_name AS NAME,
               col_code AS code,
               'Team' AS TYPE,
               col_description AS description,
               NULL AS skills,
               NULL AS teams,
               NULL AS businessroles,
               NULL AS email
          FROM tbl_ppl_team
         WHERE (:MEMBERTYPE IS NULL OR :MEMBERTYPE = 'TEAMS')
				AND :OBJECTTYPE = 'WORKBASKET'
				AND col_id IN (SELECT col_map_wb_tm_team FROM tbl_map_workbasketteam WHERE col_map_wb_tm_workbasket = :OBJECTID)
				<%= IfNotNull(":UNIFIED_SEARCH", " AND lower(COL_NAME) like F_UTIL_TOWILDCARDS(:UNIFIED_SEARCH)") %>  
        UNION ALL
        SELECT col_id AS id,
               col_name AS NAME,
               col_code AS code,
               'Skill' AS TYPE,
               col_description AS description,
               NULL AS skills,
               NULL AS teams,
               NULL AS businessroles,
               NULL AS email
          FROM tbl_ppl_skill
         WHERE (:MEMBERTYPE IS NULL OR :MEMBERTYPE = 'SKILLS')
				AND :OBJECTTYPE = 'WORKBASKET'
				AND col_id IN (SELECT tmw.COL_MAP_WS_SKILL FROM TBL_MAP_WORKBASKETSKILL tmw WHERE tmw.COL_MAP_WS_WORKBASKET = :OBJECTID)
				<%= IfNotNull(":UNIFIED_SEARCH", " AND lower(COL_NAME) like F_UTIL_TOWILDCARDS(:UNIFIED_SEARCH)") %>  
        UNION ALL
        SELECT col_id AS id,
               col_name AS NAME,
               col_code AS code,
               'Business Role' AS TYPE,
               col_description AS description,
               NULL AS skills,
               NULL AS teams,
               NULL AS businessroles,
               NULL AS email
          FROM tbl_ppl_businessrole
         WHERE (:MEMBERTYPE IS NULL OR :MEMBERTYPE = 'BUSINESSROLES')
				AND :OBJECTTYPE = 'WORKBASKET'
				AND col_id IN (SELECT col_map_wb_wr_businessrole FROM tbl_map_workbasketbusnessrole WHERE col_map_wb_br_workbasket = :OBJECTID)
				<%= IfNotNull(":UNIFIED_SEARCH", " AND lower(COL_NAME) like F_UTIL_TOWILDCARDS(:UNIFIED_SEARCH)") %>  
        UNION ALL
        SELECT cw.id AS id,
               cw.name AS NAME,
               NULL AS code,
               'Case Worker' AS TYPE,
               NULL AS description,
               (SELECT list_collect(cast(collect(to_char(skillname) order by to_char(skillname)) as split_tbl),'|||',1) 
                     --Listagg(TO_CHAR(skillname), '|||') within GROUP(ORDER BY skillname)
                  FROM (SELECT sk.col_name                AS skillname,
                               sk.col_id                  AS id,
                               cwsk.col_sk_ppl_caseworker
                          FROM tbl_caseworkerskill cwsk
                          LEFT JOIN tbl_ppl_skill sk
                            ON cwsk.col_tbl_ppl_skill = sk.col_id)
                 WHERE col_SK_ppl_caseworker = cw.id) AS skills,
               (SELECT list_collect(cast(collect(to_char(teamname) order by to_char(teamname)) as split_tbl),'|||',1)  
                   --Listagg(TO_CHAR(teamname), '|||') within GROUP(ORDER BY teamname)
                  FROM (SELECT tm.col_name AS teamname,
                               cwtm.col_tm_ppl_caseworker
                          FROM tbl_caseworkerteam cwtm
                          LEFT JOIN tbl_ppl_team tm
                            ON cwtm.col_tbl_ppl_team = tm.col_id)
                 WHERE col_tM_ppl_caseworker = cw.id) AS teams,
               (SELECT list_collect(cast(collect(to_char(rolename) order by to_char(rolename)) as split_tbl),'|||',1) 
                       --Listagg(TO_CHAR(rolename), '|||') within GROUP(ORDER BY rolename)
                  FROM (SELECT br.col_name AS rolename,
                               cwbr.col_br_ppl_caseworker
                          FROM tbl_caseworkerbusinessrole cwbr
                          LEFT JOIN tbl_ppl_businessrole br
                            ON cwbr.col_tbl_ppl_businessrole = br.col_id)
                 WHERE col_br_ppl_caseworker = cw.id) AS businessroles,
               cw.email AS email
          FROM vw_ppl_caseworkersusers cw
         WHERE     (       (   :MEMBERTYPE IS NULL
                            OR :MEMBERTYPE = 'CASEWORKERS')
                       AND :OBJECTTYPE = 'WORKBASKET'
                       AND cw.id IN
                               (SELECT col_map_wb_cw_caseworker
                                  FROM tbl_map_workbasketcaseworker
                                 WHERE col_map_wb_cw_workbasket = :OBJECTID)
                    OR     (   :MEMBERTYPE IS NULL
                            OR :MEMBERTYPE = 'CASEWORKERS')
                       AND :OBJECTTYPE = 'SKILL'
                       AND cw.id IN (SELECT col_SK_ppl_caseworker
                                       FROM tbl_caseworkerskill
                                      WHERE col_tbl_ppl_skill = :OBJECTID)
                    OR     (   :MEMBERTYPE IS NULL
                            OR :MEMBERTYPE = 'CASEWORKERS')
                       AND :OBJECTTYPE = 'TEAM'
                       AND cw.id IN (SELECT col_tM_ppl_caseworker
                                       FROM tbl_caseworkerteam
                                      WHERE col_tbl_ppl_team = :OBJECTID)
                    OR     (   :MEMBERTYPE IS NULL
                            OR :MEMBERTYPE = 'CASEWORKERS')
                       AND :OBJECTTYPE = 'BUSINESSROLE'
                       AND cw.id IN
                               (SELECT COL_BR_PPL_CASEWORKER
                                  FROM tbl_caseworkerbusinessrole
                                 WHERE col_tbl_ppl_businessrole = :OBJECTID))
               AND (   :UNIFIED_SEARCH IS NULL
                    OR LOWER (cw.name) LIKE
                           F_UTIL_TOWILDCARDS (:UNIFIED_SEARCH)
                    OR LOWER (cw.email) LIKE
                           F_UTIL_TOWILDCARDS (:UNIFIED_SEARCH)))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>