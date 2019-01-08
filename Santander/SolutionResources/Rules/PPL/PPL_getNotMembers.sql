SELECT * FROM (
    SELECT 
    COL_ID AS ID,
    COL_NAME AS NAME,
    COL_CODE AS CODE,
    COL_DESCRIPTION AS DESCRIPTION,
    NULL AS SKILLS,
    NULL AS TEAMS,
    NULL AS BUSINESSROLES,
    NULL AS EMAIL    
    FROM TBL_PPL_TEAM 
    WHERE :MEMBERTYPE = 'TEAMS' AND :OBJECTTYPE = 'WORKBASKET' 
	 		AND COL_ID NOT IN (SELECT COL_MAP_WB_TM_TEAM FROM TBL_MAP_WORKBASKETTEAM WHERE COL_MAP_WB_TM_WORKBASKET = :OBJECTID)
			<%= IfNotNull(":UNIFIED_SEARCH", " AND lower(COL_NAME) like F_UTIL_TOWILDCARDS(:UNIFIED_SEARCH)") %>  

    UNION ALL

    SELECT 
    COL_ID AS ID,
    COL_NAME AS NAME,
    COL_CODE AS CODE,
    COL_DESCRIPTION AS DESCRIPTION,
    NULL AS SKILLS,
    NULL AS TEAMS,
    NULL AS BUSINESSROLES,
    NULL AS EMAIL
    FROM TBL_PPL_BUSINESSROLE
    WHERE :MEMBERTYPE = 'BUSINESSROLES' AND :OBJECTTYPE = 'WORKBASKET'
			AND COL_ID NOT IN (SELECT COL_MAP_WB_WR_BUSINESSROLE FROM TBL_MAP_WORKBASKETBUSNESSROLE  WHERE COL_MAP_WB_BR_WORKBASKET = :OBJECTID)
			<%= IfNotNull(":UNIFIED_SEARCH", " AND lower(COL_NAME) like F_UTIL_TOWILDCARDS(:UNIFIED_SEARCH)") %>  

    UNION ALL

    SELECT 
    COL_ID AS ID,
    COL_NAME AS NAME,
    COL_CODE AS CODE,
    COL_DESCRIPTION AS DESCRIPTION,
    NULL AS SKILLS,
    NULL AS TEAMS,
    NULL AS BUSINESSROLES,
    NULL AS EMAIL
    FROM  tbl_ppl_skill
    WHERE :MEMBERTYPE = 'SKILLS' AND :OBJECTTYPE = 'WORKBASKET' 
          AND COL_ID NOT IN (SELECT COL_MAP_WS_SKILL 
                            FROM TBL_MAP_WORKBASKETSKILL  
                            WHERE COL_MAP_WS_WORKBASKET = :OBJECTID)  
			<%= IfNotNull(":UNIFIED_SEARCH", " AND lower(COL_NAME) like F_UTIL_TOWILDCARDS(:UNIFIED_SEARCH)") %> 
					 
    UNION ALL 

    SELECT 
    CW.ID AS ID,
    CW.NAME AS NAME,
    NULL AS CODE,
    NULL AS DESCRIPTION,
        (SELECT list_collect(cast(collect(to_char(SkillName) order by to_char(SkillName)) as split_tbl),',',1)  
              --  LISTAGG(SkillName, ',') WITHIN GROUP (ORDER BY SkillName)
        FROM (select sk.col_name as SkillName,
                sk.col_id as Id,
                cwsk.col_sk_ppl_caseworker
                FROM TBL_CASEWORKERSKILL cwsk
                LEFT JOIN tbl_ppl_skill sk on cwsk.COL_TBL_PPL_SKILL = sk.col_id )
        WHERE COL_sk_PPL_CASEWORKER = CW.ID)
        AS SKILLS,
        (SELECT list_collect(cast(collect(to_char(TeamName) order by to_char(TeamName)) as split_tbl),',',1)  
            --LISTAGG(TeamName, ',') WITHIN GROUP (ORDER BY TeamName)
        FROM (select tm.col_name as TeamName,
                cwtm.col_tm_ppl_caseworker
                FROM TBL_CASEWORKERTEAM cwtm
                LEFT JOIN tbl_ppl_team tm on cwtm.COL_TBL_PPL_TEAM = tm.col_id )      
        WHERE   COL_Tm_PPL_CASEWORKER = CW.ID)
                AS TEAMS,
        (SELECT list_collect(cast(collect(to_char(RoleName) order by to_char(RoleName)) as split_tbl),',',1)  
              --LISTAGG(RoleName, ',') WITHIN GROUP (ORDER BY RoleName) 
        FROM (select br.col_name as RoleName,
                cwbr.col_br_ppl_caseworker as CaseWorkerId
                from tbl_caseworkerbusinessrole cwbr
                Left join tbl_ppl_businessrole br on Cwbr.Col_Tbl_Ppl_Businessrole = br.col_id)
        WHERE CaseWorkerId = CW.ID)
        AS BUSINESSROLES,
        CW.EMAIL AS EMAIL    
    FROM VW_PPL_ACTIVECASEWORKERSUSERS CW
    WHERE (:MEMBERTYPE = 'CASEWORKERS' AND :OBJECTTYPE = 'WORKBASKET' AND CW.ID NOT IN (SELECT COL_MAP_WB_CW_CASEWORKER FROM TBL_MAP_WORKBASKETCASEWORKER WHERE COL_MAP_WB_CW_WORKBASKET = :OBJECTID) OR
        :MEMBERTYPE = 'CASEWORKERS' AND :OBJECTTYPE = 'SKILL' AND CW.ID NOT IN (SELECT COL_sk_PPL_CASEWORKER FROM TBL_CASEWORKERSKILL WHERE COL_TBL_PPL_SKILL = :OBJECTID) OR
        :MEMBERTYPE = 'CASEWORKERS' AND :OBJECTTYPE = 'TEAM' AND CW.ID NOT IN (SELECT COL_Tm_PPL_CASEWORKER FROM TBL_CASEWORKERTEAM WHERE COL_TBL_PPL_TEAM = :OBJECTID) OR
        :MEMBERTYPE = 'CASEWORKERS' AND :OBJECTTYPE = 'BUSINESSROLE' AND CW.ID NOT IN (SELECT col_br_ppl_caseworker FROM TBL_CASEWORKERBUSINESSROLE WHERE COL_TBL_PPL_BUSINESSROLE = :OBJECTID))
        AND ((:CWNAME IS NULL) OR (:CWNAME IS NOT NULL AND UPPER(CW.NAME) LIKE '%'||UPPER(:CWNAME)||'%'))
               AND (   :UNIFIED_SEARCH IS NULL
                    OR LOWER (cw.name) LIKE
                           F_UTIL_TOWILDCARDS (:UNIFIED_SEARCH)
                    OR LOWER (cw.email) LIKE
                           F_UTIL_TOWILDCARDS (:UNIFIED_SEARCH)))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>