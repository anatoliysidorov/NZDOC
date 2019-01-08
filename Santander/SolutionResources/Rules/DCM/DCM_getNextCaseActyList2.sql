SELECT 
		cst.col_id as ID,
		csts.col_activity AS NextActivity,
		csts.col_code as NextActivity_Code,
		dim.col_code as CaseNextStateInitMethod
FROM   tbl_dict_casetransition cst
       inner join tbl_dict_casestate csss on cst.col_sourcecasetranscasestate = csss.col_id
       inner join tbl_dict_casestate csts on cst.col_targetcasetranscasestate = csts.col_id 
       inner join tbl_cw_workitem cwi on csss.col_id = cwi.col_cw_workitemdict_casestate
       inner join tbl_case cs on cwi.col_id = cs.col_cw_workitemcase 
		left join tbl_map_casestateinitiation mcsi on cs.col_id = mcsi.col_map_casestateinitcase and csts.col_id = mcsi.col_map_csstinit_csst
		left join tbl_dict_initmethod dim on mcsi.col_casestateinit_initmethod = dim.col_id
WHERE  cs.col_id = :CaseId 
