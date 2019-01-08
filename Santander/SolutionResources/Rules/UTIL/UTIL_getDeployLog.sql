SELECT col_id                              AS Id, 
       F_util_getdrtnfrmnow(col_startdate) AS CreatedDuration, 
       col_startdate                       AS StartDate, 
       col_enddate                         AS EndDate 
FROM   tbl_util_deploymentlog 
ORDER  BY col_createddate DESC 