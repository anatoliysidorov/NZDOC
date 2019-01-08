WITH stateConfig AS
 (SELECT sc.col_Id AS StateConfigId
    FROM tbl_DICT_StateConfig sc
   INNER JOIN tbl_DICT_StateConfigType sct
      ON sct.col_Id = sc.col_StateConfStateConfType
     AND sct.col_Code = 'DOCUMENT'
   WHERE sc.col_IsCurrent = 1),
stateId AS
 (SELECT st.col_id AS StateId
    FROM TBL_DICT_STATE st
   WHERE col_code = 'DOCINDEXINGSTATES_WAITING_FOR_REVIEW'
     AND col_statestateconfig = (SELECT StateConfigId FROM stateConfig))
--Personal workbasket for the current caseworker
SELECT wbs.id,
       wbs.code AS code,
       wbs.CALCNAME,
       to_nchar('Assigned to me') AS DISPLAY_NAME,
       'Home' AS MENU_ITEM,
       (SELECT COUNT(*)
          FROM tbl_pi_workitem wi
         INNER JOIN vw_PPL_SimpleWorkbasket w
            ON wi.COL_PI_WORKITEMPPL_WORKBASKET = w.id
         INNER JOIN tbl_DICT_State st
            ON st.col_id = wi.col_pi_workitemdict_state
           AND st.col_StateStateConfig IN (SELECT StateConfigId FROM stateConfig)
           AND st.col_id = (SELECT StateId FROM stateId)
         WHERE w.id = wbs.id
           AND (nvl(wi.col_IsDeleted, 0) = 0)) AS ITEMSCOUNT,
       'inbox' AS ICON,
       'DOCINDEXINGSTATES_WAITING_FOR_REVIEW' AS AvailableWIState,
       1 AS SOrder
  FROM vw_PPL_SimpleWorkbasket wbs
 INNER JOIN vw_ppl_activecaseworkersusers cwu0
    ON wbs.CASEWORKER_ID = cwu0.id
 WHERE cwu0.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
   AND wbs.workbaskettype_code = 'PERSONAL'
