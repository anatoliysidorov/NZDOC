select cw.id as CaseWorkerId,
       :ThreadId as ThreadId,
       cw.NAME as Name,
       usr.EMAIL as Email,
       cw.isdeleted as Status,
       (select list_collect(cast(collect(to_char(skillname) order by to_char(skillname)) as split_tbl),'|||',1)
          from (select sk.col_name as skillname,
                       sk.col_id   as id,
                       cwsk.col_sk_ppl_caseworker
                  from tbl_caseworkerskill  cwsk
                       left join tbl_ppl_skill sk
                           on cwsk.col_tbl_ppl_skill = sk.col_id)
         where col_sk_ppl_caseworker = cw.id) as Skills,
       (select list_collect(cast(collect(to_char(teamname) order by to_char(teamname)) as split_tbl),'|||',1) 
          from (select tm.col_name as teamname, cwtm.col_tm_ppl_caseworker
                  from tbl_caseworkerteam  cwtm
                       left join tbl_ppl_team tm
                           on cwtm.col_tbl_ppl_team = tm.col_id)
         where col_tm_ppl_caseworker = cw.id) as Teams,
       (select list_collect(cast(collect(to_char(rolename) order by to_char(rolename)) as split_tbl),'|||',1) 
          from (select br.col_name as rolename, cwbr.col_br_ppl_caseworker
                  from tbl_caseworkerbusinessrole  cwbr
                       left join tbl_ppl_businessrole br
                           on cwbr.col_tbl_ppl_businessrole = br.col_id)
         where col_br_ppl_caseworker = cw.id) as BusinessRoles
from vw_ppl_caseworkersusers cw
inner join vw_users usr on usr.userid = cw.userid
<%= IfNotNull(":IsPartOfThread", " inner join tbl_threadcaseworker tcw on tcw.col_caseworkerid = cw.id ") %>
-- START Get all Case Workers who have CASE TYPE - VIEW rights
<%= IfNotNull(":IsNotPartOfThread"," inner join (select col_cstpviewcachecaseworker as CaseWorkerId from vw_dcm_simplecaselist clst ") %>
<%= IfNotNull(":IsNotPartOfThread"," inner join tbl_ac_casetypeviewcache ctvc on clst.casesystype_id = ctvc.col_casetypeviewcachecasetype ") %>
<%= IfNotNull(":IsNotPartOfThread"," where clst.id = :CaseId) cw_access on cw_access.CaseWorkerId = cw.id ") %>
-- END Get all Case Workers who have CASE TYPE - VIEW rights

where
        -- Get all members of the Discussion Thread   
        <%= IfNotNull(":IsPartOfThread", " tcw.col_threadid = :ThreadId and") %>

        -- Get all Case Workers who are not already part of the Discussion Thread
        <%= IfNotNull(":IsNotPartOfThread", " cw.id not in (select col_caseworkerid from tbl_threadcaseworker where col_threadid = :ThreadId) and ") %>

        (:TeamCodes is null or cw.id in (select cwtm.col_tm_ppl_caseworker
                                                from tbl_caseworkerteam  cwtm
                                                inner join tbl_ppl_team tm on cwtm.col_tbl_ppl_team = tm.col_id                            
                                                where cwtm.col_tm_ppl_caseworker = cw.id  
                                                      and lower(tm.col_code) in (select lower(column_value) from table(asf_split(:TeamCodes, ',')))))                                                    
        and (:SkillCodes is null or cw.id in (select cwsk.col_sk_ppl_caseworker
                                                  from tbl_caseworkerskill cwsk
                                                  inner join tbl_ppl_skill sk on cwsk.col_tbl_ppl_skill = sk.col_id
                                                  where cwsk.col_sk_ppl_caseworker = cw.id
                                                       and lower(sk.col_code) in (select lower(column_value) from table(asf_split(:SkillCodes, ',')))))
        and (:BusinessRoleCodes is null or cw.id in (select cwbr.col_br_ppl_caseworker
                                                 from tbl_caseworkerbusinessrole  cwbr
                                                 left join tbl_ppl_businessrole br on cwbr.col_tbl_ppl_businessrole = br.col_id
                                                 where cwbr.col_br_ppl_caseworker = cw.id
                                                       and lower(br.col_code) in (select lower(column_value) from table(asf_split(:BusinessRoleCodes, ',')))))
        and (:Name is null or lower(nvl(cw.name, cw.firstname || ' ' || cw.lastname)) like '%' || lower(:Name) || '%')                                         
                                   
<%=Sort("@SORT@","@DIR@")%> 