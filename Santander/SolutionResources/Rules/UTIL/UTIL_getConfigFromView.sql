SELECT VALUE, Name
  FROM (SELECT TO_CHAR (vw_config.VALUE) AS VALUE, vw_config.name AS Name
          FROM CONFIG vw_config
        UNION ALL
        SELECT TO_CHAR (s.createddate, 'Mon DD, YYYY') AS VALUE,
               N'SOLUTIONCREATEDDATE'                  AS Name
          FROM CONFIG  vw_config
               INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_SOLUTION s
                   ON vw_config.name = 'ENVIRONMENT_ID'
               INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_ENVIRONMENT e
                   ON     vw_config.VALUE = e.ENVIRONMENTID
                      AND s.ENVIRONMENTID = e.ENVIRONMENTID
        /*UNION ALL
        SELECT TO_CHAR (DEFAULT_VALUE) AS VALUE,
               N'DCM_VERSION (solution)'   AS Name
          FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_SYSVAR  sv
               INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION v
                   ON sv.COMPONENTID = v.COMPONENTID
               INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_ENVIRONMENT e
                   ON v.VERSIONID = e.DEPVERSIONID
         WHERE     e.code = '@TOKEN_DOMAIN@'
               AND sv.name = 'DCM_VERSION'*/)
WHERE 1=1
<%=IfNotNull(":Name", "AND lower(name) = lower(:Name)")%>
<%=IfNotNull(":Names", "AND lower(name) in (select column_value from table(asf_split(lower(:Names), ',')))")%>
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>