INSERT INTO DCM3_TENANT.CONF_TAGOBJECT
  (TAGID, OBJECTID, TYPE)
  (
   -- Rules  (7 as Type)
   SELECT t.TAGID,
           obj.RULEID AS OBJECT_ID,
           ot.Type
     FROM DCM3_TENANT.conf_rule obj
    INNER JOIN DCM3_TENANT.CONF_VERSION vv
       ON obj.componentid = vv.componentid
      AND vv.TYPE = 1
    INNER JOIN DCM3_TENANT.conf_version v
       ON vv.SOLUTIONID = v.SOLUTIONID
    INNER JOIN DCM3_TENANT.conf_environment e
       ON v.versionid = e.depversionid
     LEFT JOIN DCM3_TENANT.CONF_TAG t
       ON t.componentid = vv.componentid
      AND UPPER(t.CODE) = UPPER(:APTag)
     LEFT JOIN (SELECT 7 AS TYPE FROM dual) ot
       ON 1 = 1
    WHERE e.code = 'DCM_CATS_v3_Production.tenant1' --'MOJ_NTS_Development.tenant1'
      AND (SELECT COUNT(*)
             FROM DCM3_TENANT.CONF_TAGOBJECT tob
            WHERE tob.Type = ot.Type
              AND tob.TAGID = t.TAGID
              AND tob.OBJECTID = obj.ruleid) = 0
      AND ((obj.MODIFIEDDATE IS NOT NULL AND (trunc(obj.MODIFIEDDATE) >= trunc(to_date(:DateStart)) AND trunc(obj.MODIFIEDDATE) <= trunc(to_date(:DateEnd)))) OR
          (obj.MODIFIEDDATE IS NULL AND (trunc(obj.CREATEDDATE) >= trunc(to_date(:DateStart)) AND trunc(obj.CREATEDDATE) <= trunc(to_date(:DateEnd)))))

   UNION ALL
   -- Pages  (12 as Type)
   SELECT t.TAGID,
           obj.PAGEID AS OBJECT_ID,
           ot.Type
     FROM DCM3_TENANT.CONF_NAVPAGE obj
    INNER JOIN DCM3_TENANT.CONF_VERSION vv
       ON obj.componentid = vv.componentid
      AND vv.TYPE = 1
    INNER JOIN DCM3_TENANT.conf_version v
       ON vv.SOLUTIONID = v.SOLUTIONID
    INNER JOIN DCM3_TENANT.conf_environment e
       ON v.versionid = e.depversionid
     LEFT JOIN DCM3_TENANT.CONF_TAG t
       ON t.componentid = vv.componentid
      AND UPPER(t.CODE) = UPPER(:APTag)
     LEFT JOIN (SELECT 12 AS TYPE FROM dual) ot
       ON 1 = 1
    WHERE e.code = 'DCM_CATS_v3_Production.tenant1' --'MOJ_NTS_Development.tenant1'
      AND (SELECT COUNT(*)
             FROM DCM3_TENANT.CONF_TAGOBJECT tob
            WHERE tob.Type = ot.Type
              AND tob.TAGID = t.TAGID
              AND tob.OBJECTID = obj.PAGEID) = 0
      AND ((obj.MODIFIEDDATE IS NOT NULL AND (trunc(obj.MODIFIEDDATE) >= trunc(to_date(:DateStart)) AND trunc(obj.MODIFIEDDATE) <= trunc(to_date(:DateEnd)))) OR
          (obj.MODIFIEDDATE IS NULL AND (trunc(obj.CREATEDDATE) >= trunc(to_date(:DateStart)) AND trunc(obj.CREATEDDATE) <= trunc(to_date(:DateEnd)))))

   UNION ALL
   -- BO  (8 as Type) through BOATTRIBUTE
   SELECT DISTINCT t.TAGID,
                    obj.OBJECTID AS OBJECT_ID,
                    ot.Type
     FROM DCM3_TENANT.CONF_BOOBJECT obj
    INNER JOIN DCM3_TENANT.CONF_VERSION vv
       ON obj.componentid = vv.componentid
      AND vv.TYPE = 1
    INNER JOIN DCM3_TENANT.conf_version v
       ON vv.SOLUTIONID = v.SOLUTIONID
    INNER JOIN DCM3_TENANT.conf_environment e
       ON v.versionid = e.depversionid
     LEFT JOIN DCM3_TENANT.CONF_BOATTRIBUTE att
       ON att.objectid = obj.OBJECTID
     LEFT JOIN DCM3_TENANT.CONF_TAG t
       ON t.componentid = vv.componentid
      AND UPPER(t.CODE) = UPPER(:APTag)
     LEFT JOIN (SELECT 8 AS TYPE FROM dual) ot
       ON 1 = 1
    WHERE e.code = 'DCM_CATS_v3_Production.tenant1' --'MOJ_NTS_Development.tenant1'
      AND (SELECT COUNT(*)
             FROM DCM3_TENANT.CONF_TAGOBJECT tob
            WHERE tob.Type = ot.Type
              AND tob.TAGID = t.TAGID
              AND tob.OBJECTID = obj.OBJECTID) = 0
      AND (((obj.MODIFIEDDATE IS NOT NULL AND (trunc(obj.MODIFIEDDATE) >= trunc(to_date(:DateStart)) AND trunc(obj.MODIFIEDDATE) <= trunc(to_date(:DateEnd)))) OR
          (obj.MODIFIEDDATE IS NULL AND (trunc(obj.CREATEDDATE) >= trunc(to_date(:DateStart)) AND trunc(obj.CREATEDDATE) <= trunc(to_date(:DateEnd))))) OR
          ((att.MODIFIEDDATE IS NOT NULL AND (trunc(att.MODIFIEDDATE) >= trunc(to_date(:DateStart)) AND trunc(att.MODIFIEDDATE) <= trunc(to_date(:DateEnd)))) OR
          (att.MODIFIEDDATE IS NULL AND (trunc(att.CREATEDDATE) >= trunc(to_date(:DateStart)) AND trunc(att.CREATEDDATE) <= trunc(to_date(:DateEnd))))))
      AND UPPER(obj.CODE) NOT LIKE 'ROOT_CDM%'
   UNION ALL
   -- RELATION  (2 as Type)
   SELECT t.TAGID,
           obj.RELATIONID AS OBJECT_ID,
           ot.Type
     FROM DCM3_TENANT.CONF_BORELATION obj
    INNER JOIN DCM3_TENANT.CONF_VERSION vv
       ON obj.componentid = vv.componentid
      AND vv.TYPE = 1
    INNER JOIN DCM3_TENANT.conf_version v
       ON vv.SOLUTIONID = v.SOLUTIONID
    INNER JOIN DCM3_TENANT.conf_environment e
       ON v.versionid = e.depversionid
     LEFT JOIN DCM3_TENANT.CONF_TAG t
       ON t.componentid = vv.componentid
      AND UPPER(t.CODE) = UPPER(:APTag)
     LEFT JOIN (SELECT 2 AS TYPE FROM dual) ot
       ON 1 = 1
    WHERE e.code = 'DCM_CATS_v3_Production.tenant1' --'MOJ_NTS_Development.tenant1'
      AND (SELECT COUNT(*)
             FROM DCM3_TENANT.CONF_TAGOBJECT tob
            WHERE tob.Type = ot.Type
              AND tob.TAGID = t.TAGID
              AND tob.OBJECTID = obj.RELATIONID) = 0
      AND ((obj.MODIFIEDDATE IS NOT NULL AND (trunc(obj.MODIFIEDDATE) >= trunc(to_date(:DateStart)) AND trunc(obj.MODIFIEDDATE) <= trunc(to_date(:DateEnd)))) OR
          (obj.MODIFIEDDATE IS NULL AND (trunc(obj.CREATEDDATE) >= trunc(to_date(:DateStart)) AND trunc(obj.CREATEDDATE) <= trunc(to_date(:DateEnd)))))
      AND UPPER(obj.CODE) NOT LIKE 'ROOT_CDM%'

   )