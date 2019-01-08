SELECT wbs.id, 
              wbs.code, 
              wbs.CALCNAME, 
              wbs.isdefault, 
              wbs.workbaskettype_id, 
              wbs.workbaskettype_name, 
              wbs.workbaskettype_code 
       FROM   vw_ppl_activecaseworkersusers cwu 
              inner join tbl_map_workbasketcaseworker mwbcw ON cwu.id = mwbcw.col_map_wb_cw_caseworker
              inner join vw_PPL_SimpleWorkbasket wbs ON mwbcw.col_map_wb_cw_workbasket = wbs.id
       WHERE  cwu.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
       AND    lower(wbs.workbaskettype_code)  = 'group'
       
       UNION ALL
       
	SELECT wbs.id, 
              wbs.code, 
              wbs.CALCNAME, 
              wbs.isdefault, 
              wbs.workbaskettype_id, 
              wbs.workbaskettype_name, 
              wbs.workbaskettype_code 
       FROM   vw_ppl_activecaseworkersusers cwu
              inner join tbl_caseworkerbusinessrole cwbr ON cwu.id = cwbr.col_br_ppl_caseworker
			  inner join vw_PPL_SimpleWorkbasket wbs ON cwbr.col_tbl_ppl_businessrole = wbs.BusinessRole_Id
       WHERE  cwu.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject') 
       AND    lower(wbs.workbaskettype_code)  = 'personal'
	  
       UNION ALL
	   
       SELECT wbs.id, 
              wbs.code, 
              wbs.CALCNAME, 
              wbs.isdefault, 
              wbs.workbaskettype_id, 
              wbs.workbaskettype_name, 
              wbs.workbaskettype_code 
       FROM   vw_ppl_activecaseworkersusers cwu
              inner join tbl_caseworkerbusinessrole cwbr ON cwu.id = cwbr.col_br_ppl_caseworker
              inner join tbl_map_workbasketbusnessrole mwbbr ON cwbr.col_tbl_ppl_businessrole = mwbbr.col_map_wb_wr_businessrole 
              inner join vw_PPL_SimpleWorkbasket wbs ON mwbbr.col_map_wb_br_workbasket = wbs.id 
       WHERE  cwu.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject') 
       AND    lower(wbs.workbaskettype_code)  = 'group'
			  
       UNION ALL

       SELECT wbs.id, 
              wbs.code, 
              wbs.CALCNAME, 
              wbs.isdefault, 
              wbs.workbaskettype_id, 
              wbs.workbaskettype_name, 
              wbs.workbaskettype_code 
       FROM   vw_ppl_activecaseworkersusers cwu
              inner join tbl_caseworkerteam cwtm ON cwu.id = cwtm.col_tm_ppl_caseworker
			 inner join vw_PPL_SimpleWorkbasket wbs ON cwtm.COL_TBL_PPL_TEAM = wbs.Team_Id
       WHERE  cwu.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject') 
       AND    lower(wbs.workbaskettype_code)  = 'personal'

       UNION ALL
       
       -- Workbasket - Skill
       SELECT wbs.id, 
              wbs.code, 
              wbs.CALCNAME, 
              wbs.isdefault, 
              wbs.workbaskettype_id, 
              wbs.workbaskettype_name, 
              wbs.workbaskettype_code 
      FROM   vw_ppl_activecaseworkersusers cwu
              inner join TBL_CASEWORKERSKILL cws ON cws.col_sk_ppl_caseworker = cwu.ID
              inner join TBL_PPL_SKILL sk ON sk.COL_ID = cws.COL_TBL_PPL_SKILL
              inner join TBL_MAP_WORKBASKETSKILL mws ON mws.COL_MAP_WS_SKILL = sk.COL_ID
              inner join vw_PPL_SimpleWorkbasket wbs ON mws.COL_MAP_WS_WORKBASKET = wbs.id
       WHERE  cwu.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject') 
              AND lower(wbs.workbaskettype_code)  = 'group'

      