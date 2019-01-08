declare
  v_input xmltype;
  v_result number;
  v_cur sys_refcursor;
begin
  if :Input is null then
    v_input := XMLType('<CustomData><Attributes></Attributes></CustomData>');
  else
    v_input := XMLType(:Input);
  end if;  
  open v_cur for
SELECT ROWNUM                  AS Id,
       s2.Case_Id              AS Case_Id,
       s2.CaseWorker_Id        AS CaseWorker_Id,
       s2.CaseWorker_Name      AS CaseWorker_Name,
       s2.CaseWorker_Email     AS CaseWorker_Email,
       s2.CaseWorker_Photo     AS CaseWorker_Photo,
       s2.casesystypecode      AS CaseSysType_Code,
       s2.casesystypename      AS CaseSysType_Name,
       s2.username             AS UserName,
       s2.workbasketid         AS workbasket_id,
       s2.workbasketcode       AS WorkBasket_Code,
       s2.workbasketname       AS WorkBasket_Name,
       s2.workbaskettype_code  AS WorkBasketType_Code,       
       s2.businessroles        AS BusinessRoles,
       s2.skills               AS Skills,
       s2.teams                AS Teams,
	   CASE
		  WHEN lower(s2.workbaskettype_code)='group' THEN s2.workbasketname
		  WHEN lower(s2.workbaskettype_code)='personal' THEN s2.CaseWorker_Name
		END as CalculatedName
