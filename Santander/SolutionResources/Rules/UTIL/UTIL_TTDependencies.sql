DECLARE 
    v_result NCLOB; 
BEGIN 
    FOR rec IN (SELECT ds.col_type AS TaskDependency_Type, 
                       tsiParent.col_map_taskstateinittasktmpl AS ParentTaskTemplate_Id 
                FROM   tbl_taskdependency ds 
                       left join tbl_map_taskstateinitiation tsiParent 
                              ON tsiParent.col_id = 
                                 ds.col_tskdpndprnttskstateinit 
                WHERE  ds.col_tskdpndchldtskstateinit = :childtaskstateinit) LOOP 
        IF v_result IS NULL THEN 
          v_result := To_char(rec.ParentTaskTemplate_Id) 
                      || '|' 
                      || To_char(rec.TaskDependency_Type); 
        ELSE 
          v_result := v_result 
                      || ',' 
                      || To_char(rec.ParentTaskTemplate_Id) 
                      || '|' 
                      || To_char(rec.TaskDependency_Type); 
        END IF; 
    END LOOP; 

    RETURN v_result; 
END; 