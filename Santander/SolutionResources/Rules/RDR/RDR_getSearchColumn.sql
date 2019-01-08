DECLARE
    v_code NVARCHAR2(255);

BEGIN

    BEGIN
                               
        SELECT 
            searchattr.COL_CODE INTO v_code
        FROM TBL_SOM_SEARCHATTR searchattr
        INNER JOIN TBL_DOM_RENDERATTR renderattr ON renderattr.COL_ID = searchattr.COL_SOM_SEARCHATTRRENDERATTR
        WHERE searchattr.COL_SOM_SEARCHATTRSOM_CONFIG = :CONFIGID
                AND searchattr.COL_SEARCHATTRSEARCHATTRGROUP = :RENDERGROUPID
                AND renderattr.COL_ISSEARCHABLE = 1; 
                            
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_code := 'NO_DATA_FOUND';
   WHEN OTHERS THEN
        v_code := 'OTHERS_ERROR';
    END;
   
    RETURN v_code;   
END;