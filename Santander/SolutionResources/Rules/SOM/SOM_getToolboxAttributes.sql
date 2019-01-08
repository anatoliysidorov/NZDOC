SELECT  
    obj.Lvl AS LVL,
    so.COL_NAME AS OBJECTNAME,
    so.COL_CODE AS OBJECTCODE,
    sa.COL_NAME AS NAME,
    sa.COL_CODE AS CODE,
    (CASE WHEN  robj.col_id IS NULL THEN  sa.COL_ISRETRIEVABLEINLIST ELSE 1 END) AS USEONLIST,
    (CASE WHEN  robj.col_id IS NULL THEN  sa.COL_ISSEARCHABLE ELSE 1 END) AS USEONSEARCH,
    dbms_xmlgen.CONVERT(sa.COL_CONFIG) AS CONFIG,
    (CASE WHEN fomDataType.COL_ICONCODE IS NOT NULL THEN fomDataType.COL_ICONCODE
             WHEN renderDataType.COL_ICONCODE IS NOT NULL THEN renderDataType.COL_ICONCODE
             ELSE to_nchar('text-height') END) AS ICONCODE,
    (CASE WHEN fomDataType.COL_NAME IS NOT NULL THEN fomDataType.COL_NAME
         WHEN renderDataType.COL_NAME IS NOT NULL THEN renderDataType.COL_NAME
         ELSE to_nchar('Text') END) AS TYPENAME,
    (CASE WHEN fomDataType.COL_CODE IS NOT NULL THEN fomDataType.COL_CODE
        WHEN renderDataType.COL_CODE IS NOT NULL THEN renderDataType.COL_CODE
        ELSE to_nchar('TEXT') END) AS TYPECODE,
     (SELECT COUNT (*)
        FROM TBL_SOM_ResultAttr sra
       WHERE upper(sra.COL_CODE) = upper(sa.COL_CODE)
             AND sra.COL_SOM_RESULTATTRSOM_CONFIG = :CONFIGID
             AND NVL (sra.col_isdeleted, 0) = 0)
        AS ADDEDINTOGRID,
     (SELECT COUNT (*)
        FROM TBL_SOM_SearchAttr ssa
       WHERE upper(ssa.COL_CODE) = upper(sa.COL_CODE)
             AND ssa.COL_SOM_SEARCHATTRSOM_CONFIG = :CONFIGID
             AND NVL (ssa.col_isdeleted, 0) = 0)
        AS ADDEDINTOSEARCH,
     (CASE WHEN so.col_type = 'referenceObject' THEN sChildBo.COL_NAME ELSE NULL END) AS CHILDBONAME,
     (CASE WHEN  robj.col_id IS NOT NULL THEN  to_nchar('renderObject') ELSE so.COL_TYPE END) AS BOTYPE,
     robj.col_id as  RENDEROBJECTID
FROM (SELECT 1 AS Lvl,
         TO_NUMBER (:ObjectId) AS ObjID,
         NULL AS CHILDID
    FROM DUAL
  UNION ALL
      SELECT LEVEL + 1,
             COL_PARENTSOM_RELSOM_OBJECT,
             COL_CHILDSOM_RELSOM_OBJECT AS CHILDID
        FROM TBL_SOM_RELATIONSHIP
  CONNECT BY PRIOR COL_PARENTSOM_RELSOM_OBJECT =
                COL_CHILDSOM_RELSOM_OBJECT
  START WITH COL_CHILDSOM_RELSOM_OBJECT = :ObjectId) obj
 LEFT JOIN TBL_SOM_OBJECT sChildBo ON sChildBo.col_id = obj.CHILDID
 INNER JOIN TBL_SOM_OBJECT so ON so.col_id = obj.ObjID
 INNER JOIN TBL_SOM_ATTRIBUTE sa ON sa.COL_SOM_ATTRIBUTESOM_OBJECT = so.col_Id
 LEFT JOIN TBL_FOM_ATTRIBUTE fa ON fa.COL_ID = sa.COL_SOM_ATTRFOM_ATTR
 LEFT JOIN TBL_DICT_DATATYPE fomDataType ON fomDataType.COL_ID = fa.COL_FOM_ATTRIBUTEDATATYPE
 LEFT JOIN TBL_DOM_RENDEROBJECT robj ON sa.COL_SOM_ATTRIBUTERENDEROBJECT = robj.COL_ID     
 LEFT JOIN TBL_DICT_DATATYPE renderDataType ON renderDataType.COL_ID = robj.COL_DOM_RENDEROBJECTDATATYPE  
 WHERE 
            -- exclude Case/Reference fields for root search config
            (SELECT COUNT (*)
                FROM tbl_DOM_RenderAttr rattr
               WHERE fa.col_Id = rattr.COL_RENDERATTRFOM_ATTRIBUTE) = 0
               
             -- exclude Custom Objects that by DataType
             AND (SELECT COUNT (*)
                    FROM tbl_DOM_RenderObject ro
                   WHERE fomDataType.col_Id = ro.COL_DOM_RENDEROBJECTDATATYPE
                         AND ro.COL_USEINCUSTOMOBJECT = 1) = 0
                                                   
ORDER BY  obj.Lvl ,so.COL_NAME, sa.COL_NAME