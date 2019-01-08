SELECT    wb.col_id                                                 AS ID,
          wb.col_id                                                 AS COL_ID,
          wb.col_name                                               AS NAME,
          wb.col_code                                               AS CODE,
          wbt.col_id                                                AS WorkBasketType_Id,
          wbt.col_name                                              AS WorkBasketType_Name,
          wbt.col_code                                              AS WorkBasketType_Code,
          NVL(wb.col_isdefault,0)                                   AS IsDefault,
          NVL(wb.col_isprivate,0)                                   AS IsPrivate,
          u.ACCESSSUBJECTCODE                                       AS ACCESSSUBJECTCODE,
          u.EMAIL                                                   as EmailAddress,
          GREATEST(NVL(ep.COL_ISDELETED,0),NVL(cw.COL_ISDELETED,0)) AS ISDELETED,
          --what associated to
          cw.col_id AS Caseworker_Id,
          ep.col_id AS ExternalParty_Id,
          t.col_id  AS Team_Id,
          s.col_id  AS Skill_Id,
          br.col_id AS BusinessRole_Id,
          CASE
                    WHEN NVL(cw.col_id,0) > 0 AND u.userid > 0 THEN u.name
                    WHEN NVL(t.col_id,0) > 0 THEN t.col_name
                    WHEN NVL(ep.col_id,0) > 0 THEN ep.col_name
                    WHEN NVL(s.col_id,0) > 0 THEN s.col_name
                    WHEN NVL(br.col_id,0) > 0 THEN br.col_name ELSE NVL(wb.col_name,'MISSING')
          END AS CalcName,
          CASE
                    WHEN NVL(cw.col_id,0) > 0 THEN 'Case Worker'
                    WHEN NVL(t.col_id,0) > 0 THEN 'Team'
                    WHEN NVL(ep.col_id,0) > 0 THEN 'External Party'
                    WHEN NVL(s.col_id,0) > 0 THEN 'Skill'
                    WHEN NVL(br.col_id,0) > 0 THEN 'Business Role' ELSE 'Group Workbasket'
          END AS CalcType,
          CASE
                    WHEN NVL(cw.col_id,0) > 0 THEN 'CASEWORKER'
                    WHEN NVL(t.col_id,0) > 0 THEN 'TEAM'
                    WHEN NVL(ep.col_id,0) > 0 THEN 'EXTERNALPARTY'
                    WHEN NVL(s.col_id,0) > 0 THEN 'SKILL'
                    WHEN NVL(br.col_id,0) > 0 THEN 'BUSINESSROLE' ELSE 'GROUPWB'
          END                     AS CalcTypeCode
FROM      tbl_ppl_workbasket         wb
LEFT JOIN tbl_dict_workbaskettype    wbt ON(wbt.col_id = wb.col_workbasketworkbaskettype)
          --for case workers -> use their real user's name
LEFT JOIN tbl_ppl_caseworker cw ON(cw.col_id = wb.COL_CASEWORKERWORKBASKET
          AND wbt.col_code = 'PERSONAL')
LEFT JOIN vw_users u ON(u.userid = cw.col_userid)
          --external party, team, br, and skill
LEFT JOIN tbl_externalparty    ep ON(ep.col_id = wb.COL_WORKBASKETEXTERNALPARTY)
LEFT JOIN tbl_ppl_team         t  ON(t.col_id = wb.COL_WORKBASKETTEAM)
LEFT JOIN tbl_ppl_skill        s  ON(s.col_id = wb.COL_WORKBASKETSKILL)
LEFT JOIN tbl_ppl_businessrole br ON(br.col_id = wb.COL_WORKBASKETBUSINESSROLE)