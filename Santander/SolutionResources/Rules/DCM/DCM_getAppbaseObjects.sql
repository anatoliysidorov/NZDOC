SELECT 
    OBJECT_TYPE,
    OBJECT_ID,
    OBJECT_NAME,
    OBJECT_CODE,
    TAGS,
    COMPONENTID,
    CASE 
        WHEN (SELECT 
                    COUNT(*) 
                FROM 
                TABLE(ASF_SPLITCLOB(TAGS, ',')) 
                WHERE COLUMN_VALUE  = :FIND_BY_TAG) > 0 AND :FIND_BY_TAG IS NOT NULL THEN
            'TRUE'
        WHEN :FIND_BY_TAG IS NULL THEN
            'SEARCH_IS_NOT_USED'
        ELSE
            'FALSE'
            
    END AS TAG_EXIST
    
FROM (
    SELECT
        APPBASE_OBJECT.OBJECT_TYPE,
        APPBASE_OBJECT.OBJECT_ID,
        APPBASE_OBJECT.OBJECT_NAME,
        APPBASE_OBJECT.OBJECT_CODE,
        LISTAGG(TO_CHAR(TAG.CODE), ',') 
        WITHIN GROUP (ORDER BY TAG.CODE) AS TAGS,
        APPBASE_OBJECT.COMPONENTID
    FROM (SELECT
                'RULE' AS OBJECT_TYPE,
                RULE.RULEID AS OBJECT_ID,
                RULE.NAME AS OBJECT_NAME,
                RULE.CODE AS OBJECT_CODE,
                RULE.COMPONENTID AS COMPONENTID
            FROM 
                @TOKEN_SYSTEMDOMAINUSER@.CONF_RULE RULE
            WHERE NVL(RULE.ISSYSTEM,0) = 0

            UNION ALL

            SELECT
                'PAGE' AS OBJECT_TYPE,
                PAGE.PAGEID AS OBJECT_ID,
                PAGE.NAME AS OBJECT_NAME,
                PAGE.CODE AS OBJECT_CODE,
                PAGE.COMPONENTID AS COMPONENTID
            FROM 
                @TOKEN_SYSTEMDOMAINUSER@.CONF_NAVPAGE PAGE

            UNION ALL

            SELECT
                'RELATION' AS OBJECT_TYPE,
                RELATION.RELATIONID AS OBJECT_ID,
                RELATION.NAME AS OBJECT_NAME,
                RELATION.CODE AS OBJECT_CODE,
                RELATION.COMPONENTID AS COMPONENTID
            FROM 
                @TOKEN_SYSTEMDOMAINUSER@.CONF_BORELATION RELATION

            UNION ALL

            SELECT
                'OBJECT' AS OBJECT_TYPE,
                OBJECT.OBJECTID AS OBJECT_ID,
                OBJECT.NAME AS OBJECT_NAME,
                OBJECT.CODE AS OBJECT_CODE,
                OBJECT.COMPONENTID AS COMPONENTID
            FROM 
                @TOKEN_SYSTEMDOMAINUSER@.CONF_BOOBJECT OBJECT

            UNION ALL

            SELECT
                'APPLICATION' AS OBJECT_TYPE,
                APPLICATION.APPID AS OBJECT_ID,
                APPLICATION.NAME AS OBJECT_NAME,
                APPLICATION.CODE AS OBJECT_CODE,
                APPLICATION.COMPONENTID AS COMPONENTID
            FROM 
                @TOKEN_SYSTEMDOMAINUSER@.CONF_APPLICATION APPLICATION
        ) APPBASE_OBJECT

    LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT TAG_OBJECT ON TAG_OBJECT.OBJECTID = APPBASE_OBJECT.OBJECT_ID
    LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAG TAG ON TAG.TAGID = TAG_OBJECT.TAGID

    WHERE APPBASE_OBJECT.COMPONENTID = (SELECT 
                                            COMPONENTID 
                                        FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION 
                                        WHERE CODE = (SELECT 
                                                            VERCONF.CODE 
                                                        FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_ENVIRONMENT ENV 
                                                        INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION VERR ON VERR.VERSIONID = ENV.DEPVERSIONID 
                                                        INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION VERCONF ON VERCONF.SOLUTIONID = VERR.SOLUTIONID AND VERCONF.TYPE=1
                                                        WHERE ENV.CODE = '@TOKEN_DOMAIN@')
                                                        )
    GROUP BY 
        APPBASE_OBJECT.OBJECT_TYPE,
        APPBASE_OBJECT.OBJECT_ID,
        APPBASE_OBJECT.OBJECT_NAME,
        APPBASE_OBJECT.OBJECT_CODE,
        APPBASE_OBJECT.COMPONENTID
)