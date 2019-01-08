SELECT wb.col_id                      AS ID,
            wb.col_id                      AS COL_ID,
            wb.col_name                    AS NAME,
            wb.col_code                    AS CODE,
            wbt.col_id                     AS WorkBasketType_Id,
            wbt.col_name                   AS WorkBasketType_Name,
            wbt.col_code                   AS WorkBasketType_Code,
            u.accesssubjectcode            AS ACCESSSUBJECTCODE,
            u.email                        AS EmailAddress,
            --what associated to
            cw.col_id AS Caseworker_Id,
            ep.col_id AS ExternalParty_Id,
            t.col_id  AS Team_Id,
            s.col_id  AS Skill_Id,
            br.col_id AS BusinessRole_Id,
            CASE
                    WHEN wb.col_caseworkerworkbasket > 0 THEN u.name
                    WHEN wb.col_workbasketteam > 0 THEN t.col_name
                    WHEN wb.col_workbasketexternalparty > 0 THEN ep.col_name
                    WHEN wb.col_workbasketskill > 0 THEN s.col_name
                    WHEN wb.col_workbasketbusinessrole > 0 THEN br.col_name
                    ELSE NVL(wb.col_name,'MISSING')
            END AS CalcName
FROM tbl_ppl_workbasket wb
LEFT JOIN tbl_dict_workbaskettype wbt ON wbt.col_id = wb.col_workbasketworkbaskettype
          --for case workers -> use their real user's name
LEFT JOIN tbl_ppl_caseworker cw ON cw.col_id = wb.col_caseworkerworkbasket AND wbt.col_code = 'PERSONAL'
LEFT JOIN vw_users u ON u.userid = cw.col_userid
          --external party, team, br, and skill
LEFT JOIN tbl_externalparty ep ON ep.col_id = wb.col_workbasketexternalparty
LEFT JOIN tbl_ppl_team t ON t.col_id = wb.col_workbasketteam
LEFT JOIN tbl_ppl_skill s ON s.col_id = wb.col_workbasketskill
LEFT JOIN tbl_ppl_businessrole br ON br.col_id = wb.col_workbasketbusinessrole