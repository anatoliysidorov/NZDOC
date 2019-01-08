SELECT   
	vau.userid
	,vau.photo
	,vau.NAME
	,vau.EMAIL
	,decode(count(ar1.roleid), 0, '1', '11') as user_sr_filter
	, 'Not calculated' as user_sr
	, 'Not calculated' as user_sg
	/*,list_collect(cast(collect(to_char(ar.localcode) order by to_char(ar.localcode)) as split_tbl),'|||',1) as user_sr*/
	/*,list_collect(cast(collect(to_char(ag.NAME) order by to_char(ag.NAME)) as split_tbl),'|||',1) as user_sg*/
FROM   
	vw_ppl_caseworkersusers vau
	LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_userrole aur ON (vau.userid = aur.userid)
	LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_role ar ON (aur.roleid = ar.roleid)
	LEFT JOIN (SELECT roleid FROM @TOKEN_SYSTEMDOMAINUSER@.asf_role WHERE envid = '@TOKEN_DOMAIN@') ar1 ON (aur.roleid = ar1.roleid)
	LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_usergroup aug ON (vau.userid = aug.userid)
	LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_group ag ON (aug.groupid = ag.groupid)
GROUP BY   
	vau.userid
	,vau.photo
	,vau.NAME
	,vau.EMAIL
ORDER BY vau.NAME