FROM   (SELECT s1.Case_Id      AS Case_Id,
               s1.CaseWorker_Id        AS CaseWorker_Id,
               s1.CaseWorker_Name      AS CaseWorker_Name,
               s1.CaseWorker_Email     AS CaseWorker_Email,
               s1.CaseWorker_Photo     AS CaseWorker_Photo,
               s1.casesystypecode      AS CaseSysTypeCode,
               s1.casesystypename      AS CaseSysTypeName,
               s1.caseworkername       AS CaseWorkerName,
               s1.username             AS UserName,
               s1.workbasketid         AS workbasketid,
               s1.workbasketcode       AS WorkBasketCode,
               s1.workbasketname       AS WorkBasketName,
               s1.workbaskettype_code  AS WorkBasketType_Code,
               s1.businessroles        AS BusinessRoles,
               s1.skills               AS Skills,
               s1.teams                AS Teams
        FROM   (SELECT cs.col_id                                     AS Case_Id,
                       pcw.col_id                                    AS CaseWorker_Id,
                       au.name                                       AS CaseWorker_Name,
                       au.email                                      AS CaseWorker_Email,
                       au.photo                                      AS CaseWorker_Photo,
                       dcst.col_code                                 AS CaseSysTypeCode, 
                       dcst.col_name                                 AS CaseSysTypeName, 
                       pcw.col_name                                  AS CaseWorkerName, 
                       pcwu.name                                     AS UserName, 
                       pwb.col_id                                    AS WorkBasketId,
                       pwb.col_code                                  AS WorkBasketCode,
                       pwb.col_name                                  AS WorkBasketName,
                       pwbt.col_code                                 AS WorkBasketType_Code,
                       list_collect(cast(collect(to_char(pbr2.col_name) order by to_char(pbr2.col_name)) as split_tbl),',',1) as BusinessRoles, 
					   list_collect(cast(collect(to_char(sk2.col_name) order by to_char(sk2.col_name)) as split_tbl),',',1)  AS Skills,
                       list_collect(cast(collect(to_char(t2.col_name) order by to_char(t2.col_name)) as split_tbl),',',1) as  Teams
                FROM   tbl_case cs
                       inner join tbl_dict_casesystype dcst
                               ON cs.col_casedict_casesystype = dcst.col_id
                       inner join tbl_participant prtc
                               ON dcst.col_id = prtc.col_participantcasesystype and prtc.col_participanttasksystype is null
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
                       inner join tbl_dict_workbaskettype pwbt
                               ON pwb.col_workbasketworkbaskettype = pwbt.col_id
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
                --FILTER BY CASE ID
                WHERE  	cs.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'CaseId') AND pwb.col_IsPrivate = 0 and nvl(prtc.col_isdeleted, 0) = 0
                GROUP  BY cs.col_id,
                          pcw.col_id,
                          au.name,
                          au.email,
                          au.photo,
                          dcst.col_code, 
                          dcst.col_name,
                          pcw.col_name,
                          pcwu.name,
                          pwb.col_id,
                          pwb.col_code,
                          pwb.col_name,
                          pwbt.col_code
                UNION 
                SELECT cs.col_id                                     AS Case_Id,
                       pcw.col_id                                    AS CaseWorker_Id,
                       au.name                                       AS CaseWorker_Name,
                       au.email                                      AS CaseWorker_Email,
                       au.photo                                      AS CaseWorker_Photo,
                       dcst.col_code                                 AS CaseSysTypeCode,
                       dcst.col_name                                 AS CaseSysTypeName,
                       pcw.col_name                                  AS CaseWorkerName,
                       pcwu.name                                     AS UserName,
                       pwb.col_id                                    AS WorkBasketId,
                       pwb.col_code                                  AS WorkBasketCode,
                       pwb.col_name                                  AS WorkBasketName,
                       pwbt.col_code                                 AS WorkBasketType_Code,
                        list_collect(cast(collect(to_char(pbr.col_name) order by to_char(pbr.col_name)) as split_tbl),',',1) as BusinessRoles, 
					   list_collect(cast(collect(to_char(sk2.col_name) order by to_char(sk2.col_name)) as split_tbl),',',1)  AS Skills,
                       list_collect(cast(collect(to_char(t2.col_name) order by to_char(t2.col_name)) as split_tbl),',',1) as  Teams
                FROM   tbl_case cs
                       inner join tbl_dict_casesystype dcst
                               ON cs.col_casedict_casesystype = dcst.col_id
                       inner join tbl_participant prtc
                               ON dcst.col_id = prtc.col_participantcasesystype and prtc.col_participanttasksystype is null
                       left  join tbl_dict_partytype pt ON prtc.col_participantdict_partytype = pt.col_id
                       left  join tbl_dict_participanttype ptt ON pt.col_partytypeparticiptype = ptt.col_id
                       inner join vw_ppl_activecaseworker pcw
                               ON prtc.col_participantppl_caseworker = pcw.col_id
                       left  join vw_users au ON pcw.col_userid = au.userid
                       inner join tbl_ppl_workbasket pwb
                               ON pcw.col_id = pwb.col_caseworkerworkbasket
                       inner join tbl_dict_workbaskettype pwbt
                               ON pwb.col_workbasketworkbaskettype = pwbt.col_id
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
                --FILTER BY CASE ID
                WHERE  	cs.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'CaseId') AND pwb.col_IsPrivate = 0 and nvl(prtc.col_isdeleted, 0) = 0
                GROUP  BY cs.col_id,
                          pcw.col_id,
                          au.name,
                          au.email,
                          au.photo,
                          dcst.col_code, 
                          dcst.col_name, 
                          pcw.col_name, 
                          pcwu.name, 
                          pwb.col_id,
                          pwb.col_code, 
                          pwb.col_name,
                          pwbt.col_code
                          ) s1
        ORDER  BY s1.username) s2
WHERE
(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name') IS NULL
	OR (lower(s2.workbaskettype_code)='group' AND lower(s2.workbasketname) LIKE f_UTIL_toWildcards(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name')))
	OR (lower(s2.workbaskettype_code)='personal' AND lower(s2.CaseWorker_Name) LIKE f_UTIL_toWildcards(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name')))
)
order by CASE
		  WHEN lower(s2.workbaskettype_code)='group' THEN s2.workbasketname
		  WHEN lower(s2.workbaskettype_code)='personal' THEN s2.CaseWorker_Name
		END;
    :cur_item := v_cur;
end;