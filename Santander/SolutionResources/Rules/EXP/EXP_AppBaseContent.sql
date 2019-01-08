SELECT o.ID,
       o.CODE,
       o.NAME,
       o.TYPE,
       DECODE (o.COMPONENTID, ta.COMPONENTID, ta.localcode, null) AS TAG
  FROM (SELECT RULEID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Rule' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_RULE
        UNION ALL
        SELECT RULEEXTENSIONID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Extension' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_RULEEXTENSION
        UNION ALL
        SELECT PAGEID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Page' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_NAVPAGE
        UNION ALL
        SELECT REPORTID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Report' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_REPORT
        UNION ALL
        SELECT TYPEID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'BusinessType' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_TYPE
        UNION ALL
        SELECT OBJECTID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'BusinessObject' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BOOBJECT
        UNION ALL
        SELECT RELATIONID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Relation' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BORELATION
        UNION ALL
        SELECT CAPTURECHANNELTYPEID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'CaptureChannelSchema' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_CAPTURECHANNELTYPE
        UNION ALL
        SELECT SCHEMAID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'ScanIndexingSchema' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_INDEXSCHEMA
        UNION ALL
        SELECT BARCODEMASKID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Barcode' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BARCODEMASK
        UNION ALL
        SELECT MIMEAPPMAPID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'MimeType' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_MIMETYPEAPPMAP
        UNION ALL
        SELECT TASKID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'ScheduledTask' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_SCHEDULEDTASK
        UNION ALL
        SELECT CHANNELID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'DistributionChannel' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_DISTRIBCHANNEL
        UNION ALL
        SELECT BOOKMARKID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Bookmark' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BOOKMARK
        UNION ALL
        SELECT TEMPLATEID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'LetterTemplate' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_TEMPLATE
         WHERE TEMPLATETYPE = 1
        UNION ALL
        SELECT TEMPLATEID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'MailMergeTemplate' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_TEMPLATE
         WHERE TEMPLATETYPE = 2
        UNION ALL
        SELECT ACTIVITYTYPEID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'ActivityType' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_WFACTIVITYTYPE
        UNION ALL
        SELECT POOLID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Pool' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_WFPOOL
        UNION ALL
        SELECT WORKFLOWID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Workflow' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_WFWORKFLOW
        UNION ALL
        SELECT REPORTCATEGORYID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'ReportCategory' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_REPORTCATEGORY
        UNION ALL
        SELECT ROLEID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Role' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_ROLE
        UNION ALL
        SELECT APPID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'Application' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_APPLICATION
        UNION ALL
        SELECT ALLOWEDLANGID AS ID,
               LANGUAGECODE AS CODE,
               LANGUAGECODE AS NAME,
               N'AllowedLocale' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_ALLOWEDLANG
        UNION ALL
        SELECT EVENTID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'BusinessEvent' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_EVENT
        UNION ALL
        SELECT RESOURCEKEYID AS ID,
               CODE AS CODE,
               NAME AS NAME,
               N'ResourceKey' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_RESOURCEKEY
        UNION ALL
        SELECT SYSVARID AS ID,
               NAME AS CODE,
               NAME AS NAME,
               N'SysVar' AS TYPE,
               COMPONENTID AS COMPONENTID
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_SYSVAR) o
       INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION v
           ON o.COMPONENTID = v.COMPONENTID
       INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_ENVIRONMENT e
           ON v.VERSIONID = e.DEPVERSIONID
       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT tago
           ON TAGO.OBJECTID = o.ID
       LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAG ta 
           ON ta.TAGID = tago.tagid
 WHERE e.code = '@TOKEN_DOMAIN@' 
   --AND (o.COMPONENTID = ta.COMPONENTID OR ta.COMPONENTID IS NULL)
UNION ALL
SELECT NULL AS ID,
       TRANSLATE ((COLUMN_VALUE) USING NCHAR_CS) AS CODE,
       TRANSLATE ((COLUMN_VALUE) USING NCHAR_CS) AS NAME,
       N'SolutionResources' AS TYPE,
       NULL AS TAG
  FROM TABLE (
           ASF_SPLIT ('Build,cache,config,lib,Rules,SolutionSysFiles', ','))
UNION ALL
SELECT NULL AS ID,
       TRANSLATE ((COLUMN_VALUE) USING NCHAR_CS) AS CODE,
       TRANSLATE ((COLUMN_VALUE) USING NCHAR_CS) AS NAME,
       N'VersionResources' AS TYPE,
       NULL AS TAG
  FROM TABLE (ASF_SPLIT ('EmailTemplates,Rules,Pages', ','))