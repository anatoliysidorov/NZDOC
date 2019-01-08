--only show users who are not case workers, or those who are case workers but are deleted 
SELECT vau.userid as USERID, 
       vau.name as NAME, 
       vau.email as EMAIL,
       CASE vau.source
       WHEN 0 THEN 'DB'
       WHEN 1 THEN 'AD'
       ELSE 'DB'
       END        AS LOGINTYPE,
       cw.col_isdeleted AS IsDeleted 
FROM   vw_users vau 
       left join tbl_ppl_caseworker cw ON ( vau.userid = cw.col_userid ) 
WHERE  cw.col_id IS NULL OR cw.col_isdeleted = 1         
<%=Sort("@SORT@","@DIR@")%>