UNION
-- All (Personal + Shared) workbaskets where current user participates
SELECT NULL AS id,
       to_nchar('ALL') AS code,
       NULL AS CALCNAME,
       to_nchar('All (work baskets)') AS DISPLAY_NAME,
       'Home' AS MENU_ITEM,
       (SELECT COUNT(*)
          FROM tbl_pi_workitem wi
         INNER JOIN vw_PPL_SimpleWorkbasket wbs
            ON wi.COL_PI_WORKITEMPPL_WORKBASKET = wbs.id
         INNER JOIN tbl_DICT_State st
            ON st.col_id = (SELECT StateId FROM stateId)
           AND st.col_id = wi.col_pi_workitemdict_state
        --Personal workbaskets many to one CaseWorker (should be only one)
          LEFT JOIN vw_ppl_activecaseworkersusers cwu0
            ON cwu0.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
           AND wbs.CASEWORKER_ID = cwu0.id
        --user linked to workbasket via Workbasket Many to many CaseWorker
          LEFT JOIN (SELECT mwbcw1.col_map_wb_cw_workbasket AS workbasket, cwu1.id AS Id, cwu1.accode AS accode
                      FROM tbl_map_workbasketcaseworker mwbcw1
                     INNER JOIN vw_ppl_activecaseworkersusers cwu1
                        ON cwu1.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu1.id = mwbcw1.col_map_wb_cw_caseworker
                    UNION
                    SELECT mwbbr3.col_map_wb_br_workbasket AS workbasket, cwu3.Id AS Id, cwu3.accode AS accode
                      FROM tbl_map_workbasketbusnessrole mwbbr3
                     INNER JOIN tbl_caseworkerbusinessrole cwbr3
                        ON cwbr3.col_tbl_ppl_businessrole = mwbbr3.col_map_wb_wr_businessrole
                     INNER JOIN vw_ppl_activecaseworkersusers cwu3
                        ON cwu3.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu3.id = cwbr3.col_br_ppl_caseworker
                    UNION
                    SELECT wbs.id AS workbasket, cwu3.Id AS Id, cwu3.accode AS accode
                      FROM vw_PPL_SimpleWorkbasket wbs
                     INNER JOIN tbl_map_workbasketbusnessrole mwbbr3
                        ON mwbbr3.col_map_wb_wr_businessrole = wbs.BusinessRole_Id
                     INNER JOIN tbl_caseworkerbusinessrole cwbr3
                        ON cwbr3.col_tbl_ppl_businessrole = wbs.BusinessRole_Id
                     INNER JOIN vw_ppl_activecaseworkersusers cwu3
                        ON cwu3.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu3.id = cwbr3.col_br_ppl_caseworker
                    UNION
                    SELECT mwbtm4.col_map_wb_tm_workbasket AS workbasket, cwu4.id AS Id, cwu4.accode AS accode
                      FROM tbl_map_workbasketteam mwbtm4
                     INNER JOIN tbl_caseworkerteam cwtm4
                        ON cwtm4.col_tbl_ppl_team = mwbtm4.col_map_wb_tm_team
                     INNER JOIN vw_ppl_activecaseworkersusers cwu4
                        ON cwu4.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu4.id = cwtm4.col_tm_ppl_caseworker
                    UNION
                    SELECT wbs.id AS workbasket, cwu4.id AS Id, cwu4.accode AS accode
                      FROM vw_PPL_SimpleWorkbasket wbs
                     INNER JOIN tbl_map_workbasketteam mwbtm4
                        ON mwbtm4.col_map_wb_tm_team = wbs.Team_Id
                     INNER JOIN tbl_caseworkerteam cwtm4
                        ON cwtm4.COL_TBL_PPL_TEAM = wbs.Team_Id
                     INNER JOIN vw_ppl_activecaseworkersusers cwu4
                        ON cwu4.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu4.id = cwtm4.col_tm_ppl_caseworker
                    UNION
                    SELECT mwsk5.col_map_ws_workbasket AS workbasket, cwu5.id AS Id, cwu5.accode AS accode
                      FROM tbl_map_workbasketskill mwsk5
                     INNER JOIN tbl_caseworkerskill cwsk5
                        ON cwsk5.col_tbl_ppl_skill = mwsk5.col_map_ws_skill
                     INNER JOIN vw_ppl_activecaseworkersusers cwu5
                        ON cwu5.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker
                    UNION
                    SELECT wbs.id AS workbasket, cwu5.id AS Id, cwu5.accode AS accode
                      FROM vw_PPL_SimpleWorkbasket wbs
                     INNER JOIN tbl_map_workbasketskill mwsk5
                        ON mwsk5.col_map_ws_skill = wbs.Skill_Id
                     INNER JOIN tbl_caseworkerskill cwsk5
                        ON cwsk5.col_tbl_ppl_skill = wbs.Skill_Id
                     INNER JOIN vw_ppl_activecaseworkersusers cwu5
                        ON cwu5.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker) s1
            ON s1.workbasket = wbs.id
         WHERE Sys_context('CLIENTCONTEXT', 'AccessSubject') IN (cwu0.accode, s1.accode)
           AND (nvl(wi.col_IsDeleted, 0) = 0)) AS ITEMSCOUNT,
       'inbox' AS ICON,
       'DOCINDEXINGSTATES_WAITING_FOR_REVIEW' AS AvailableWIState,
       2 AS SOrder
  FROM dual
