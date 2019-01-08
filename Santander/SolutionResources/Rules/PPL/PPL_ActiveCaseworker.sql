SELECT c.col_id AS ID, 
       c.col_id AS col_id, 
       c.col_code, 
       c.col_createdby, 
       c.col_createddate, 
       c.col_modifiedby, 
       c.col_modifieddate,     
       c.col_lockedby, 
       c.col_lockeddate, 
       c.col_lockedexpdate, 
       c.col_owner, 
       c.col_name, 
       c.col_userid, 
       c.col_caseworkeraccesssubject, 
       c.col_caseworkercaseworker,
       u.AccessSubjectCode
FROM   tbl_ppl_caseworker c
LEFT JOIN vw_users u ON u.USERID = c.COL_USERID 
WHERE  NVL(col_isdeleted, 0) = 0 AND NVL(u.STATUS,0) = 0  AND NVL(u.ISLOCKEDOUT, 0) = 0