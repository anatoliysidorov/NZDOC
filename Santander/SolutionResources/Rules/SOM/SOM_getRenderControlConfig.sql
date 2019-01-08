DECLARE 
    v_renderGroupdId NUMBER;
    v_configId NUMBER;
    v_config NCLOB;
    v_mapConfigName NVARCHAR2(255);
    v_res NVARCHAR2(500);

BEGIN
    v_config := :CONTROLCONFIGXML;
    v_renderGroupdId := :RENDERGROUPID;
    v_configId := :CONFIGID;
              
     IF v_config IS NOT NULL THEN
    
         FOR rec IN (
             SELECT t.extract('/attribute/name/text()').getstringval() as name,
                         t.extract('/attribute/value/text()').getstringval() as value
            FROM TABLE((XMLSequence(XMLType(v_config).extract( '/attributes/attribute', v_config)))) t
        )
        LOOP
            
             BEGIN
                           
                 SELECT 
                        (CASE WHEN ro.COL_USEINCUSTOMOBJECT = 1 and resultattr.col_code = renderattr.col_code THEN fo.COL_ALIAS ELSE  resultattr.COL_CODE END) INTO v_mapConfigName
                 FROM TBL_SOM_RESULTATTR resultattr
                 INNER JOIN TBL_DOM_RENDERATTR renderattr ON renderattr.COL_ID = resultattr.COL_SOM_RESULTATTRRENDERATTR AND renderattr.COL_CODE = rec.value
                 INNER JOIN TBL_DOM_RENDEROBJECT ro ON ro.COL_ID = resultattr.COL_SOM_RESATTRRENDEROBJECT
                 INNER JOIN TBL_FOM_ATTRIBUTE fo ON fo.COL_ID = resultattr.COL_SOM_RESULTATTRFOM_ATTR   
                 WHERE resultattr.COL_SOM_RESULTATTRSOM_CONFIG = v_configId
                             AND resultattr.COL_RESULTATTRRESULTATTRGROUP = v_renderGroupdId;
                
             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_mapConfigName := NULL;
             END;
        
             v_res := v_res || ',"' || rec.name || '"' || ':' || '"' || v_mapConfigName || '"';
                     
        END LOOP; 
    END IF;
    
    IF(v_res IS NOT NULL) THEN
        v_res := SUBSTR(v_res, 2, LENGTH(v_res));
        v_res := '{' || v_res || '}';
    END IF;
    
   return v_res;    
END;