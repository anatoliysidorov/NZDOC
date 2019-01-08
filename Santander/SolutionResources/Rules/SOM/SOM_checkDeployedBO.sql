SELECT
   count(*) as COUNT_NOTDEPLOYED
FROM tbl_som_object so
INNER JOIN tbl_fom_object fo on fo.col_id = so.col_som_objectfom_object
INNER JOIN tbl_fom_attribute fa on fa.col_fom_attributefom_object = fo.col_id
LEFT JOIN vw_util_deployedbo dbo on lower(dbo.BACODE) = lower(fa.col_apicode)
LEFT JOIN vw_fom_relationship frc on lower(frc.CODE) = lower(fa.col_apicode)
WHERE ((:ConfigId  is not null  and so.col_som_objectsom_model = 
                                                (SELECT sm.col_id
                                                FROM tbl_som_config sc
                                                INNER JOIN tbl_som_model sm
                                                    ON sm.col_id = sc.col_som_configsom_model
                                                WHERE sc.col_id = :ConfigId)) 
            or (:ModelId is not null and so.col_som_objectsom_model = :ModelId)) 
            and so.col_type IN ('businessObject', 'rootBusinessObject')
            and dbo.col_id is null
            and frc.col_id is null
            and fa.col_alias NOT IN ('PARENTID', 'ID')
            
            
            
            
            
            