SELECT id, 
       caseworkerid, 
       accesssubject, 
       name,
       StartDate,
       EndDate
FROM   TABLE(F_dcm_getproxyassignorlist()) 