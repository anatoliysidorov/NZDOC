begin



    for jornal_record  in (select 
                                upper(modeljournal.col_dbname) as db_name,
                                modeljournal.col_appbasecode as appbasecode,
                                modeljournal.col_errorcode as errorcode,
                                modeljournal.col_errormessage as errormessage
                            from 
                                tbl_mdm_modelversion modelversion
                                
                            inner join tbl_dom_modeljournal modeljournal 
                                on modeljournal.col_mdm_modverdom_modjrnl = modelversion.col_id
                                
                            where 
                            modelversion.col_id = (select max(vers.col_id) from tbl_mdm_modelversion vers where vers.col_mdm_modelversionmdm_model = :modelid)
                            and modeljournal.col_dbname is not null)
                            
    loop
    
        update tbl_dom_modelcache 
        set col_dbname = jornal_record.db_name,
        col_errorcode = jornal_record.errorcode,
        col_errormessage = jornal_record.errormessage
        where col_appbasecode = jornal_record.appbasecode;
        
    end loop;





/*UPDATE tbl_dom_modelcache modelcache
SET 
    (modelcache.col_dbname) = ( SELECT 
                                    upper(modeljornal.col_dbname)
                                FROM 
                                    tbl_mdm_modelversion modelversion
                                    
                                INNER JOIN tbl_dom_modeljornal modeljornal 
                                    ON modeljornal.col_mdm_modverdom_modjrn = modelversion.col_id
                                    
                                WHERE modelversion.col_mdm_modelversionmdm_model = :ModelId
                                AND modeljornal.col_dbname IS NOT NULL
                                AND modelcache.col_appbasecode = modeljornal.col_appbasecode 
                                group by upper(modeljornal.col_dbname)
                                )                    
WHERE EXISTS (
         SELECT 
            1
        FROM 
            tbl_mdm_modelversion modelversion
            
        INNER JOIN tbl_dom_modeljornal modeljornal 
            ON modeljornal.col_mdm_modverdom_modjrn = modelversion.col_id
            
        WHERE modelversion.col_mdm_modelversionmdm_model = ModelId
        AND modeljornal.col_dbname IS NOT NULL
        AND modelcache.col_appbasecode = modeljornal.col_appbasecode 
        );     */                           
                                
------------for check which one records will be modified--------------------
/*SELECT 

    jrn.col_dbname jornal_dbname,
    jrn.col_appbasecode  jornal_appbasecode,
    cch.col_dbname cache_dbname,
    cch.col_appbasecode  cache_appbasecode
    
FROM ( SELECT 
            modeljornal.col_dbname ,
            modeljornal.col_appbasecode
        FROM 
            tbl_mdm_modelversion modelversion
            
        INNER JOIN tbl_dom_modeljornal modeljornal 
            ON modeljornal.col_mdm_modverdom_modjrn = modelversion.col_id
            
        WHERE modelversion.col_mdm_modelversionmdm_model = ModelId
        AND modeljornal.col_dbname IS NOT NULL
        GROUP BY modeljornal.col_dbname ,modeljornal.col_appbasecode) jrn 
        
INNER JOIN 
    (SELECT 
        col_dbname,
        col_appbasecode 
    FROM tbl_dom_modelcache) cch 
    
ON jrn.col_appbasecode = cch.col_appbasecode*/

end;