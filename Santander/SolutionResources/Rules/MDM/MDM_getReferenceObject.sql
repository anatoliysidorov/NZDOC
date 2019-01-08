  SELECT ro.COL_ID AS ID,
         ro.COL_NAME AS NAME,
         ro.COL_CODE AS CODE,
         NVL (fo.COL_APICODE, ro.COL_CODE) AS APICODE,
         f_MDM_getXMLRefAttr(RefObjectId => ro.COL_ID, RefObjectName => ro.COL_NAME) AS ATTRIBUTES
    FROM    TBL_DOM_REFERENCEOBJECT ro
         INNER JOIN
            TBL_FOM_OBJECT fo
         ON fo.COL_ID = ro.COL_DOM_REFOBJECTFOM_OBJECT
    WHERE NVL(ro.col_isDeleted, 0) = 0
ORDER BY ro.COL_NAME