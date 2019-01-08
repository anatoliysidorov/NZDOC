declare
  v_input xmltype;
  v_result number;
  v_cur sys_refcursor;
  v_name nvarchar2(255);
  v_businessrole number;
  v_skill number;
  v_team number;
begin
  if :Input is null then
    v_input := XMLType('<CustomData><Attributes></Attributes></CustomData>');
  else
    v_input := XMLType(:Input);
  end if;
  v_name := f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name');
  v_businessrole := to_number(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'BusinessRole'));
  v_skill := to_number(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Skill'));
  v_team := to_number(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Team'));
  open v_cur for
SELECT 
        s2.workbasket_id        AS Id,
        s2.CaseWorker_Id        AS CaseWorker_Id,
        s2.CaseWorker_Name      AS CaseWorker_Name,
        s2.CaseWorker_Email     AS CaseWorker_Email,
        s2.CaseWorker_Photo     AS CaseWorker_Photo,
        s2.workbasket_id        AS workbasket_id,
        s2.WorkBasket_Code      AS WorkBasket_Code,
        s2.WorkBasket_Name      AS WorkBasket_Name,
        wbt.col_Code            AS WorkBasketType_Code,
        s2.ParticipantType      AS ParticipantType,
        s2.businessroles        AS BusinessRoles,
		s2.skills               AS Skills,
        s2.teams                AS Teams,
        s2.businessroleids      AS BusinessRoleIds,
        s2.skillids             AS SkillIds,
        s2.teamids              AS TeamIds,
        CASE
            WHEN lower(wbt.col_Code)='group' THEN s2.WorkBasket_Name
            WHEN lower(wbt.col_Code)='personal' THEN s2.CaseWorker_Name
        END as CalculatedName
FROM   (SELECT 
               s1.Participant_Id       AS Participant_Id,
               s1.Name                 AS Name,
               s1.Description          AS Description,
               s1.Required             AS Required,
               s1.BusinessRole_Id      AS BusinessRole_Id,
               s1.BusinessRole_Name    AS BusinessRole_Name,
               s1.CaseWorker_Id        AS CaseWorker_Id,
               s1.CaseWorker_Name      AS CaseWorker_Name,
               s1.CaseWorker_Email     AS CaseWorker_Email,
               s1.CaseWorker_Photo     AS CaseWorker_Photo,
               s1.PartyType_Id         AS PartyType_Id,
               s1.PartyType_Name       AS PartyType_Name,
               s1.PartyType_Code       AS PartyType_Code,
               s1.ParticipantType_Id   AS ParticipantType_Id,
               s1.ParticipantType_Code AS ParticipantType_Code,
               s1.ParticipantType_Name AS ParticipantType_Name,
               s1.casesystypecode      AS CaseSysTypeCode,
               s1.casesystypename      AS CaseSysTypeName,
               s1.TaskSysType_Id       AS TaskSysType_Id,
               s1.TaskSysType_Code     AS TaskSysType_Code,
               s1.TaskSysType_Name     AS TaskSysType_Name,
               s1.caseworkername       AS CaseWorkerName,
               s1.username             AS UserName,
               s1.workbasket_id         AS workbasket_id,
               s1.WorkBasket_Code       AS WorkBasket_Code,
               s1.WorkBasket_Name       AS WorkBasket_Name,
			   s1.workbasketType_Id         AS workbasketType_Id,
               s1.isowner              AS IsOwner,
               s1.TypeGrouping         AS TypeGrouping,
               s1.ParticipantType      AS ParticipantType,
               s1.TypeGrouping_Class   AS TypeGrouping_Class,
               s1.businessroles        AS BusinessRoles,
               s1.skills               AS Skills,
               s1.teams                AS Teams,
               s1.businessroleids      AS BusinessRoleIds,
               s1.skillids             AS SkillIds,
               s1.teamids              AS TeamIds
        FROM   (SELECT 
                       prtc.col_id                                   AS Participant_Id,
                       prtc.col_name                                 AS Name,
                       cast(prtc.col_description AS NVARCHAR2(2000)) AS Description,
                       prtc.col_required                             AS Required,
                       pbr.col_id                                    AS BusinessRole_Id,
                       pbr.col_name                                  AS BusinessRole_Name,
                       pcw.col_id                                    AS CaseWorker_Id,
                       au.name                                       AS CaseWorker_Name,
                       au.email                                      AS CaseWorker_Email,
                       au.photo                                      AS CaseWorker_Photo,
                       pt.col_id                                     AS PartyType_Id,
                       pt.col_name                                   AS PartyType_Name,
                       pt.col_code                                   AS PartyType_Code,
                       ptt.col_id                                    AS ParticipantType_Id,
                       ptt.col_code                                  AS ParticipantType_Code,
                       ptt.col_name                                  AS ParticipantType_Name,
                       dtst.col_id                                   AS TaskSysType_Id,
                       dcst.col_code                                 AS CaseSysTypeCode, 
                       dcst.col_name                                 AS CaseSysTypeName, 
                       dtst.col_code                                 AS TaskSysType_Code, 
                       dtst.col_name                                 AS TaskSysType_Name, 
                       pcw.col_name                                  AS CaseWorkerName,
                       pcwu.name                                     AS UserName,
                       pwb.col_id                                    AS workbasket_id,
                       pwb.col_code                                  AS WorkBasket_Code,
                       pwb.col_name                                  AS WorkBasket_Name,
					   pwb.col_WORKBASKETWORKBASKETTYPE              AS workbasketType_Id,
                       prtc.col_isowner                              AS IsOwner,
                       NVL(dtst.col_name, 'Case Ownership')          AS TypeGrouping,
                       'BusinessRole'                                AS ParticipantType,
                       CASE
                         WHEN dtst.col_id IS NOT NULL THEN 'TASKSYSTYPE'
                         ELSE 'CASESYSTYPE'
                       END                                           AS TypeGrouping_Class,
                       --LiSTAGG(pbr2.col_name, ',') WITHIN GROUP (ORDER BY NULL)  AS BusinessRoles,
                       list_collect(cast(collect(to_char(pbr2.col_name) order by to_char(pbr2.col_name)) as split_tbl),',',1) as BusinessRoles, 
                       list_collect(cast(collect(to_char(sk2.col_name) order by to_char(sk2.col_name)) as split_tbl),',',1)  AS Skills,
                       list_collect(cast(collect(to_char(t2.col_name) order by to_char(t2.col_name)) as split_tbl),',',1)  AS Teams,
                       list_collect(cast(collect(to_char(pbr2.col_id) order by to_char(pbr2.col_name)) as split_tbl),',',1) as BusinessRoleIds, 
					   list_collect(cast(collect(to_char(sk2.col_id) order by to_char(sk2.col_name)) as split_tbl),',',1)  AS SkillIds,
                       list_collect(cast(collect(to_char(t2.col_id) order by to_char(t2.col_name)) as split_tbl),',',1) as TeamIds
                FROM   tbl_dict_tasksystype dtst
                       inner join tbl_case cs
                               ON cs.col_id = :Case_Id
                       inner join tbl_dict_casesystype dcst
                               ON cs.col_casedict_casesystype = dcst.col_id
                       inner join tbl_participant prtc
                               ON dtst.col_id = prtc.col_participanttasksystype
                                  AND dcst.col_id = prtc.col_participantcasesystype
                       left  join tbl_dict_partytype pt ON prtc.col_participantdict_partytype = pt.col_id
                       left  join tbl_dict_participanttype ptt ON pt.col_partytypeparticiptype = ptt.col_id
                       inner join tbl_ppl_businessrole pbr
                               ON prtc.col_participantbusinessrole = pbr.col_id
                       inner join tbl_caseworkerbusinessrole cwbr
                               ON pbr.col_id = cwbr.col_tbl_ppl_businessrole
                       inner join vw_ppl_activecaseworker pcw
                               ON cwbr.col_br_ppl_caseworker = pcw.col_id
                       left  join vw_users au ON pcw.col_userid = au.userid
                       inner join tbl_ppl_workbasket pwb
                               ON pcw.col_id = pwb.col_caseworkerworkbasket
                       inner join tbl_caseworkerbusinessrole cwbr2
                               ON pcw.col_id = cwbr2.col_br_ppl_caseworker
                       inner join tbl_ppl_businessrole pbr2
                               ON cwbr2.col_tbl_ppl_businessrole = pbr2.col_id
                       left join tbl_caseworkerskill cwsk2
                       		   ON pcw.col_id = cwsk2.col_sk_ppl_caseworker
                       left join tbl_ppl_skill sk2
                       		   ON cwsk2.col_tbl_ppl_skill = sk2.col_id
                       left join tbl_caseworkerteam cwt2
                       		   ON pcw.col_id = cwt2.col_tm_ppl_caseworker
                       left join tbl_ppl_team t2
                       		   ON cwt2.col_tbl_ppl_team = t2.col_id
                       inner join vw_ppl_activecaseworkersusers pcwu
                               ON pcw.col_id = pcwu.id
                --FILTER BY TASK ID
                WHERE  dtst.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'TaskSysType_Id') 
						AND pwb.col_IsPrivate = 0	
						--TO DO - ADD SEARCH BY SKILL, TEAM, OR BUSINESS ROLE
                GROUP  BY 
                          prtc.col_id,
                          prtc.col_name,
                          cast (prtc.col_description AS NVARCHAR2(2000)),
                          prtc.col_required,
                          pbr.col_id,
                          pbr.col_name,
                          pcw.col_id,
                          au.name,
                          au.email,
                          au.photo,
                          pt.col_id,
                          pt.col_name,
                          pt.col_code,
                          ptt.col_id,
                          ptt.col_code,
                          ptt.col_name,
                          dtst.col_id,
                          dcst.col_code,
                          dcst.col_name,
                          dtst.col_code,
                          dtst.col_name,
                          pcw.col_name,
                          pcwu.name,
						  pwb.col_id,
                          pwb.col_code,
                          pwb.col_name,
						  pwb.COL_WORKBASKETWORKBASKETTYPE,
                          prtc.col_isowner,
                          NVL(dtst.col_name, 'Case Ownership'),
                          'BusinessRole',
                          CASE
                            WHEN dtst.col_id IS NOT NULL THEN 'TASKSYSTYPE'
                            ELSE 'CASESYSTYPE'
                          END
                UNION 
                SELECT 
                       prtc.col_id                                   AS Participant_Id,
                       prtc.col_name                                 AS Name,
                       cast(prtc.col_description AS NVARCHAR2(2000)) AS Description,
                       prtc.col_required                             AS Required,
                       pbr.col_id                                    AS BusinessRole_Id,
                       pbr.col_name                                  AS BusinessRole_Name,
                       pcw.col_id                                    AS CaseWorker_Id,
                       au.name                                       AS CaseWorker_Name,
                       au.email                                      AS CaseWorker_Email,
                       au.photo                                      AS CaseWorker_Photo,
                       pt.col_id                                     AS PartyType_Id,
                       pt.col_name                                   AS PartyType_Name,
                       pt.col_code                                   AS PartyType_Code,
                       ptt.col_id                                    AS ParticipantType_Id,
                       ptt.col_code                                  AS ParticipantType_Code,
                       ptt.col_name                                  AS ParticipantType_Name,
                       dtst.col_id                                   AS TaskSysType_Id,
                       dcst.col_code                                 AS CaseSysTypeCode,
                       dcst.col_name                                 AS CaseSysTypeName,
                       dtst.col_code                                 AS TaskSysType_Code,
                       dtst.col_name                                 AS TaskSysType_Name,
                       pcw.col_name                                  AS CaseWorkerName,
                       pcwu.name                                     AS UserName,
                       pwb.col_id                                    AS workbasket_id,
                       pwb.col_code                                  AS WorkBasket_Code,
                       pwb.col_name                                  AS WorkBasket_Name,
					   pwb.col_WORKBASKETWORKBASKETTYPE         		AS workbasketType_Id,
                       prtc.col_isowner                              AS IsOwner,
                       NVL(dtst.col_name, 'Case Ownership')          AS TypeGrouping,
                       'BusinessRole'                                AS ParticipantType,
                       CASE
                         WHEN dtst.col_id IS NOT NULL THEN 'TASKSYSTYPE'
                         ELSE 'CASESYSTYPE'
                       END                                           AS TypeGrouping_Class,
                       list_collect(cast(collect(to_char(pbr.col_name) order by to_char(pbr.col_name)) as split_tbl),',',1) as BusinessRoles, 
                       list_collect(cast(collect(to_char(sk2.col_name) order by to_char(sk2.col_name)) as split_tbl),',',1)  AS Skills,
                       list_collect(cast(collect(to_char(t2.col_name) order by to_char(t2.col_name)) as split_tbl),',',1)  AS Teams,
                       list_collect(cast(collect(to_char(pbr.col_id) order by to_char(pbr.col_name)) as split_tbl),',',1) as BusinessRoleIds, 
					   list_collect(cast(collect(to_char(sk2.col_id) order by to_char(sk2.col_name)) as split_tbl),',',1)  AS SkillIds,
                       list_collect(cast(collect(to_char(t2.col_id) order by to_char(t2.col_name)) as split_tbl),',',1) as TeamIds
                FROM   tbl_dict_tasksystype dtst
                       inner join tbl_case cs
                               ON cs.col_id = :Case_Id
                       inner join tbl_dict_casesystype dcst
                               ON cs.col_casedict_casesystype = dcst.col_id
                       inner join tbl_participant prtc
                               ON dtst.col_id = prtc.col_participanttasksystype
                                  AND dcst.col_id = prtc.col_participantcasesystype
                       left  join tbl_dict_partytype pt ON prtc.col_participantdict_partytype = pt.col_id
                       left  join tbl_dict_participanttype ptt ON pt.col_partytypeparticiptype = ptt.col_id
                       inner join vw_ppl_activecaseworker pcw
                               ON prtc.col_participantppl_caseworker = pcw.col_id
                       left  join vw_users au ON pcw.col_userid = au.userid
                       inner join tbl_ppl_workbasket pwb
                               ON pcw.col_id = pwb.col_caseworkerworkbasket
                       left join tbl_caseworkerbusinessrole cwbr
                              ON pcw.col_id = cwbr.col_br_ppl_caseworker
                       left join tbl_ppl_businessrole pbr
                              ON cwbr.col_tbl_ppl_businessrole = pbr.col_id
                       left join tbl_caseworkerskill cwsk2
                       		   ON pcw.col_id = cwsk2.col_sk_ppl_caseworker
                       left join tbl_ppl_skill sk2
                       		   ON cwsk2.col_tbl_ppl_skill = sk2.col_id
                       left join tbl_caseworkerteam cwt2
                       		   ON pcw.col_id = cwt2.col_tm_ppl_caseworker
                       left join tbl_ppl_team t2
                       		   ON cwt2.col_tbl_ppl_team = t2.col_id
                       inner join vw_ppl_activecaseworkersusers pcwu
                               ON pcw.col_id = pcwu.id
                --FILTER BY TASK ID
                WHERE  	dtst.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'TaskSysType_Id')
						AND pwb.col_IsPrivate = 0
						
						--TO DO - ADD SEARCH BY SKILL, TEAM, OR BUSINESS ROLE
                GROUP  BY 
                          prtc.col_id,
                          prtc.col_name,
                          cast (prtc.col_description AS NVARCHAR2(2000)),
                          prtc.col_required,
                          pbr.col_id,
                          pbr.col_name,
                          pcw.col_id,
                          au.name,
                          au.email,
                          au.photo,
                          pt.col_id,
                          pt.col_name,
                          pt.col_code,
                          ptt.col_id,
                          ptt.col_code,
                          ptt.col_name,
                          dtst.col_id,
                          dcst.col_code,
                          dcst.col_name,
                          dtst.col_code,
                          dtst.col_name,
                          pcw.col_name,
                          pcwu.name,
                          pwb.col_id,
                          pwb.col_code,
                          pwb.col_name,
						  pwb.COL_WORKBASKETWORKBASKETTYPE,
                          prtc.col_isowner,
                          NVL(dtst.col_name, 'Case Ownership'),
                          'BusinessRole',
                          CASE
                            WHEN dtst.col_id IS NOT NULL THEN 'TASKSYSTYPE'
                            ELSE 'CASESYSTYPE'
                          END
                UNION
                SELECT
                       prtc.col_id                                   AS Participant_Id,
                       prtc.col_name                                 AS Name,
                       cast(prtc.col_description AS NVARCHAR2(2000)) AS Description,
                       prtc.col_required                             AS Required,
                       pbr.col_id                                    AS BusinessRole_Id,
                       pbr.col_name                                  AS BusinessRole_Name,
                       pcw.col_id                                    AS CaseWorker_Id,
                       au.name                                       AS CaseWorker_Name,
                       au.email                                      AS CaseWorker_Email,
                       au.photo                                      AS CaseWorker_Photo,
                       pt.col_id                                     AS PartyType_Id,
                       pt.col_name                                   AS PartyType_Name,
                       pt.col_code                                   AS PartyType_Code,
                       ptt.col_id                                    AS ParticipantType_Id,
                       ptt.col_code                                  AS ParticipantType_Code,
                       ptt.col_name                                  AS ParticipantType_Name,
                       dtst.col_id                                   AS TaskSysType_Id,
                       dcst.col_code                                 AS CaseSysTypeCode, 
                       dcst.col_name                                 AS CaseSysTypeName, 
                       dtst.col_code                                 AS TaskSysType_Code, 
                       dtst.col_name                                 AS TaskSysType_Name, 
                       pcw.col_name                                  AS CaseWorkerName,
                       pcwu.name                                     AS UserName,
                       pwb.col_id                                    AS workbasket_id,
                       pwb.col_code                                  AS WorkBasket_Code,
                       pwb.col_name                                  AS WorkBasket_Name,
					   pwb.col_WORKBASKETWORKBASKETTYPE         		AS workbasketType_Id,
                       prtc.col_isowner                              AS IsOwner,
                       NVL(dtst.col_name, 'Case Ownership')          AS TypeGrouping,
                       'Team'                                AS ParticipantType,
                       CASE
                         WHEN dtst.col_id IS NOT NULL THEN 'TASKSYSTYPE'
                         ELSE 'CASESYSTYPE'
                       END                                           AS TypeGrouping_Class,
                       --LiSTAGG(pbr2.col_name, ',') WITHIN GROUP (ORDER BY NULL)  AS BusinessRoles,
                       list_collect(cast(collect(to_char(pbr2.col_name) order by to_char(pbr2.col_name)) as split_tbl),',',1) as BusinessRoles, 
                       list_collect(cast(collect(to_char(sk2.col_name) order by to_char(sk2.col_name)) as split_tbl),',',1)  AS Skills,
                       list_collect(cast(collect(to_char(t2.col_name) order by to_char(t2.col_name)) as split_tbl),',',1)  AS Teams,
                       list_collect(cast(collect(to_char(pbr2.col_id) order by to_char(pbr2.col_name)) as split_tbl),',',1) as BusinessRoleIds, 
					   list_collect(cast(collect(to_char(sk2.col_id) order by to_char(sk2.col_name)) as split_tbl),',',1)  AS SkillIds,
                       list_collect(cast(collect(to_char(t2.col_id) order by to_char(t2.col_name)) as split_tbl),',',1) as TeamIds
                FROM   tbl_dict_tasksystype dtst
                       inner join tbl_case cs
                               ON cs.col_id = :Case_Id
                       inner join tbl_dict_casesystype dcst
                               ON cs.col_casedict_casesystype = dcst.col_id
                       inner join tbl_participant prtc
                               ON dtst.col_id = prtc.col_participanttasksystype
                                  AND dcst.col_id = prtc.col_participantcasesystype
                       left  join tbl_dict_partytype pt ON prtc.col_participantdict_partytype = pt.col_id
                       left  join tbl_dict_participanttype ptt ON pt.col_partytypeparticiptype = ptt.col_id
                       inner join tbl_ppl_team pbr
                               ON prtc.col_participantteam = pbr.col_id
                       inner join tbl_caseworkerteam cwbr
                               ON pbr.col_id = cwbr.col_tbl_ppl_team
                       inner join vw_ppl_activecaseworker pcw
                               ON cwbr.col_tm_ppl_caseworker = pcw.col_id
                       left  join vw_users au ON pcw.col_userid = au.userid
                       inner join tbl_ppl_workbasket pwb
                               ON pcw.col_id = pwb.col_caseworkerworkbasket
                       left  join tbl_caseworkerbusinessrole cwbr2
                               ON pcw.col_id = cwbr2.col_br_ppl_caseworker
                       left  join tbl_ppl_businessrole pbr2
                               ON cwbr2.col_tbl_ppl_businessrole = pbr2.col_id
                       left  join tbl_caseworkerskill cwsk2
                       		   ON pcw.col_id = cwsk2.col_sk_ppl_caseworker
                       left  join tbl_ppl_skill sk2
                       		   ON cwsk2.col_tbl_ppl_skill = sk2.col_id
                       left  join tbl_caseworkerteam cwt2
                       		   ON pcw.col_id = cwt2.col_tm_ppl_caseworker
                       left  join tbl_ppl_team t2
                       		   ON cwt2.col_tbl_ppl_team = t2.col_id
                       inner join vw_ppl_activecaseworkersusers pcwu
                               ON pcw.col_id = pcwu.id
                --FILTER BY TASK ID
                WHERE  dtst.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'TaskSysType_Id') 
						AND pwb.col_IsPrivate = 0	
						--TO DO - ADD SEARCH BY SKILL, TEAM, OR BUSINESS ROLE
                GROUP  BY 
                          prtc.col_id,
                          prtc.col_name,
                          cast (prtc.col_description AS NVARCHAR2(2000)),
                          prtc.col_required,
                          pbr.col_id,
                          pbr.col_name,
                          pcw.col_id,
                          au.name,
                          au.email,
                          au.photo,
                          pt.col_id,
                          pt.col_name,
                          pt.col_code,
                          ptt.col_id,
                          ptt.col_code,
                          ptt.col_name,
                          dtst.col_id,
                          dcst.col_code,
                          dcst.col_name,
                          dtst.col_code,
                          dtst.col_name,
                          pcw.col_name,
                          pcwu.name,
						  pwb.col_id,
                          pwb.col_code,
                          pwb.col_name,
						  pwb.COL_WORKBASKETWORKBASKETTYPE,
                          prtc.col_isowner,
                          NVL(dtst.col_name, 'Case Ownership'),
                          'Team',
                          CASE
                            WHEN dtst.col_id IS NOT NULL THEN 'TASKSYSTYPE'
                            ELSE 'CASESYSTYPE'
                          END) s1
        ORDER  BY s1.username) s2
INNER JOIN tbl_DICT_WorkBasketType wbt ON (wbt.col_id = s2.workbasketType_Id)  
WHERE
(v_name IS NULL
	OR (lower(wbt.col_Code)='group' AND lower(s2.WorkBasket_Name) LIKE f_UTIL_toWildcards(v_name))
	OR (lower(wbt.col_Code)='personal' AND lower(s2.CaseWorker_Name) LIKE f_UTIL_toWildcards(v_name))
)
and (v_businessrole is null or v_businessrole in (select to_number(column_value) from table(asf_splitclob(s2.BusinessRoleIds,','))))
and (v_skill is null or v_skill in (select to_number(column_value) from table(asf_splitclob(s2.SkillIds,','))))
and (v_team is null or v_team in (select to_number(column_value) from table(asf_splitclob(s2.TeamIds,','))))
order by CASE
			WHEN lower(wbt.col_Code)='group' THEN s2.WorkBasket_Name
			WHEN lower(wbt.col_Code)='personal' THEN s2.CaseWorker_Name
		END;
    :cur_item := v_cur;
end;