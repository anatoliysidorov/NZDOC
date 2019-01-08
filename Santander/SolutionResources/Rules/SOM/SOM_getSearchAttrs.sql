SELECT sSAttr.COL_SOM_SEARCHATTRSOM_CONFIG AS Config_Id,
       sSAttr.COL_ID AS Id,
       sSAttr.COL_CODE AS Code,
       sSAttr.COL_CUSTOMCONFIG AS CustomConfig,
       sSAttr.COL_DISPLAYFIELD AS DisplayField,
       sSAttr.COL_ISCASEINCENSITIVE AS IsCaseIncensitive,
       sSAttr.COL_ISLIKE AS IsLike,
       sSAttr.COL_NAME AS Name,
       sSAttr.COL_PROCESSORCODE AS ProcessorCode,
       sSAttr.COL_SORDER AS SOrder,
       sSAttr.COL_VALUEFIELD AS ValueField,
       sSAttr.COL_CONSTANT AS CONSTANT,
       sSAttr.COL_DEFAULTVALUE AS DEFAULTVALUE,
       sSAttr.COL_ISPREDEFINED AS ISPREDEFINED,
       fUiEl.COL_ID AS UIElementType_Id,
       fUiEl.COL_NAME AS UIElementType_Name,
       fUiEl.COL_CODE AS UIElementType_Code,
       DECODE(fPath.COL_ID, NULL, 'ATTRIBUTE', 'PATH') AS LinkType_Code,
       DECODE(fPath.COL_ID, NULL, 'Attribute', 'Path') AS LinkType_Name,
       DECODE(fPath.COL_ID, NULL, fAttr.COL_ID, fPath.COL_ID) AS LinkId,
       fAttr.COL_ID AS LinkAttrId,
       fAttr.COL_NAME AS AttrName,
       f_getNameFromAccessSubject(sSAttr.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(sSAttr.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(sSAttr.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(sSAttr.col_modifiedDate) AS ModifiedDuration
  FROM TBL_SOM_SEARCHATTR sSAttr
       LEFT JOIN TBL_FOM_ATTRIBUTE fAttr
          ON fAttr.COL_ID = sSAttr.COL_SOM_SEARCHATTRFOM_ATTR
       LEFT JOIN TBL_FOM_PATH fPath
          ON fPath.COL_ID = sSAttr.COL_SOM_SEARCHATTRFOM_PATH
       LEFT JOIN TBL_FOM_UIELEMENTTYPE fUiEl
          ON fUiEl.COL_ID = sSAttr.COL_SEARCHATTR_UIELEMENTTYPE
 WHERE sSAttr.COL_SOM_SEARCHATTRSOM_CONFIG = :Config_Id AND :Id IS NULL OR (:Id IS NOT NULL AND sSAttr.COL_ID = :Id)
<%=Sort("@SORT@","@DIR@")%>