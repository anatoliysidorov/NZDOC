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
  select
	s1.workbasket_Id                 as Id,
	s1.caseworker_id                 as caseworker_id,
	s1.caseworker_name               as caseworker_name,
	s1.caseworker_photo              as caseworker_photo,
	s1.caseworker_email              as caseworker_email,
	s1.caseworker_accesssubject      as caseworker_accesssubject,
	s1.caseworker_firstname          as caseworker_firstname,
	s1.caseworker_lastname           as caseworker_lastname,
	s1.workbasket_id                 as workbasket_Id,
	s1.workbasket_code               as workbasket_code,
	s1.workbasket_name               as workbasket_name,
	wbt.col_Code                     as WorkBasketType_Code,
	list_collect(cast(collect(to_char(s.col_name) order by to_char(s.col_name)) as split_tbl),',',1) as skills,
	list_collect(cast(collect(to_char(t.col_name) order by to_char(t.col_name)) as split_tbl),',',1) as teams,
	list_collect(cast(collect(to_char(br.col_name) order by to_char(br.col_name)) as split_tbl),',',1) as b_roles,
	case
		when lower(wbt.col_Code)='group' THEN s1.workbasket_name
		when lower(wbt.col_Code)='personal' THEN s1.caseworker_name
	end as CalculatedName

  from
  (
  --business roles in participants
  select
  pcwu.id                          as caseworker_id,
  pcwu.name                        as caseworker_name,
  pcwu.photo                       as caseworker_photo,
  pcwu.email                       as caseworker_email,
  pcwu.accode                      as caseworker_accesssubject,
  pcwu.firstname                   as caseworker_firstname,
  pcwu.lastname                    as caseworker_lastname,
  pwb.col_id                       as workbasket_Id,
  pwb.col_code                     as workbasket_code,
  pwb.col_name                     as workbasket_name,
  pwb.col_workbasketworkbaskettype as workbasketType_Id
  from tbl_caseparty cp
  left join tbl_participant prtc on cp.col_casepartyparticipant = prtc.col_id
  inner join tbl_case cs on cp.col_casepartycase = cs.col_id
  inner join tbl_dict_casesystype dcst on cs.col_casedict_casesystype = dcst.col_id
  inner join tbl_task tsk on cs.col_id = tsk.col_casetask
  inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
  inner join tbl_ppl_businessrole pbr on cp.col_casepartyppl_businessrole = pbr.col_id
  inner join tbl_caseworkerbusinessrole cwbr on pbr.col_id = cwbr.col_tbl_ppl_businessrole 
  inner join vw_ppl_activecaseworkersusers pcwu on cwbr.col_br_ppl_caseworker = pcwu.id
  inner join tbl_ppl_workbasket pwb on pcwu.id = pwb.col_caseworkerworkbasket
  where cs.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'CaseId')
    and cp.col_casepartytasksystype = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'TaskTypeId')
    and pwb.col_IsPrivate = 0
  union
  --teams in participants
  select
  pcwu.id                          as caseworker_id,
  pcwu.name                        as caseworker_name,
  pcwu.photo                       as caseworker_photo,
  pcwu.email                       as caseworker_email,
  pcwu.accode                      as caseworker_accesssubject,
  pcwu.firstname                   as caseworker_firstname,
  pcwu.lastname                    as caseworker_lastname,
  pwb.col_id                       as workbasket_Id,
  pwb.col_code                     as workbasket_code,
  pwb.col_name                     as workbasket_name,
  pwb.col_workbasketworkbaskettype as workbasketType_Id
  from tbl_caseparty cp
  left join tbl_participant prtc on cp.col_casepartyparticipant = prtc.col_id
  inner join tbl_case cs on cp.col_casepartycase = cs.col_id
  inner join tbl_dict_casesystype dcst on cs.col_casedict_casesystype = dcst.col_id
  inner join tbl_task tsk on cs.col_id = tsk.col_casetask
  inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
  inner join tbl_ppl_team ptm on cp.col_casepartyppl_team = ptm.col_id
  inner join tbl_caseworkerteam cwtm on ptm.col_id = cwtm.col_tbl_ppl_team 
  inner join vw_ppl_activecaseworkersusers pcwu on cwtm.col_tm_ppl_caseworker = pcwu.id
  inner join tbl_ppl_workbasket pwb on pcwu.id = pwb.col_caseworkerworkbasket
  where cs.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'CaseId')
    and cp.col_casepartytasksystype = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'TaskTypeId')
    and pwb.col_IsPrivate = 0
  union
  --skills in participants
  select
  pcwu.id                          as caseworker_id,
  pcwu.name                        as caseworker_name,
  pcwu.photo                       as caseworker_photo,
  pcwu.email                       as caseworker_email,
  pcwu.accode                      as caseworker_accesssubject,
  pcwu.firstname                   as caseworker_firstname,
  pcwu.lastname                    as caseworker_lastname,
  pwb.col_id                       as workbasket_Id,
  pwb.col_code                     as workbasket_code,
  pwb.col_name                     as workbasket_name,
  pwb.col_workbasketworkbaskettype as workbasketType_Id
  from tbl_caseparty cp
  left join tbl_participant prtc on cp.col_casepartyparticipant = prtc.col_id
  inner join tbl_case cs on cp.col_casepartycase = cs.col_id
  inner join tbl_dict_casesystype dcst on cs.col_casedict_casesystype = dcst.col_id
  inner join tbl_task tsk on cs.col_id = tsk.col_casetask
  inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
  inner join tbl_ppl_skill psk on cp.col_casepartyppl_skill = psk.col_id
  inner join tbl_caseworkerskill cwsk on psk.col_id = cwsk.col_tbl_ppl_skill
  inner join vw_ppl_activecaseworkersusers pcwu on cwsk.col_sk_ppl_caseworker = pcwu.id
  inner join tbl_ppl_workbasket pwb on pcwu.id = pwb.col_caseworkerworkbasket
  where dcst.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'CaseId')
    and cp.col_casepartytasksystype = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'TaskTypeId')
    and pwb.col_IsPrivate = 0
  union
  --caseworkers in participants
  select
  pcwu.id                          as caseworker_id,
  pcwu.name                        as caseworker_name,
  pcwu.photo                       as caseworker_photo,
  pcwu.email                       as caseworker_email,
  pcwu.accode                      as caseworker_accesssubject,
  pcwu.firstname                   as caseworker_firstname,
  pcwu.lastname                    as caseworker_lastname,
  pwb.col_id                       as workbasket_Id,
  pwb.col_code                     as workbasket_code,
  pwb.col_name                     as workbasket_name,
  pwb.col_workbasketworkbaskettype as workbasketType_Id
  from tbl_caseparty cp
  left join tbl_participant prtc on cp.col_casepartyparticipant = prtc.col_id
  inner join tbl_case cs on cp.col_casepartycase = cs.col_id
  inner join tbl_dict_casesystype dcst on cs.col_casedict_casesystype = dcst.col_id
  inner join tbl_task tsk on cs.col_id = tsk.col_casetask
  inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
  inner join vw_ppl_activecaseworkersusers pcwu on cp.col_casepartyppl_caseworker = pcwu.id
  inner join tbl_ppl_workbasket pwb on pcwu.id = pwb.col_caseworkerworkbasket
  where cs.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'CaseId')
    and cp.col_casepartytasksystype = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'TaskTypeId')
    and pwb.col_IsPrivate = 0
) s1
  --Skill
  left join tbl_caseworkerskill cws on (s1.caseworker_id = cws.col_sk_ppl_caseworker)
  left join tbl_ppl_skill s on (cws.col_tbl_ppl_skill = s.col_id)
  --Team
  left join tbl_caseworkerteam cwt on (s1.caseworker_id = cwt.col_tm_ppl_caseworker)
  left join tbl_ppl_team t on ( cwt.col_tbl_ppl_team = t.col_id)
  --BRoles
  left join tbl_caseworkerbusinessrole cwb on (s1.caseworker_id = cwb.col_br_ppl_caseworker)
  left join tbl_ppl_businessrole br on (cwb.col_tbl_ppl_businessrole = br.col_id)
  inner join tbl_DICT_WorkBasketType wbt on (wbt.col_id = s1.workbasketType_Id)
  where 
	  (f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name') IS NULL
		  or (lower(wbt.col_Code)='group' and lower(s1.workbasket_name) like f_UTIL_toWildcards(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name')))
		  or (lower(wbt.col_Code)='personal' and lower(s1.caseworker_name) like f_UTIL_toWildcards(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name')	))
	  )
  group by s1.caseworker_id,
           s1.caseworker_name,
           s1.caseworker_photo,
           s1.caseworker_email,
           s1.caseworker_accesssubject,
           s1.caseworker_firstname,
           s1.caseworker_lastname,
           s1.workbasket_id,
           s1.workbasket_code,
           s1.workbasket_name,
           wbt.col_Code;
  :Items := v_cur;
end;