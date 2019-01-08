SELECT r.RULEID AS Id,
       r.RULEID AS col_Id,
       r.RULEID AS RuleId,
       r.COMPONENTID AS ComponentId,
       r.CODE AS Code,
       r.NAME AS NAME,
       r.RULETYPE AS RuleType,
       r.BIZTYPE AS BizType,
       r.ACCESSOBJECTID AS AccessObjectId,
       r.DESCRIPTION AS Description,
       r.LOCALCODE AS LocalCode,
       r.REF_SCHEMAID AS Ref_SchemaId,
       r.ISNEEDDEPLOYFUNCTION AS IsNeedDeployFunction,
       r.ISNEEDDEPLOYVIEW AS IsNeedDeployView,
       r.ISSYSTEM AS IsSystem,
       r.MODIFIEDDATE AS ModifiedDate,
       @TOKEN_SYSTEMDOMAINUSER@.CONF_GETOBJECTTAGS(r.RULEID, 7) AS Tags,
       r.ISNEEDDEPLOYFUNCTION AS IsFunction,
       CASE
         WHEN NVL(r.ISNEEDDEPLOYFUNCTION, 0) = 1 THEN
          lower('f_' || r.LOCALCODE)
         ELSE
          NULL
       END AS FunctionId,
       CASE
         WHEN NVL(r.ISNEEDDEPLOYFUNCTION, 0) = 1 THEN
          lower('f_' || r.LOCALCODE)
         ELSE
          r.CODE
       END AS CALC_ID
  FROM @TOKEN_SYSTEMDOMAINUSER@.conf_environment e
 INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version v
    ON v.versionid = e.depversionid
 INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_rule r
    ON r.componentid = v.componentid
 WHERE e.code = '@TOKEN_DOMAIN@'
<%=IfNotNull(":IsFunction", " AND r.ISNEEDDEPLOYFUNCTION = :IsFunction")%>
<%=IfNotNull(":APTags", " AND r.ruleid in (SELECT tob.OBJECTID FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT tob INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAG t ON t.TAGID = tob.TAGID INNER JOIN (select to_char(regexp_substr(:APTags,'[[:'||'alnum:]_]+', 1, level)) as tag_code from dual connect by dbms_lob.getlength(regexp_substr(:APTags, '[[:'||'alnum:]_]+', 1, level)) > 0) xtag ON xtag.tag_code = t.code WHERE tob.Type = 7)")%>
<%=IfNotNull("@SORT@", " order by @SORT@ @DIR@, 1")%>