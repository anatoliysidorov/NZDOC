DECLARE
    v_code NVARCHAR2(255);

BEGIN

    BEGIN
                               
       SELECT 
            (CASE WHEN ro.COL_USEINCUSTOMOBJECT = 1 and resultattr.col_code = renderattr.col_code THEN fo.COL_ALIAS ELSE resultattr.COL_CODE END) INTO v_code
        FROM TBL_SOM_RESULTATTR resultattr
        INNER JOIN TBL_DOM_RENDERATTR renderattr ON renderattr.COL_ID = resultattr.COL_SOM_RESULTATTRRENDERATTR
        INNER JOIN TBL_DOM_RENDEROBJECT ro ON ro.COL_ID = resultattr.COL_SOM_RESATTRRENDEROBJECT
        INNER JOIN TBL_FOM_ATTRIBUTE fo ON fo.COL_ID = resultattr.COL_SOM_RESULTATTRFOM_ATTR   
        WHERE resultattr.COL_SOM_RESULTATTRSOM_CONFIG = :CONFIGID
                    AND resultattr.COL_RESULTATTRRESULTATTRGROUP = :RENDERGROUPID
                    AND renderattr.COL_ISSORTABLE = 1;
                            
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_code := 'NO_DATA_FOUND';
   WHEN OTHERS THEN
        v_code := 'OTHERS_ERROR';
    END;
   
    RETURN v_code;   
END;