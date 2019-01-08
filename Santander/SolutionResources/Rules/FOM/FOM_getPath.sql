SELECT objPath.ID AS Id, 
       objPath.CODE AS Code, 
       objPath.NAME AS Name, 
       objPath.RelId AS  RelId,
       objPath.PathPathId AS PathPathId, 
       objPath.LevelPath AS LevelPath,
       Relation.COL_NAME AS RelName,
       Relation.COL_CHILDFOM_RELFOM_OBJECT AS ChildTableId,
       fObjC.COL_TABLENAME AS ChildTable,
       Relation.COL_PARENTFOM_RELFOM_OBJECT AS ParentTableId,
       fObjP.COL_TABLENAME AS ParentTable,
       CASE
        WHEN fObjC.COL_ID <> :Object_Id AND fObjP.COL_ID <> :Object_Id THEN
          fObjP.COL_NAME || ' - ' || fObjC.COL_NAME
        ELSE
          DECODE(fObjC.COL_ID, :Object_Id, fObjP.COL_NAME, fObjC.COL_NAME)
       END AS TableRelName
      
FROM (
  SELECT tfp.COL_ID AS ID,
         tfp.COL_CODE AS CODE,
         tfp.COL_NAME AS NAME,
         tfp.COL_FOM_PATHFOM_RELATIONSHIP AS RelId,
         tfp.COL_FOM_PATHFOM_PATH AS PathPathId,
         LEVEL AS LevelPath
    FROM TBL_FOM_PATH tfp
  CONNECT BY tfp.COL_ID = PRIOR tfp.COL_FOM_PATHFOM_PATH
  START WITH tfp.COL_ID IN(
  SELECT fPath.COL_ID
    FROM TBL_FOM_PATH fPath
   INNER JOIN TBL_FOM_RELATIONSHIP fRel
      ON fRel.COL_ID = fPath.COL_FOM_PATHFOM_RELATIONSHIP
   WHERE fRel.COL_CHILDFOM_RELFOM_OBJECT  = :Object_Id
      OR fRel.COL_PARENTFOM_RELFOM_OBJECT = :Object_Id
  )
   ORDER BY LevelPath ASC
) objPath
LEFT JOIN TBL_FOM_RELATIONSHIP Relation
  ON Relation.COL_ID = objPath.RelId
LEFT JOIN TBL_FOM_OBJECT fObjC
  ON fObjC.COL_ID = Relation.COL_CHILDFOM_RELFOM_OBJECT
LEFT JOIN TBL_FOM_OBJECT fObjP
  ON fObjP.COL_ID = Relation.COL_PARENTFOM_RELFOM_OBJECT
<%=Sort("@SORT@","@DIR@")%>