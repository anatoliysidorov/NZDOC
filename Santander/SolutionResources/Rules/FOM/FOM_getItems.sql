SELECT *
  FROM (SELECT attr.col_id AS Id,
               attr.COL_COLUMNNAME AS ColumnName,
               attr.col_code AS Code,
               attr.col_name AS Name,
               attr.COL_FOM_ATTRIBUTEFOM_OBJECT AS OBJECT_ID,
               'Attribute' AS TYPE,
               attr.col_isdeleted AS IsDeleted,
               -------------------------------------------
               f_getNameFromAccessSubject(attr.col_createdBy) AS CreatedBy_Name,
               f_UTIL_getDrtnFrmNow(attr.col_createdDate) AS CreatedDuration,
               f_getNameFromAccessSubject(attr.col_modifiedBy) AS ModifiedBy_Name,
               f_UTIL_getDrtnFrmNow(attr.col_modifiedDate) AS ModifiedDuration
               -------------------------------------------
          FROM tbl_fom_attribute attr
         WHERE     (:Attribute_Id IS NULL OR (:Attribute_Id IS NOT NULL AND attr.col_id = :Attribute_Id))
               AND (:Object_Id IS NULL OR (:Object_Id IS NOT NULL AND attr.COL_FOM_ATTRIBUTEFOM_OBJECT = :Object_Id))
               AND (:TYPE IS NULL OR (:TYPE IS NOT NULL AND LOWER(:TYPE) = 'attribute'))
        --------------------------------------------------------------------
        UNION
        ----------------------------------------------------------------------
        SELECT rel.col_id AS Id,
               rel.COL_FOREIGNKEYNAME AS ColumnName,
               rel.col_code AS Code,
               rel.col_name AS Name,
               rel.COL_PARENTFOM_RELFOM_OBJECT AS OBJECT_ID,
               'Relationship' AS TYPE,
               rel.col_isdeleted AS IsDeleted,
               -------------------------------------------
               f_getNameFromAccessSubject(rel.col_createdBy) AS CreatedBy_Name,
               f_UTIL_getDrtnFrmNow(rel.col_createdDate) AS CreatedDuration,
               f_getNameFromAccessSubject(rel.col_modifiedBy) AS ModifiedBy_Name,
               f_UTIL_getDrtnFrmNow(rel.col_modifiedDate) AS ModifiedDuration
               -------------------------------------------
          FROM tbl_fom_relationship rel
         WHERE     (:Relationship_Id IS NULL OR (:Relationship_Id IS NOT NULL AND rel.col_id = :Relationship_Id))
               AND (:Object_Id IS NULL OR (:Object_Id IS NOT NULL AND rel.COL_PARENTFOM_RELFOM_OBJECT = :Object_Id))
               AND (:TYPE IS NULL OR (:TYPE IS NOT NULL AND LOWER(:TYPE) = 'relationship')))
<%=Sort("@SORT@","@DIR@")%>