UNION
--Trash. All (shared + personal) workbaskets where workitems.IsDeleted = true
SELECT NULL AS Id,
       to_nchar('TRASH') AS code,
       NULL AS CALCNAME,
       to_nchar('Trash') AS DISPLAY_NAME,
       'Home' AS MENU_ITEM,
       (SELECT COUNT(*)
          FROM tbl_pi_workitem wi
         INNER JOIN vw_PPL_SimpleWorkbasket wbs
            ON wi.COL_PI_WORKITEMPPL_WORKBASKET = wbs.id
         INNER JOIN tbl_DICT_State st
            ON st.col_id = (SELECT StateId FROM stateId)
           AND st.col_id = wi.col_pi_workitemdict_state
           AND st.col_StateStateConfig IN (SELECT StateConfigId FROM stateConfig)
        --Personal workbaskets many to one CaseWorker (should be only one)
          LEFT JOIN vw_ppl_activecaseworkersusers cwu0
            ON cwu0.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
           AND wbs.CASEWORKER_ID = cwu0.id
        --user linked to workbasket via Workbasket Many to many CaseWorker
          LEFT JOIN (SELECT mwbcw1.col_map_wb_cw_workbasket AS workbasket, cwu1.id AS Id, cwu1.accode AS accode
                      FROM tbl_map_workbasketcaseworker mwbcw1
                     INNER JOIN vw_ppl_activecaseworkersusers cwu1
                        ON cwu1.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu1.id = mwbcw1.col_map_wb_cw_caseworker
                    UNION
                    SELECT mwbbr3.col_map_wb_br_workbasket AS workbasket, cwu3.Id AS Id, cwu3.accode AS accode
                      FROM tbl_map_workbasketbusnessrole mwbbr3
                     INNER JOIN tbl_caseworkerbusinessrole cwbr3
                        ON cwbr3.col_tbl_ppl_businessrole = mwbbr3.col_map_wb_wr_businessrole
                     INNER JOIN vw_ppl_activecaseworkersusers cwu3
                        ON cwu3.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu3.id = cwbr3.col_br_ppl_caseworker
                    UNION
                    SELECT wbs.id AS workbasket, cwu3.Id AS Id, cwu3.accode AS accode
                      FROM vw_PPL_SimpleWorkbasket wbs
                     INNER JOIN tbl_map_workbasketbusnessrole mwbbr3
                        ON mwbbr3.col_map_wb_wr_businessrole = wbs.BusinessRole_Id
                     INNER JOIN tbl_caseworkerbusinessrole cwbr3
                        ON cwbr3.col_tbl_ppl_businessrole = wbs.BusinessRole_Id
                     INNER JOIN vw_ppl_activecaseworkersusers cwu3
                        ON cwu3.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu3.id = cwbr3.col_br_ppl_caseworker
                    UNION
                    SELECT mwbtm4.col_map_wb_tm_workbasket AS workbasket, cwu4.id AS Id, cwu4.accode AS accode
                      FROM tbl_map_workbasketteam mwbtm4
                     INNER JOIN tbl_caseworkerteam cwtm4
                        ON cwtm4.col_tbl_ppl_team = mwbtm4.col_map_wb_tm_team
                     INNER JOIN vw_ppl_activecaseworkersusers cwu4
                        ON cwu4.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu4.id = cwtm4.col_tm_ppl_caseworker
                    UNION
                    SELECT wbs.id AS workbasket, cwu4.id AS Id, cwu4.accode AS accode
                      FROM vw_PPL_SimpleWorkbasket wbs
                     INNER JOIN tbl_map_workbasketteam mwbtm4
                        ON mwbtm4.col_map_wb_tm_team = wbs.Team_Id
                     INNER JOIN tbl_caseworkerteam cwtm4
                        ON cwtm4.COL_TBL_PPL_TEAM = wbs.Team_Id
                     INNER JOIN vw_ppl_activecaseworkersusers cwu4
                        ON cwu4.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu4.id = cwtm4.col_tm_ppl_caseworker
                    UNION
                    SELECT mwsk5.col_map_ws_workbasket AS workbasket, cwu5.id AS Id, cwu5.accode AS accode
                      FROM tbl_map_workbasketskill mwsk5
                     INNER JOIN tbl_caseworkerskill cwsk5
                        ON cwsk5.col_tbl_ppl_skill = mwsk5.col_map_ws_skill
                     INNER JOIN vw_ppl_activecaseworkersusers cwu5
                        ON cwu5.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker
                    UNION
                    SELECT wbs.id AS workbasket, cwu5.id AS Id, cwu5.accode AS accode
                      FROM vw_PPL_SimpleWorkbasket wbs
                     INNER JOIN tbl_map_workbasketskill mwsk5
                        ON mwsk5.col_map_ws_skill = wbs.Skill_Id
                     INNER JOIN tbl_caseworkerskill cwsk5
                        ON cwsk5.col_tbl_ppl_skill = wbs.Skill_Id
                     INNER JOIN vw_ppl_activecaseworkersusers cwu5
                        ON cwu5.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker) s1
            ON s1.workbasket = wbs.id
         WHERE Sys_context('CLIENTCONTEXT', 'AccessSubject') IN (cwu0.accode, s1.accode)
           AND (wi.cOL_IsDeleted = 1)) AS ITEMSCOUNT,
       'trash' AS ICON,
       'DOCINDEXINGSTATES_WAITING_FOR_REVIEW' AS AvailableWIState,
       3 AS SOrder
  FROM dual
