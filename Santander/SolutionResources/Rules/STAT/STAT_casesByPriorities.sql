SELECT records, 
       priority_value, 
       priority_name, 
       CASE 
              WHEN casestate_isstart = 1 THEN 'START'
              WHEN casestate_isresolve = 1 THEN 'RESOLVE' 
              WHEN casestate_isfinish = 1 THEN 'FINISH'
              ELSE 'NONE' 
       END AS statetype 
FROM  ( 
                SELECT   count(1) AS records, 
                         priority_value, 
                         priority_name, 
                         casestate_isresolve, 
                         casestate_isfinish, 
                         casestate_isstart 
                FROM     vw_dcm_simplecase 
                WHERE    priority_value IS NOT NULL 
                GROUP BY priority_value, 
                         priority_name, 
                         casestate_isresolve, 
                         casestate_isfinish, 
                         casestate_isstart 
                ORDER BY priority_value)