-- Script deletes :TAG from solution (works under DCM3_TENANT schema only!)

DELETE FROM DCM3_TENANT.CONF_TAGOBJECT
      WHERE TAGID =
            (SELECT DISTINCT t.TAGID
               FROM DCM3_TENANT.CONF_BORELATION  obj
                    INNER JOIN DCM3_TENANT.CONF_VERSION vv
                        ON obj.componentid = vv.componentid AND vv.TYPE = 1
                    INNER JOIN DCM3_TENANT.conf_version v
                        ON vv.SOLUTIONID = v.SOLUTIONID
                    INNER JOIN DCM3_TENANT.conf_environment e
                        ON v.versionid = e.depversionid
                    LEFT JOIN DCM3_TENANT.CONF_TAG t
                        ON     t.componentid = vv.componentid
                           AND UPPER (t.CODE) = UPPER (:APTag)
                    LEFT JOIN (SELECT 2 AS TYPE FROM DUAL) ot ON 1 = 1
              WHERE     e.code = 'DCM_CATS_v3_Production.tenant1'
                    --'MOJ_NTS_Development.tenant1'
                    AND (SELECT COUNT (*)
                           FROM DCM3_TENANT.CONF_TAGOBJECT tob
                          WHERE     tob.TYPE = ot.TYPE
                                AND tob.TAGID = t.TAGID
                                AND tob.OBJECTID = obj.RELATIONID) =
                        0);

DELETE FROM DCM3_TENANT.CONF_TAG
      WHERE TAGID =
            (SELECT DISTINCT t.TAGID
               FROM DCM3_TENANT.CONF_BORELATION  obj
                    INNER JOIN DCM3_TENANT.CONF_VERSION vv
                        ON obj.componentid = vv.componentid AND vv.TYPE = 1
                    INNER JOIN DCM3_TENANT.conf_version v
                        ON vv.SOLUTIONID = v.SOLUTIONID
                    INNER JOIN DCM3_TENANT.conf_environment e
                        ON v.versionid = e.depversionid
                    LEFT JOIN DCM3_TENANT.CONF_TAG t
                        ON     t.componentid = vv.componentid
                           AND UPPER (t.CODE) = UPPER (:APTag)
                    LEFT JOIN (SELECT 2 AS TYPE FROM DUAL) ot ON 1 = 1
              WHERE     e.code = 'DCM_CATS_v3_Production.tenant1'
                    --'MOJ_NTS_Development.tenant1'
                    AND (SELECT COUNT (*)
                           FROM DCM3_TENANT.CONF_TAGOBJECT tob
                          WHERE     tob.TYPE = ot.TYPE
                                AND tob.TAGID = t.TAGID
                                AND tob.OBJECTID = obj.RELATIONID) =
                        0);