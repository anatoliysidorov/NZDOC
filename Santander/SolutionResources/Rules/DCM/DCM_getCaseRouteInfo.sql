DECLARE
	--input
	v_case_id integer;

BEGIN
	--input
	v_case_id := :case_Id;
	
	--system
	:ErrorCode := 0;
	:ErrorMessage := '';
	
	--get next states for the case
	OPEN :CUR_AVAILTRANSITIONS FOR
		select cst.col_id               as ID,
			cst.col_name                as NAME,
			cst.col_iconcode            as ICONCODE,
			csts.col_activity           as TARGET_ACTIVITY,
			csts.col_isstart            as TARGET_ISSTART,
			csts.col_isresolve          as TARGET_ISRESOLVE,
			csts.col_isfinish           as TARGET_ISFINISH,
			csts.col_isassign           as TARGET_CANASSIGN
		from   tbl_dict_casetransition cst
			inner join tbl_dict_casestate csss on cst.col_sourcecasetranscasestate = csss.col_id
			inner join tbl_dict_casestate csts on cst.col_targetcasetranscasestate = csts.col_id
			inner join tbl_cw_workitem cwi on csss.col_id = cwi.col_cw_workitemdict_casestate
			inner join tbl_case cs on cwi.col_id = cs.col_cw_workitemcase
			left join tbl_map_casestateinitiation mcsi on cs.col_id = mcsi.col_map_casestateinitcase and csts.col_id = mcsi.col_map_csstinit_csst
			left join tbl_dict_initmethod dim on mcsi.col_casestateinit_initmethod = dim.col_id
			left join tbl_fom_uielement uect on cst.col_id = uect.col_uielementcasetransition and cs.col_casedict_casesystype = uect.col_uielementcasesystype
			left join tbl_fom_uielement ue on cst.col_id = ue.col_uielementcasetransition and uect.col_uielementcasesystype is null
		where  
			case 
				when uect.col_id is not null then nvl(uect.col_ishidden,0)
				when ue.col_id is not null then nvl(ue.col_ishidden,0)
				else 0 
			end = 0
			and cs.col_id = v_case_id
		ORDER BY csts.col_defaultorder ASC;
	
	--get resolution codes for the case
	OPEN :CUR_RESCODES FOR
		SELECT 
			rc.col_id as ID,
			rc.col_code as CODE,
			rc.col_description as DESCRIPTION,
			rc.col_name as NAME,
			rc.col_iconcode as ICONCODE,
			rc.col_theme as THEME
		FROM tbl_case t
		INNER JOIN tbl_casesystyperesolutioncode m ON m.col_tbl_dict_casesystype = t.col_casedict_casesystype
		INNER JOIN tbl_stp_resolutioncode rc ON rc.col_id = m.col_casetyperesolutioncode
		WHERE t.col_id = v_case_id
		ORDER BY UPPER(rc.col_name);
END;