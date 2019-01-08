SELECT domAttr.COL_ID AS ID,
       domAttr.COL_UCODE AS UCODE,
       CASE 
            WHEN domObj.COL_TYPE = 'referenceObject' THEN domObj.COL_NAME 
            ELSE  domAttr.COL_NAME 
       END AS NAME,
       dbms_xmlgen.CONVERT(TO_CHAR(domAttr.COL_CONFIG)) AS CONFIG,
       f_getNameFromAccessSubject(domAttr.COL_MODIFIEDBY) AS MODIFIEDBY,
       f_getNameFromAccessSubject(domAttr.COL_CREATEDBY) AS CREATEDBY,
       domAttr.COL_CODE AS CODE,
       f_UTIL_getDrtnFrmNow(domAttr.COL_MODIFIEDDATE) AS MODIFIEDDATE,
       f_UTIL_getDrtnFrmNow(domAttr.COL_CREATEDDATE) AS CREATEDDATE,
       domAttr.COL_DOM_ATTRFOM_ATTR AS DOM_ATTRFOM_ATTR,
       domAttr.COL_DOM_ATTRIBUTEDOM_OBJECT AS DOM_ATTRIBUTEDOM_OBJECT,
       domAttr.COL_DORDER AS DORDER,
       domAttr.COL_ISUPDATABLE AS ISUPDATABLE,
       domAttr.COL_ISSEARCHABLE AS ISSEARCHABLE,
       domAttr.COL_ISRETRIEVABLEINLIST AS ISRETRIEVABLEINLIST,
       domAttr.COL_ISRETRIEVABLEINDETAIL AS ISRETRIEVABLEINDETAIL,
       domAttr.COL_ISINSERTABLE AS ISINSERTABLE,
       domAttr.COL_ISREQUIRED AS ISREQUIRED,
       dataType.COL_NAME AS TYPENAME,
       dataType.COL_ICONCODE AS ICONCODE,
       CASE 
            WHEN domObj.COL_TYPE = 'referenceObject' THEN CAST('reference' AS NVARCHAR2(255)) 
            ELSE  dataType.COL_CODE
       END AS TYPECODE,
       domObj.COL_CODE AS BOCODE,
       refObj.COL_CODE AS REFERENCE_OBJECT_CODE
FROM TBL_DOM_ATTRIBUTE domAttr
    LEFT JOIN TBL_DOM_OBJECT domObj ON domObj.COL_ID = domAttr.COL_DOM_ATTRIBUTEDOM_OBJECT                                                                
    LEFT JOIN TBL_FOM_ATTRIBUTE fomAttr ON domAttr.COL_DOM_ATTRFOM_ATTR = fomAttr.COL_ID
    LEFT JOIN TBL_DICT_DATATYPE dataType ON fomAttr.COL_FOM_ATTRIBUTEDATATYPE = dataType.COL_ID

    LEFT JOIN TBL_DOM_RELATIONSHIP domRel ON domRel.COL_PARENTDOM_RELDOM_OBJECT = domObj.COL_ID 
                                             AND domObj.COL_TYPE = 'referenceObject'                                                            

    LEFT JOIN TBL_FOM_OBJECT fomObj ON fomObj.COL_ID = domObj.COL_DOM_OBJECTFOM_OBJECT
    LEFT JOIN TBL_DOM_REFERENCEOBJECT refObj ON refObj.COL_DOM_REFOBJECTFOM_OBJECT = fomObj.COL_ID                                                                                                      
                                                                    
WHERE ((
    domObj.COL_ID = :ObjId
    AND (NVL(domAttr.COL_ISUPDATABLE,0)=1 OR NVL(domAttr.COL_ISINSERTABLE,0)=1 OR NVL(domAttr.COL_ISRETRIEVABLEINDETAIL,0)=1)
) OR (
    domRel.COL_ChildDOM_RelDOM_Object = :ObjId 
    AND (NVL(domAttr.COL_ISUPDATABLE,0)=1 OR NVL(domAttr.COL_ISINSERTABLE,0)=1)
))
AND (NVL(domAttr.COL_ISSYSTEM,0) <> 1)

<%=Sort("@SORT@","@DIR@")%>