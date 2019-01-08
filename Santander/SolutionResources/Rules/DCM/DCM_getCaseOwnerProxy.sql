SELECT cs.col_id       AS Id, 
       cs.col_id       AS CaseId, 
       wb.col_id       WorkbasketId, 
       wb.col_code     AS WorkbasketCode, 
       wbt.col_code    AS WorkbasketTypeCode, 
       pal.name        AS AssignorName, 
       s1.assigneename AS AssigneeName 
FROM   tbl_case cs 
       inner join tbl_ppl_workbasket wb 
               ON cs.col_caseppl_workbasket = wb.col_id 
       inner join tbl_dict_workbaskettype wbt 
               ON wb.col_workbasketworkbaskettype = wbt.col_id 
       inner join vw_ppl_activecaseworker cw 
               ON wb.col_caseworkerworkbasket = cw.col_id 
       inner join TABLE(F_dcm_getproxyassignorlist()) pal 
               ON cw.col_id = pal.id 
       left join (SELECT col_assignor               AS Id, 
                         col_assignor               AS CaseworkerId, 
                         (SELECT accode 
                          FROM   vw_ppl_activecaseworkersusers 
                          WHERE  id = col_assignor) AS AccessSubject, 
                         (SELECT name 
                          FROM   vw_ppl_activecaseworkersusers 
                          WHERE  id = col_assignor) AS AssignorName, 
                         col_assignee               AS AssigneeId, 
                         (SELECT accode 
                          FROM   vw_ppl_activecaseworkersusers 
                          WHERE  id = col_assignee) AS AssigneeAccessSubject, 
                         (SELECT name 
                          FROM   vw_ppl_activecaseworkersusers 
                          WHERE  id = col_assignee) AS AssigneeName 
                  FROM   tbl_proxy 
                  WHERE  col_assignee = (SELECT id 
                                         FROM   vw_ppl_activecaseworkersusers 
                                         WHERE  accode = 
                                        Sys_context('CLIENTCONTEXT', 
                                        'AccessSubject')) 
                         AND SYSDATE BETWEEN col_startdate AND col_enddate) s1 
              ON cw.col_id = s1.id 
WHERE  wbt.col_code = 'PERSONAL' 
       AND cs.col_id = :CaseId 