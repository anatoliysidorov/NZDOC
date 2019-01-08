SELECT
    r.RULEID as Id,
    r.RULEID as col_Id,
    r.RULEID as RuleId,
    r.COMPONENTID as ComponentId,
    r.CODE as Code,
    r.NAME as Name,
    r.RULETYPE as RuleType,
    r.BIZTYPE as BizType,
    r.ACCESSOBJECTID as AccessObjectId,
    r.DESCRIPTION as Description,
    r.LOCALCODE as LocalCode,
    r.REF_SCHEMAID as Ref_SchemaId,
    r.ISNEEDDEPLOYFUNCTION as IsNeedDeployFunction,
    r.ISNEEDDEPLOYVIEW as IsNeedDeployView,
    r.ISSYSTEM as IsSystem,
    r.MODIFIEDDATE as ModifiedDate,
    @TOKEN_SYSTEMDOMAINUSER@.CONF_GETOBJECTTAGS(r.RULEID, 7) as Tags,
    r.ISNEEDDEPLOYFUNCTION as IsFunction,
    CASE
      WHEN NVL(r.ISNEEDDEPLOYFUNCTION, 0)=1 THEN ('f_'|| r.LOCALCODE)
      ELSE null
    END as FunctionId,
	CASE
		WHEN NVL(r.ISNEEDDEPLOYFUNCTION, 0)=1 THEN ('f_'|| r.LOCALCODE)
		ELSE r.CODE
	END as CALC_ID
FROM   @TOKEN_SYSTEMDOMAINUSER@.conf_environment e
       inner join @TOKEN_SYSTEMDOMAINUSER@.conf_version v ON v.versionid = e.depversionid
       inner join @TOKEN_SYSTEMDOMAINUSER@.conf_rule r ON r.componentid = v.componentid
       INNER JOIN TABLE(ASF_SPLITCLOB(:APTags)) x ON (x.COLUMN_VALUE IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLITCLOB(@TOKEN_SYSTEMDOMAINUSER@.CONF_GETOBJECTTAGS(r.RULEID, 7)))))
WHERE  e.code = '@TOKEN_DOMAIN@'
	AND (:IsFunction IS NULL OR r.ISNEEDDEPLOYFUNCTION = :IsFunction)
<%=IfNotNull("@SORT@", " order by @SORT@ @DIR@, 1")%>