SELECT 
    cw.ID AS ID ,
    cw.NAME AS CaseWorker_Name,
    cw.photo AS CaseWorker_Photo,
    cw.EMAIL AS CaseWorker_Email,
    cw.status AS CaseWorker_Status,
    
    list_collect(cast(collect(to_char(s2.col_name) order by to_char(s2.col_name)) as split_tbl),',',1) as skills,
    list_collect(cast(collect(to_char(t2.col_name) order by to_char(t2.col_name)) as split_tbl),',',1) as teams,
    list_collect(cast(collect(to_char(br2.col_name) order by to_char(br2.col_name)) as split_tbl),',',1) as b_roles
    
    FROM vw_ppl_activecaseworkersusers cw

  --Skill
    LEFT JOIN tbl_caseworkerskill cws ON (cw.ID = cws.COL_sk_PPL_CASEWORKER)
    LEFT JOIN tbl_ppl_skill s ON (cws.col_tbl_ppl_skill = s.col_id)

  --Team
    LEFT JOIN tbl_caseworkerteam cwt ON (cw.ID = cwt.col_tm_ppl_caseworker)
    LEFT JOIN tbl_ppl_team T ON (cwt.col_tbl_ppl_team = T.col_id)

  --BRoles
    LEFT JOIN tbl_caseworkerBusinessRole cwb ON (cw.ID = cwb.COL_BR_PPL_CASEWORKER)
    LEFT JOIN tbl_ppl_businessrole br ON (cwb.col_tbl_ppl_businessrole = br.col_id)

  --Skills, Teams and Business Roles for Grouping
    LEFT JOIN tbl_caseworkerskill cws2 ON (cw.ID = cws2.col_sk_ppl_caseworker)
     LEFT JOIN tbl_ppl_skill s2 ON (cws2.col_tbl_ppl_skill = s2.col_id)
    LEFT JOIN tbl_caseworkerteam cwt2 ON (cw.ID = cwt2.col_tM_ppl_caseworker)
    LEFT JOIN tbl_ppl_team t2 ON (cwt2.col_tbl_ppl_team = t2.col_id)
    LEFT JOIN tbl_caseworkerbusinessrole cwb2 ON cw.ID = cwb2.COL_br_PPL_CASEWORKER
    LEFT JOIN tbl_ppl_businessrole br2 ON cwb2.col_tbl_ppl_businessrole = br2.col_id
    GROUP BY 
        cw.ID,
        cw.NAME,
        cw.photo,
        cw.EMAIL,
        cw.status