UNION
--All Shared
SELECT NULL AS Id,
       to_nchar('ALL_SHARED') AS code,
       NULL AS CALCNAME,
       to_nchar('All Shared (work baskets)') AS DISPLAY_NAME,
       'Shared Work Baskets' AS MENU_ITEM,
       (SELECT COUNT(*)
          FROM tbl_pi_workitem wi
         INNER JOIN vw_PPL_SimpleWorkbasket wbs
            ON wi.COL_PI_WORKITEMPPL_WORKBASKET = wbs.id
         INNER JOIN tbl_DICT_State st
            ON st.col_id = (SELECT StateId FROM stateId)
           AND st.col_id = wi.col_pi_workitemdict_state
        --user linked to workbasket via Workbasket Many to many CaseWorker
          LEFT JOIN (SELECT mwbcw1.col_map_wb_cw_workbasket AS workbasket, cwu1.id AS Id, cwu1.accode AS accode
                      FROM tbl_map_workbasketcaseworker mwbcw1
                     INNER JOIN vw_ppl_activecaseworkersusers cwu1
                        ON cwu1.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu1.id = mwbcw1.col_map_wb_cw_caseworker
                    UNION
                    SELECT mwbbr3.col_map_wb_br_workbasket AS workbasket, cwu3.Id AS Id, cwu3.accode AS accode
                      FROM tbl_map_workbasketbusnessrole mwbbr3
                     INNER JOIN tbl_caseworkerbusinessrole cwbr3
                        ON cwbr3.col_tbl_ppl_businessrole = mwbbr3.col_map_wb_wr_businessrole
                     INNER JOIN vw_ppl_activecaseworkersusers cwu3
                        ON cwu3.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu3.id = cwbr3.col_br_ppl_caseworker
                    UNION
                    SELECT wbs.id AS workbasket, cwu3.Id AS Id, cwu3.accode AS accode
                      FROM vw_PPL_SimpleWorkbasket wbs
                     INNER JOIN tbl_map_workbasketbusnessrole mwbbr3
                        ON mwbbr3.col_map_wb_wr_businessrole = wbs.BusinessRole_Id
                     INNER JOIN tbl_caseworkerbusinessrole cwbr3
                        ON cwbr3.col_tbl_ppl_businessrole = wbs.BusinessRole_Id
                     INNER JOIN vw_ppl_activecaseworkersusers cwu3
                        ON cwu3.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu3.id = cwbr3.col_br_ppl_caseworker
                    UNION
                    SELECT mwbtm4.col_map_wb_tm_workbasket AS workbasket, cwu4.id AS Id, cwu4.accode AS accode
                      FROM tbl_map_workbasketteam mwbtm4
                     INNER JOIN tbl_caseworkerteam cwtm4
                        ON cwtm4.col_tbl_ppl_team = mwbtm4.col_map_wb_tm_team
                     INNER JOIN vw_ppl_activecaseworkersusers cwu4
                        ON cwu4.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu4.id = cwtm4.col_tm_ppl_caseworker
                    UNION
                    SELECT wbs.id AS workbasket, cwu4.id AS Id, cwu4.accode AS accode
                      FROM vw_PPL_SimpleWorkbasket wbs
                     INNER JOIN tbl_map_workbasketteam mwbtm4
                        ON mwbtm4.col_map_wb_tm_team = wbs.Team_Id
                     INNER JOIN tbl_caseworkerteam cwtm4
                        ON cwtm4.COL_TBL_PPL_TEAM = wbs.Team_Id
                     INNER JOIN vw_ppl_activecaseworkersusers cwu4
                        ON cwu4.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu4.id = cwtm4.col_tm_ppl_caseworker
                    UNION
                    SELECT mwsk5.col_map_ws_workbasket AS workbasket, cwu5.id AS Id, cwu5.accode AS accode
                      FROM tbl_map_workbasketskill mwsk5
                     INNER JOIN tbl_caseworkerskill cwsk5
                        ON cwsk5.col_tbl_ppl_skill = mwsk5.col_map_ws_skill
                     INNER JOIN vw_ppl_activecaseworkersusers cwu5
                        ON cwu5.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker
                    UNION
                    SELECT wbs.id AS workbasket, cwu5.id AS Id, cwu5.accode AS accode
                      FROM vw_PPL_SimpleWorkbasket wbs
                     INNER JOIN tbl_map_workbasketskill mwsk5
                        ON mwsk5.col_map_ws_skill = wbs.Skill_Id
                     INNER JOIN tbl_caseworkerskill cwsk5
                        ON cwsk5.col_tbl_ppl_skill = wbs.Skill_Id
                     INNER JOIN vw_ppl_activecaseworkersusers cwu5
                        ON cwu5.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                       AND cwu5.col_id = cwsk5.col_sk_ppl_caseworker) s1
            ON s1.workbasket = wbs.id
         WHERE Sys_context('CLIENTCONTEXT', 'AccessSubject') IN (s1.accode)
           AND (nvl(wi.col_IsDeleted, 0) = 0)) AS ITEMSCOUNT,
       'inbox' AS ICON,
       'DOCINDEXINGSTATES_WAITING_FOR_REVIEW' AS AvailableWIState,
       4 AS SOrder
  FROM dual
