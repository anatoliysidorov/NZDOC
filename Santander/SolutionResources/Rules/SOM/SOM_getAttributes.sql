SELECT subQ.TYPE AS TYPE,
       subQ.CODE AS CODE,
       subQ.NAME AS NAME,
       subQ.JSONDATA AS JSONDATA,
       subQ.SORDER AS SORDER,
       dbms_xmlgen.CONVERT(subq.CONFIG) AS CONFIG,
       subq.OBJECTNAME AS OBJECTNAME,
       subq.OBJECTCODE AS OBJECTCODE,
       subq.USEONLIST AS USEONLIST,
       subq.USEONSEARCH AS USEONSEARCH,
       subq.TYPENAME AS TYPENAME,
       subq.TYPECODE AS TYPECODE,
       subq.BOTYPE AS BOTYPE,
       subq.FOMOBJECTCODE AS FOMOBJECTCODE,
       subq.OBJECTCONFIG AS OBJECTCONFIG,
       subq.RENDEROBJECTID AS RENDEROBJECTID,
       subq.RENDERCONTROLCODE AS RENDERCONTROLCODE,           
       subq.RENDERCONTROLNAME AS RENDERCONTROLNAME, 
       subq.RENDERCONTROLCONFIG AS RENDERCONTROLCONFIG,
       subq.SEARCHABLECOLUMN AS SEARCHABLECOLUMN,
       subq.SORTABLECOLUMN AS SORTABLECOLUMN,
       subq.FOMCOLUMNNAME AS FOMCOLUMNNAME
       FROM (
                -- Base Fields
            SELECT 'FIELDSETTING' AS TYPE,
                    ssa.COL_CODE AS CODE,
                    ssa.COL_NAME AS NAME,
                    TO_CHAR (ssa.COL_JSONDATA) AS JSONDATA,
                    ssa.COL_SORDER AS SORDER,
                    TO_CHAR (sa.COL_CONFIG) AS CONFIG,
                    so.COL_NAME AS OBJECTNAME,
                    so.COL_CODE AS OBJECTCODE,
                    sa.COL_ISRETRIEVABLEINLIST AS USEONLIST,
                    sa.COL_ISSEARCHABLE AS USEONSEARCH,
                    ddt.COL_NAME AS TYPENAME,
                    ddt.COL_CODE AS TYPECODE,
                    TO_CHAR(so.COL_TYPE) AS BOTYPE,
                    fo.COL_CODE AS FOMOBJECTCODE,
                    (SELECT count(*) FROM tbl_SOM_CONFIG c WHERE c.COL_ID = :CONFIGID AND c.COL_SOM_CONFIGFOM_OBJECT = fo.col_ID) AS OBJECTCONFIG,
                    NULL AS RENDEROBJECTID, 
                    NULL  AS RENDERCONTROLCODE,                    
                    NULL AS RENDERCONTROLNAME, 
                    NULL AS RENDERCONTROLCONFIG,
                    NULL AS SEARCHABLECOLUMN,
                    NULL AS SORTABLECOLUMN,
                     fa.COL_COLUMNNAME AS FOMCOLUMNNAME
            FROM TBL_SOM_SEARCHATTR ssa
                    INNER JOIN TBL_SOM_ATTRIBUTE sa
                    ON upper(sa.COL_CODE) = upper(ssa.COL_CODE)
                        AND (sa.COL_SOM_ATTRIBUTESOM_OBJECT IN
                                (SELECT so.col_id
                                    FROM tbl_som_config sc
                                        INNER JOIN tbl_som_model sm
                                            ON sm.col_id =
                                                sc.col_som_configsom_model
                                        INNER JOIN tbl_som_object so
                                            ON so.col_som_objectsom_model =
                                                sm.col_id
                                    WHERE sc.col_id = :CONFIGID))
                    INNER JOIN TBL_SOM_OBJECT so ON so.col_Id = sa.COL_SOM_ATTRIBUTESOM_OBJECT                    
                    INNER JOIN TBL_FOM_OBJECT fo  ON fo.col_id = so.COL_SOM_OBJECTFOM_OBJECT
                    INNER JOIN TBL_FOM_ATTRIBUTE fa  ON fa.COL_ID = ssa.COL_SOM_SEARCHATTRFOM_ATTR
                    LEFT JOIN TBL_DICT_DATATYPE ddt ON ddt.COL_ID = fa.COL_FOM_ATTRIBUTEDATATYPE
            WHERE ssa.COL_SOM_SEARCHATTRSOM_CONFIG = :CONFIGID
                        AND NVL(ssa.COL_ISDELETED,0) = 0
                        AND (
                                (so.COL_TYPE = 'referenceObject' AND 
                                (SELECT COUNT (*) 
                                FROM tbl_DOM_RenderObject ro 
                                WHERE fo.COL_ID = ro.COL_RENDEROBJECTFOM_OBJECT) = 0) 
                                OR so.COL_TYPE != 'referenceObject'
                        )
                        
             UNION
             
              -- Case /Reference Column Renderers
            SELECT 
                'FIELDSETTING' AS TYPE,
                ssa.COL_CODE AS CODE,
                ssa.COL_NAME AS NAME,
                TO_CHAR (ssa.COL_JSONDATA) AS JSONDATA,
                ssa.COL_SORDER AS SORDER,
                NULL AS CONFIG,
                fo.COL_NAME AS OBJECTNAME,
                fo.COL_CODE AS OBJECTCODE,
                1 AS USEONLIST,
                1 AS USEONSEARCH,
                NVL(ddt.COL_NAME, 'Text')  AS TYPENAME,
                NVL(ddt.COL_CODE, 'TEXT')  AS TYPECODE,
                'renderObject' AS BOTYPE, 
                fo.COL_CODE AS FOMOBJECTCODE,
                NULL AS OBJECTCONFIG,
                ro.COL_ID AS RENDEROBJECTID,
                NULL AS RENDERCONTROLCODE, 
                NULL AS RENDERCONTROLNAME, 
                NULL AS RENDERCONTROLCONFIG,
                f_RDR_getSearchColumn(RENDERGROUPID => ssa.COL_ID, CONFIGID =>  ssa.COL_SOM_SEARCHATTRSOM_CONFIG) AS SEARCHABLECOLUMN,   
                NULL AS SORTABLECOLUMN,
                NULL AS FOMCOLUMNNAME
            FROM TBL_SOM_SEARCHATTR ssa
            INNER JOIN TBL_DOM_RENDEROBJECT ro ON ro.COL_ID = ssa.COL_SOM_SRCHATTRRENDEROBJECT
            LEFT JOIN TBL_DICT_DATATYPE ddt ON ddt.COL_ID = ro.COL_DOM_RENDEROBJECTDATATYPE
            INNER JOIN TBL_FOM_OBJECT fo ON fo.COL_ID = ro.COL_RENDEROBJECTFOM_OBJECT
            WHERE ssa.COL_SOM_SEARCHATTRSOM_CONFIG = :CONFIGID 
                        AND  ssa.COL_SEARCHATTRSEARCHATTRGROUP  IS NULL
                        AND NVL(ssa.COL_ISDELETED,0) = 0
                        AND ro.COL_USEINCASE = 1
            UNION
            
            -- Custom Object  Field  Renderers 
            SELECT 
                'FIELDSETTING' AS TYPE,
                ssa.COL_CODE AS CODE,
                ssa.COL_NAME AS NAME,
                TO_CHAR (ssa.COL_JSONDATA) AS JSONDATA,
                ssa.COL_SORDER AS SORDER,
                NULL AS CONFIG,
                fobjChild.COL_NAME AS OBJECTNAME,
                fobjChild.COL_CODE AS OBJECTCODE,
                1 AS USEONLIST,
                1 AS USEONSEARCH,
                NVL(ddt.COL_NAME, 'Text')  AS TYPENAME,
                NVL(ddt.COL_CODE, 'TEXT')  AS TYPECODE,
                'renderObject' AS BOTYPE, 
                fobjChild.COL_CODE AS FOMOBJECTCODE,
                NULL AS OBJECTCONFIG,
                ro.COL_ID AS RENDEROBJECTID,
                NULL AS RENDERCONTROLCODE, 
                NULL AS RENDERCONTROLNAME, 
                NULL AS RENDERCONTROLCONFIG,
                f_RDR_getSearchColumn(RENDERGROUPID => ssa.COL_ID, CONFIGID =>  ssa.COL_SOM_SEARCHATTRSOM_CONFIG) AS SEARCHABLECOLUMN,         
                NULL AS SORTABLECOLUMN,
                NULL AS FOMCOLUMNNAME
            FROM TBL_SOM_SEARCHATTR ssa
            INNER JOIN TBL_DOM_RENDEROBJECT ro ON ro.COL_ID = ssa.COL_SOM_SRCHATTRRENDEROBJECT  
            LEFT JOIN TBL_DICT_DATATYPE ddt ON ddt.COL_ID = ro.COL_DOM_RENDEROBJECTDATATYPE
            LEFT JOIN TBL_FOM_OBJECT fo ON fo.COL_ID = ro.COL_RENDEROBJECTFOM_OBJECT
            INNER JOIN TBL_FOM_PATH fp ON fp.COL_ID = ssa.COL_SOM_SEARCHATTRFOM_PATH
            INNER JOIN TBL_FOM_RELATIONSHIP rshp ON rshp.COL_ID = fp.COL_FOM_PATHFOM_RELATIONSHIP
            INNER JOIN TBL_FOM_OBJECT fobjChild ON fobjChild.COL_ID = rshp.COL_CHILDFOM_RELFOM_OBJECT
            WHERE ssa.COL_SOM_SEARCHATTRSOM_CONFIG = :CONFIGID 
                        AND ssa.COL_SEARCHATTRSEARCHATTRGROUP  IS NULL
                        AND NVL(ssa.COL_ISDELETED,0) = 0              
                        AND ro.COL_USEINCUSTOMOBJECT = 1
               
            UNION            
            
            -- Base Column
            SELECT 'COLUMNSETTING' AS TYPE,
                    sra.COL_CODE AS CODE,
                    sra.COL_NAME AS NAME,
                    TO_CHAR (sra.COL_JSONDATA) AS JSONDATA,
                    sra.COL_SORDER AS SORDER,
                    TO_CHAR (sa.COL_CONFIG) AS CONFIG,
                    so.COL_NAME AS OBJECTNAME,
                    so.COL_CODE AS OBJECTCODE,
                    sa.COL_ISRETRIEVABLEINLIST AS USEONLIST,
                    sa.COL_ISSEARCHABLE AS USEONSEARCH,
                    ddt.COL_NAME AS TYPENAME,
                    ddt.COL_CODE AS TYPECODE,
                    TO_CHAR(so.COL_TYPE) AS BOTYPE,
                    fo.COL_CODE AS FOMOBJECTCODE,
                    (SELECT count(*) FROM tbl_SOM_CONFIG c WHERE c.COL_ID = :CONFIGID AND c.COL_SOM_CONFIGFOM_OBJECT = fo.col_ID) AS OBJECTCONFIG,
                    NULL AS RENDEROBJECTID ,
                    NULL  AS RENDERCONTROLCODE,
                    NULL AS RENDERCONTROLNAME, 
                    NULL AS RENDERCONTROLCONFIG,
                    NULL AS SEARCHABLECOLUMN,
                    NULL AS SORTABLECOLUMN,
                    fa.COL_COLUMNNAME AS FOMCOLUMNNAME
               FROM TBL_SOM_RESULTATTR sra
                    INNER JOIN TBL_SOM_ATTRIBUTE sa
                       ON upper(sa.COL_CODE) = upper(sra.COL_CODE)
                          AND (sa.COL_SOM_ATTRIBUTESOM_OBJECT IN
                                  (SELECT so.col_id
                                     FROM tbl_som_config sc
                                          INNER JOIN tbl_som_model sm
                                             ON sm.col_id =
                                                   sc.col_som_configsom_model
                                          INNER JOIN tbl_som_object so
                                             ON so.col_som_objectsom_model =
                                                   sm.col_id
                                    WHERE sc.col_id = :CONFIGID))
                    INNER JOIN TBL_SOM_OBJECT so ON sa.COL_SOM_ATTRIBUTESOM_OBJECT = so.col_Id                             
                    INNER JOIN TBL_FOM_OBJECT fo  ON fo.col_id = so.COL_SOM_OBJECTFOM_OBJECT
                    INNER JOIN TBL_FOM_ATTRIBUTE fa  ON fa.COL_ID = sra.COL_SOM_RESULTATTRFOM_ATTR
                    LEFT JOIN TBL_DICT_DATATYPE ddt ON ddt.COL_ID = fa.COL_FOM_ATTRIBUTEDATATYPE
              WHERE sra.COL_SOM_RESULTATTRSOM_CONFIG = :CONFIGID
                         AND NVL(sra.COL_ISDELETED,0) = 0
                         AND (
                                    (so.COL_TYPE = 'referenceObject' AND 
                                    (SELECT COUNT (*) 
                                    FROM tbl_DOM_RenderObject ro 
                                    WHERE fo.COL_ID = ro.COL_RENDEROBJECTFOM_OBJECT) = 0) 
                                    OR so.COL_TYPE != 'referenceObject'
                               )
              
              
            UNION

              -- Case/ Reference Column Renderers 
              SELECT 
                'COLUMNSETTING' AS TYPE,
                sra.COL_CODE AS CODE,
                sra.COL_NAME AS NAME,
                TO_CHAR (sra.COL_JSONDATA) AS JSONDATA,
                sra.COL_SORDER AS SORDER,
                NULL AS CONFIG,
                (CASE WHEN so.col_type = 'referenceObject' THEN so.COL_NAME ELSE fo.COL_NAME END) AS OBJECTNAME,
                (CASE WHEN so.col_type = 'referenceObject' THEN so.COL_CODE ELSE fo.COL_CODE END) AS OBJECTCODE,
                1 AS USEONLIST,
                1 AS USEONSEARCH,
                NVL(ddt.COL_NAME, 'Text')  AS TYPENAME,
                NVL(ddt.COL_CODE, 'TEXT')  AS TYPECODE,
                'renderObject' AS BOTYPE, 
                fo.COL_CODE AS FOMOBJECTCODE,
                NULL AS OBJECTCONFIG,
                ro.COL_ID AS RENDEROBJECTID,
                TO_CHAR(rc.COL_CODE) AS RENDERCONTROLCODE, 
                TO_CHAR(rc.COL_NAME) AS RENDERCONTROLNAME, 
                f_SOM_getRenderControlConfig(CONFIGID => sra.COL_SOM_RESULTATTRSOM_CONFIG, CONTROLCONFIGXML => rc.COL_CONFIG, RENDERGROUPID => sra.COL_ID) AS RENDERCONTROLCONFIG,
                NULL AS SEARCHABLECOLUMN,
                f_RDR_getSortColumn(RENDERGROUPID => sra.COL_ID, CONFIGID =>  sra.COL_SOM_RESULTATTRSOM_CONFIG) AS SORTABLECOLUMN,
                NULL AS FOMCOLUMNNAME
            FROM TBL_SOM_RESULTATTR sra
            INNER JOIN TBL_SOM_ATTRIBUTE sa
            ON upper(sa.COL_CODE) = upper(sra.COL_CODE)
                AND (sa.COL_SOM_ATTRIBUTESOM_OBJECT IN
                        (SELECT so.col_id
                            FROM tbl_som_config sc
                                INNER JOIN tbl_som_model sm
                                    ON sm.col_id =
                                        sc.col_som_configsom_model
                                INNER JOIN tbl_som_object so
                                    ON so.col_som_objectsom_model =
                                        sm.col_id
                            WHERE sc.col_id = :CONFIGID))
            INNER JOIN TBL_SOM_OBJECT so ON so.col_Id = sa.COL_SOM_ATTRIBUTESOM_OBJECT  
            INNER JOIN TBL_DOM_RENDEROBJECT ro ON ro.COL_ID = sra.COL_SOM_RESATTRRENDEROBJECT
            LEFT JOIN TBL_DICT_DATATYPE ddt ON ddt.COL_ID = ro.COL_DOM_RENDEROBJECTDATATYPE
            INNER JOIN TBL_FOM_OBJECT fo ON fo.COL_ID = ro.COL_RENDEROBJECTFOM_OBJECT
            INNER JOIN TBL_DOM_RENDERCONTROL rc ON rc.COL_ID = sra.COL_SOM_RESULTATTRRENDERCTRL
            WHERE sra.COL_SOM_RESULTATTRSOM_CONFIG = :CONFIGID 
                        AND sra.COL_RESULTATTRRESULTATTRGROUP  IS NULL
                        AND NVL(sra.COL_ISDELETED,0) = 0
                        AND ro.COL_USEINCASE = 1
             
            UNION
            
            -- Custom Object Column Renderers 
            SELECT 
                'COLUMNSETTING' AS TYPE,
                sra.COL_CODE AS CODE,
                sra.COL_NAME AS NAME,
                TO_CHAR (sra.COL_JSONDATA) AS JSONDATA,
                sra.COL_SORDER AS SORDER,
                NULL AS CONFIG,
                fobjChild.COL_NAME AS OBJECTNAME,
                fobjChild.COL_CODE AS OBJECTCODE,
                1 AS USEONLIST,
                1 AS USEONSEARCH,
                NVL(ddt.COL_NAME, 'Text')  AS TYPENAME,
                NVL(ddt.COL_CODE, 'TEXT')  AS TYPECODE,
                'renderObject' AS BOTYPE, 
                fobjChild.COL_CODE AS FOMOBJECTCODE,
                NULL AS OBJECTCONFIG,
                ro.COL_ID AS RENDEROBJECTID,
                TO_CHAR(rc.COL_CODE) AS RENDERCONTROLCODE, 
                TO_CHAR(rc.COL_NAME) AS RENDERCONTROLNAME, 
                f_SOM_getRenderControlConfig(CONFIGID => sra.COL_SOM_RESULTATTRSOM_CONFIG, CONTROLCONFIGXML => rc.COL_CONFIG, RENDERGROUPID => sra.COL_ID) AS RENDERCONTROLCONFIG,
                NULL AS SEARCHABLECOLUMN,
                f_RDR_getSortColumn(RENDERGROUPID => sra.COL_ID, CONFIGID =>  sra.COL_SOM_RESULTATTRSOM_CONFIG) AS SORTABLECOLUMN,
                NULL AS FOMCOLUMNNAME
            FROM TBL_SOM_RESULTATTR sra
            INNER JOIN TBL_DOM_RENDEROBJECT ro ON ro.COL_ID = sra.COL_SOM_RESATTRRENDEROBJECT  
            LEFT JOIN TBL_DICT_DATATYPE ddt ON ddt.COL_ID = ro.COL_DOM_RENDEROBJECTDATATYPE
            LEFT JOIN TBL_FOM_OBJECT fo ON fo.COL_ID = ro.COL_RENDEROBJECTFOM_OBJECT
            INNER JOIN TBL_DOM_RENDERCONTROL rc ON rc.COL_ID = sra.COL_SOM_RESULTATTRRENDERCTRL
            INNER JOIN TBL_FOM_PATH fp ON fp.COL_ID = sra.COL_SOM_RESULTATTRFOM_PATH
            INNER JOIN TBL_FOM_RELATIONSHIP rshp ON rshp.COL_ID = fp.COL_FOM_PATHFOM_RELATIONSHIP
            INNER JOIN TBL_FOM_OBJECT fobjChild ON fobjChild.COL_ID = rshp.COL_CHILDFOM_RELFOM_OBJECT
            WHERE sra.COL_SOM_RESULTATTRSOM_CONFIG = :CONFIGID 
                        AND sra.COL_RESULTATTRRESULTATTRGROUP  IS NULL
                        AND NVL(sra.COL_ISDELETED,0) = 0 AND
                        ro.COL_USEINCUSTOMOBJECT = 1
               
) subQ