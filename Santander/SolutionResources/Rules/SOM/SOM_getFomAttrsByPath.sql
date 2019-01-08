SELECT fAttr.COL_ID AS AttrId,
       fAttr.COL_NAME AS AttrColName,
       fAttr.COL_CODE AS AttrColCode,
       fAttr.COL_ALIAS AS AttrAlias,
       fObj.COL_NAME AS TableName,
       DECODE(fObj.COL_ID, fRel.COL_PARENTFOM_RELFOM_OBJECT, 1 , 0) AS IsParent,
       GREATEST(NVL(fAttr.COL_ISDELETED, 0), NVL(fRel.COL_ISDELETED, 0), NVL(fObj.COL_ISDELETED, 0)) AS ISDELETED
  FROM TBL_FOM_PATH fPath
 INNER JOIN TBL_FOM_RELATIONSHIP fRel
    ON fPath.COL_FOM_PATHFOM_RELATIONSHIP = fRel.COL_ID
 INNER JOIN TBL_FOM_ATTRIBUTE fAttr
    ON fAttr.COL_FOM_ATTRIBUTEFOM_OBJECT = fRel.COL_CHILDFOM_RELFOM_OBJECT
    OR fAttr.COL_FOM_ATTRIBUTEFOM_OBJECT = fRel.COL_PARENTFOM_RELFOM_OBJECT
 INNER JOIN TBL_FOM_OBJECT fObj
    ON fObj.COL_ID = fAttr.COL_FOM_ATTRIBUTEFOM_OBJECT
 WHERE NVL(:Path_Id, 0) <> 0 AND fAttr.COL_FOM_ATTRIBUTEFOM_OBJECT <> :Object_Id 
   AND fPath.COL_ID  = :Path_Id -- One path
   /*AND fPath.COL_ID IN  ( --Level path
    SELECT tfp.COL_ID AS ID
      FROM TBL_FOM_PATH tfp
   CONNECT BY tfp.COL_ID = PRIOR tfp.COL_FOM_PATHFOM_PATH
     START WITH tfp.COL_ID = :Path_Id
   )*/
 UNION ALL
SELECT mainAttr.COL_ID AS AttrId,
       mainAttr.COL_NAME AS AttrColName,
       mainAttr.COL_CODE AS AttrColCode,
       mainAttr.COL_ALIAS AS AttrAlias,
       mainObj.COL_NAME AS TableName,
       NULL AS IsParent,
       GREATEST(NVL(mainAttr.COL_ISDELETED, 0), NVL(mainObj.COL_ISDELETED, 0)) AS ISDELETED
  FROM TBL_FOM_ATTRIBUTE mainAttr
 INNER JOIN TBL_FOM_OBJECT mainObj
    ON mainObj.COL_ID = mainAttr.COL_FOM_ATTRIBUTEFOM_OBJECT
 WHERE NVL(:Path_Id, 0) = 0 AND NVL(:Object_Id, 0) <> 0 AND mainAttr.COL_FOM_ATTRIBUTEFOM_OBJECT = :Object_Id
ORDER BY IsParent DESC, AttrColName ASC