SELECT sRAttr.COL_SOM_RESULTATTRSOM_CONFIG AS Config_Id,
       sRAttr.COL_ID AS Id,
       sRAttr.COL_CODE AS Code,
       sRAttr.COL_CUSTOMCONFIG AS CustomConfig,
       sRAttr.COL_NAME AS Name,
       sRAttr.COL_SORDER AS SOrder,
       sRAttr.COL_IDPROPERTY AS IdProperty,
       sRAttr.COL_ISHIDDEN AS IsHidden,
       dataType.COL_ID AS dataType_Id,
       dataType.COL_NAME AS dataType_Name,
       dataType.COL_CODE AS dataType_Code,
       DECODE(fPath.COL_ID, NULL, 'ATTRIBUTE', 'PATH') AS LinkType_Code,
       DECODE(fPath.COL_ID, NULL, 'Attribute', 'Path') AS LinkType_Name,
       DECODE(fPath.COL_ID, NULL, fAttr.COL_ID, fPath.COL_ID) AS LinkId,
       fAttr.COL_NAME AS AttrName,
       fAttr.COL_ID AS LinkAttrId,
       f_getNameFromAccessSubject(sRAttr.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(sRAttr.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(sRAttr.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(sRAttr.col_modifiedDate) AS ModifiedDuration
  FROM tbl_som_resultattr sRAttr
       LEFT JOIN TBL_FOM_ATTRIBUTE fAttr
          ON fAttr.COL_ID = sRAttr.COL_SOM_RESULTATTRFOM_ATTR
       LEFT JOIN TBL_FOM_PATH fPath
          ON fPath.COL_ID = sRAttr.COL_SOM_RESULTATTRFOM_PATH
       LEFT JOIN TBL_DICT_DATATYPE dataType
          ON dataType.COL_ID = fAttr.COL_FOM_ATTRIBUTEDATATYPE
 WHERE sRAttr.COL_SOM_RESULTATTRSOM_CONFIG = :Config_Id AND :Id IS NULL OR (:Id IS NOT NULL AND sRAttr.COL_ID = :Id)
<%=Sort("@SORT@","@DIR@")%>