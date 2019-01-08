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
SELECT 
	s1.workbasket_Id                AS Id, 
	s1.caseworker_id                AS caseworker_id, 
	s1.caseworker_name              AS caseworker_name, 
	s1.caseworker_photo              AS caseworker_photo, 
	s1.caseworker_email              AS caseworker_email,
	s1.caseworker_accesssubject  AS caseworker_accesssubject,
	s1.caseworker_firstname  AS caseworker_firstname,
	s1.caseworker_lastname  AS caseworker_lastname,			   
	s1.workbasket_id                AS workbasket_Id, 
	s1.workbasket_code              AS workbasket_code, 
	s1.workbasket_name              AS workbasket_name, 
	wbt.col_Code 			AS	WorkBasketType_Code,
	list_collect(cast(collect(to_char(s.col_name) order by to_char(s.col_name)) as split_tbl),',',1) as skills,
	list_collect(cast(collect(to_char(t.col_name) order by to_char(t.col_name)) as split_tbl),',',1) as teams,
	list_collect(cast(collect(to_char(br.col_name) order by to_char(br.col_name)) as split_tbl),',',1) as b_roles,
	CASE
		WHEN lower(wbt.col_Code)='group' THEN s1.workbasket_name
		WHEN lower(wbt.col_Code)='personal' THEN s1.caseworker_name
	END as CalculatedName
	    
FROM   (SELECT pcwu.id   AS caseworker_id, 
               pcwu.name AS caseworker_name, 
			   pcwu.photo AS caseworker_photo, 
               pcwu.email  AS caseworker_email,
			   pcwu.accode  AS caseworker_accesssubject,
			   pcwu.firstname  AS caseworker_firstname,
			   pcwu.lastname  AS caseworker_lastname,
               pwb.col_id   AS workbasket_Id, 
               pwb.col_code AS workbasket_code, 
               pwb.col_name AS workbasket_name,
			   pwb.col_WORKBASKETWORKBASKETTYPE AS workbasketType_Id			   
			   
        FROM   tbl_participant prtc 
               inner join tbl_dict_casesystype dcst 
                       ON prtc.col_participantcasesystype = dcst.col_id 
               inner join tbl_ppl_businessrole pbr 
                       ON prtc.col_participantbusinessrole = pbr.col_id 
               inner join tbl_caseworkerbusinessrole cwbr 
                       ON pbr.col_id = cwbr.col_tbl_ppl_businessrole 
               inner join vw_ppl_activecaseworkersusers pcwu 
                       ON cwbr.col_br_ppl_caseworker = pcwu.id 
               inner join tbl_ppl_workbasket pwb 
                       ON pcwu.id = pwb.col_caseworkerworkbasket 	   
        WHERE  	dcst.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'CaseSysType_Id') AND
				pwb.col_IsPrivate = 0 AND 
				prtc.col_participanttasksystype IS NULL 
        UNION 
        SELECT pcwu.id   AS caseworker_id, 
               pcwu.name AS caseworker_name, 
			   pcwu.photo AS caseworker_photo, 
               pcwu.email  AS caseworker_email,
			   pcwu.accode  AS caseworker_accesssubject,
			   pcwu.firstname  AS caseworker_firstname,
			   pcwu.lastname  AS caseworker_lastname,
               pwb.col_id   AS workbasket_Id, 
               pwb.col_code AS workbasket_code, 
               pwb.col_name AS workbasket_name,
			   pwb.col_WORKBASKETWORKBASKETTYPE AS workbasketType_Id
        FROM   tbl_participant prtc 
               inner join tbl_dict_casesystype dcst 
                       ON prtc.col_participantcasesystype = dcst.col_id 
               inner join vw_ppl_activecaseworkersusers pcwu 
                       ON prtc.col_participantppl_caseworker = pcwu.id 
               inner join tbl_ppl_workbasket pwb 
                       ON pcwu.id = pwb.col_caseworkerworkbasket 

        WHERE  	dcst.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'CaseSysType_Id') AND
				pwb.col_IsPrivate = 0 AND
                prtc.col_participanttasksystype IS NULL) s1 
       --Skill 
       left join tbl_caseworkerskill cws 
              ON ( s1.caseworker_id = cws.col_sk_ppl_caseworker ) 
       left join tbl_ppl_skill s 
              ON ( cws.col_tbl_ppl_skill = s.col_id ) 
       --Team 
       left join tbl_caseworkerteam cwt 
              ON ( s1.caseworker_id = cwt.col_tm_ppl_caseworker ) 
       left join tbl_ppl_team t 
              ON ( cwt.col_tbl_ppl_team = t.col_id ) 
       --BRoles 
       left join tbl_caseworkerbusinessrole cwb 
              ON ( s1.caseworker_id = cwb.col_br_ppl_caseworker ) 
       left join tbl_ppl_businessrole br 
              ON ( cwb.col_tbl_ppl_businessrole = br.col_id )
INNER JOIN tbl_DICT_WorkBasketType wbt ON (wbt.col_id = s1.workbasketType_Id)
WHERE 
	(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name') IS NULL
		OR (lower(wbt.col_Code)='group' AND lower(s1.workbasket_name) LIKE f_UTIL_toWildcards(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name')))
		OR (lower(wbt.col_Code)='personal' AND lower(s1.caseworker_name) LIKE f_UTIL_toWildcards(f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Name')	))
	)
	AND (f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Skill') IS NULL or s.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Skill'))
	AND (f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Team') IS NULL or t.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'Team'))
	AND (f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'BusinessRole') IS NULL or br.col_id = f_FORM_getParamByName(Input => v_input.getClobVal(), Param => 'BusinessRole'))		  
GROUP  BY s1.caseworker_id, 
          s1.caseworker_name, 
		  s1.caseworker_photo, 
          s1.caseworker_email,
		  s1.caseworker_accesssubject,
	      s1.caseworker_firstname,
	      s1.caseworker_lastname,			   
          s1.workbasket_id, 
          s1.workbasket_code, 
          s1.workbasket_name,
			wbt.col_Code
order by CASE
		WHEN lower(wbt.col_Code)='group' THEN s1.workbasket_name
		WHEN lower(wbt.col_Code)='personal' THEN s1.caseworker_name
	END;
    :cur_item := v_cur;
end;