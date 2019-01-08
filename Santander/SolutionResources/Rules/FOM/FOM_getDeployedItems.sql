 SELECT r.code  AS Code,
  r.columnname AS ColumnName,
 'Relationship' AS COLUMNTYPE
  -------------------------------------------
FROM vw_fom_relationship r
WHERE (:Object_Id IS NULL
OR (:Object_Id    IS NOT NULL
AND R.Sourcebo     = :Object_Id ))
AND (:Type        IS NULL
OR (:Type         IS NOT NULL
AND lower(:Type)   ='relationship'))
UNION
SELECT a.bacode  AS Code,
  a.bacolumnname AS ColumnName,
'Attribute' AS COLUMNTYPE
  -------------------------------------------
FROM Vw_Util_Deployedbo a
WHERE (:Object_Id IS NULL
OR (:Object_Id    IS NOT NULL
AND a.botablename  = :Object_Id ))
AND (:Type        IS NULL
OR (:Type         IS NOT NULL
AND lower(:Type)   ='attribute'))
<%=Sort("@SORT@","@DIR@")%>