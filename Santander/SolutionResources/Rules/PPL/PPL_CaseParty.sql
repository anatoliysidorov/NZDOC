SELECT cp.col_id AS Id,
       cp.col_id AS Col_Id,
       cp.col_name AS NAME,
       cp.col_allowdelete AS AllowDelete,
       cp.col_casepartycase AS Case_Id,
       (SELECT CASESTATE_ISFINISH
          FROM vw_dcm_simplecase
         WHERE id = cp.col_casepartycase)
          AS CaseState_IsFinish,
       cp.col_description AS Description,
       cp.col_casepartydict_unittype AS PartyType_Id,
       pt.col_name AS PartyType_Name,
       pt.col_code AS PartyType_Code,
       cp.col_CustomConfig AS CustomConfig,
       cw.id AS CaseWorker_Id,
       t.col_id AS Team_Id,
       br.col_id AS BusinessRole_Id,
       s.col_id AS Skill_Id,
       extP.col_id AS ExternalParty_Id,
       --CALCULATED
       CASE LOWER (NVL (pt.col_code, N'TEXT'))
          WHEN N'external_party'
          THEN
             extP.col_id
          ELSE
             (CASE LOWER (NVL (pt.col_code, N'TEXT'))
                 WHEN N'caseworker' THEN cw.id
                 WHEN N'team' THEN t.col_id
                 WHEN N'businessrole' THEN br.col_id
                 WHEN N'skill' THEN s.col_id
                 ELSE 0
              END)
       END
          AS CALC_ID,
       CASE LOWER (NVL (pt.col_code, N'TEXT'))
          WHEN N'external_party'
          THEN
             extP.col_name
          ELSE
             (CASE LOWER (NVL (pt.col_code, N'TEXT'))
                 WHEN N'caseworker' THEN cw.name
                 WHEN N'team' THEN t.col_name
                 WHEN N'businessrole' THEN br.col_name
                 WHEN N'skill' THEN s.col_name
                 ELSE N''
              END)
       END
          AS CALC_NAME,
       CASE LOWER (NVL (pt.col_code, N'TEXT'))
          WHEN N'external_party'
          THEN
             extP.col_email
          ELSE
             (CASE LOWER (NVL (pt.col_code, N'TEXT'))
                 WHEN N'caseworker' THEN cw.email
                 ELSE N''
              END)
       END
          AS CALC_EMAIL,
       CASE LOWER (NVL (pt.col_code, N'TEXT'))
          WHEN N'external_party'
          THEN
             extP.col_extsysid
          ELSE
             (CASE LOWER (NVL (pt.col_code, N'TEXT'))
                 WHEN N'caseworker' THEN cw.extsysid
                 ELSE N''
              END)
       END
          AS CALC_EXTSYSID
  FROM tbl_caseparty cp
       LEFT JOIN tbl_dict_participantunittype pt
          ON pt.col_id = cp.col_casepartydict_unittype
       LEFT JOIN vw_ppl_activecaseworkersusers cw
          ON cp.col_casepartyppl_caseworker = cw.id
       LEFT JOIN tbl_externalparty extP
          ON cp.col_casepartyexternalparty = extP.col_id
       LEFT JOIN tbl_ppl_team t
          ON cp.col_casepartyppl_team = t.col_id
       LEFT JOIN tbl_ppl_businessrole br
          ON cp.col_casepartyppl_businessrole = br.col_id
       LEFT JOIN tbl_ppl_skill s
          ON cp.col_casepartyppl_skill = s.col_id