UNION
SELECT s1.*, rownum + 4 AS SOrder
  FROM (SELECT s.*
          FROM (
                --Workbaskets where user participates via Workbasket to Caseworker map
                SELECT wbs.id,
                        wbs.code,
                        wbs.CALCNAME,
                        wbs.Name AS DISPLAY_NAME,
                        'Shared Work Baskets' AS MENU_ITEM,
                        (SELECT COUNT(*)
                           FROM tbl_pi_workitem wi
                          INNER JOIN vw_PPL_SimpleWorkbasket w
                             ON wi.COL_PI_WORKITEMPPL_WORKBASKET = w.id
                          INNER JOIN tbl_DICT_State st
                             ON st.col_id = wi.col_pi_workitemdict_state
                            AND st.col_StateStateConfig IN (SELECT StateConfigId FROM stateConfig)
                            AND st.col_id = (SELECT StateId FROM stateId)
                          WHERE w.id = wbs.id
                            AND (nvl(wi.col_IsDeleted, 0) = 0)) AS ITEMSCOUNT,
                        'inbox' AS ICON,
                        'DOCINDEXINGSTATES_WAITING_FOR_REVIEW' AS AvailableWIState
                  FROM vw_PPL_SimpleWorkbasket wbs
                 INNER JOIN tbl_map_workbasketcaseworker mwbcw1
                    ON mwbcw1.col_map_wb_cw_workbasket = wbs.id
                 INNER JOIN vw_ppl_activecaseworkersusers cwu1
                    ON cwu1.id = mwbcw1.col_map_wb_cw_caseworker
                 WHERE cwu1.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                   AND wbs.workbaskettype_code = 'GROUP'
                UNION
                --Workbaskets where user participates via Business Roles to Caseworkers map
                SELECT wbs.id,
                        wbs.code,
                        wbs.CALCNAME,
                        wbs.Name AS DISPLAY_NAME,
                        'Shared Work Baskets' AS MENU_ITEM,
                        (SELECT COUNT(*)
                           FROM tbl_pi_workitem wi
                          INNER JOIN vw_PPL_SimpleWorkbasket w
                             ON wi.COL_PI_WORKITEMPPL_WORKBASKET = w.id
                          INNER JOIN tbl_DICT_State st
                             ON st.col_id = wi.col_pi_workitemdict_state
                            AND st.col_StateStateConfig IN (SELECT StateConfigId FROM stateConfig)
                            AND st.col_id = (SELECT StateId FROM stateId)
                          WHERE w.id = wbs.id
                            AND (nvl(wi.col_IsDeleted, 0) = 0)) AS ITEMSCOUNT,
                        'inbox' AS ICON,
                        'DOCINDEXINGSTATES_WAITING_FOR_REVIEW' AS AvailableWIState
                  FROM vw_PPL_SimpleWorkbasket wbs
                 INNER JOIN tbl_map_workbasketbusnessrole mwbbr3
                    ON mwbbr3.col_map_wb_wr_businessrole = wbs.BusinessRole_Id
                 INNER JOIN tbl_caseworkerbusinessrole cwbr2
                    ON cwbr2.col_tbl_ppl_businessrole = wbs.BusinessRole_Id
                 INNER JOIN vw_ppl_activecaseworkersusers cwu2
                    ON cwu2.id = cwbr2.col_br_ppl_caseworker
                 WHERE cwu2.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                UNION
                --Workbaskets where user participates via Team to Caseworkers map
                SELECT wbs.id,
                        wbs.code,
                        wbs.CALCNAME,
                        wbs.Name AS DISPLAY_NAME,
                        'Shared Work Baskets' AS MENU_ITEM,
                        (SELECT COUNT(*)
                           FROM tbl_pi_workitem wi
                          INNER JOIN vw_PPL_SimpleWorkbasket w
                             ON wi.COL_PI_WORKITEMPPL_WORKBASKET = w.id
                          INNER JOIN tbl_DICT_State st
                             ON st.col_id = wi.col_pi_workitemdict_state
                            AND st.col_StateStateConfig IN (SELECT StateConfigId FROM stateConfig)
                            AND st.col_id = (SELECT StateId FROM stateId)
                          WHERE w.id = wbs.id
                            AND (wi.col_IsDeleted IS NULL OR wi.col_IsDeleted = 0)) AS ITEMSCOUNT,
                        'inbox' AS ICON,
                        'DOCINDEXINGSTATES_WAITING_FOR_REVIEW' AS AvailableWIState
                  FROM vw_PPL_SimpleWorkbasket wbs
                 INNER JOIN tbl_map_workbasketteam mwbtm4
                    ON mwbtm4.col_map_wb_tm_team = wbs.Team_Id
                 INNER JOIN tbl_caseworkerteam cwtm4
                    ON cwtm4.COL_TBL_PPL_TEAM = wbs.Team_Id
                 INNER JOIN vw_ppl_activecaseworkersusers cwu4
                    ON cwu4.id = cwtm4.col_tm_ppl_caseworker
                 WHERE cwu4.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                UNION
                --Workbaskets where user participates via Skill to Caseworkers map
                SELECT wbs.id,
                        wbs.code,
                        wbs.CALCNAME,
                        wbs.Name AS DISPLAY_NAME,
                        'Shared Work Baskets' AS MENU_ITEM,
                        (SELECT COUNT(*)
                           FROM tbl_pi_workitem wi
                          INNER JOIN vw_PPL_SimpleWorkbasket w
                             ON wi.COL_PI_WORKITEMPPL_WORKBASKET = w.id
                          INNER JOIN tbl_DICT_State st
                             ON st.col_id = wi.col_pi_workitemdict_state
                            AND st.col_StateStateConfig IN (SELECT StateConfigId FROM stateConfig)
                            AND st.col_id = (SELECT StateId FROM stateId)
                          WHERE w.id = wbs.id
                            AND (wi.col_IsDeleted IS NULL OR wi.col_IsDeleted = 0)) AS ITEMSCOUNT,
                        'inbox' AS ICON,
                        'DOCINDEXINGSTATES_WAITING_FOR_REVIEW' AS AvailableWIState
                  FROM vw_PPL_SimpleWorkbasket wbs
                 INNER JOIN tbl_map_workbasketskill mwbsk5
                    ON mwbsk5.col_map_ws_skill = wbs.Skill_Id
                 INNER JOIN tbl_caseworkerskill cws5
                    ON cws5.col_tbl_ppl_skill = wbs.Skill_Id
                 INNER JOIN vw_ppl_activecaseworkersusers cwu5
                    ON cws5.COL_sk_PPL_CASEWORKER = cwu5.ID
                 WHERE cwu5.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')) s
         ORDER BY UPPER(s.DISPLAY_NAME)) s1
 ORDER BY SOrder